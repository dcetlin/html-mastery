---
name: html
description: Produce and maintain rich interactive HTML documents. Use when creating new HTML artifacts, editing existing large HTML files (500+ lines), building SVG diagrams, or rendering HTML to PNG. Triggers on "create an HTML doc", "update the HTML", "fix the HTML", "add a section", "build a diagram", "render to PNG", or when working with any self-contained HTML artifact.
---

# HTML Document Skill

This skill provides operational discipline for producing and maintaining self-contained HTML artifacts. It detects what you're about to do and loads the relevant methodology.

**The full design system and conventions live in `STANDARD.md` in the html-mastery repo.** This skill assumes STANDARD.md is available as ambient context (via CLAUDE.md reference or similar). If it's not loaded, read it first.

---

## Detect the moment

Before acting, identify which mode applies:

| Signal | Mode | What to load |
|--------|------|-------------|
| No HTML file exists yet | **Create** | Design system, artifact class selection, gallery as reference |
| HTML file exists, < 500 lines | **Edit (small)** | Direct editing is safe. Validate after. |
| HTML file exists, 500+ lines | **Edit (large)** | Section-based workflow. NEVER full-file rewrite. |
| Need a diagram or visual | **Diagram** | SVG conventions, Chromium pipeline |
| Need to render HTML to PNG | **Render** | Chromium headless command |

---

## Mode: Create

1. Decide artifact class: **Document-class** (reports, design docs, decisions, audits) or **Dashboard-class** (data dashboards, monitoring, interactive tools).
2. Start from the gallery example or the skeleton in STANDARD.md. Never start from a blank file.
3. Include all required features for the class:
   - Document-class: light/dark toggle, taxonomic section IDs, comment widget, version metadata
   - Dashboard-class: light/dark toggle (if readable sections), filter bar, status badges
4. Use the full color token system (dark-first).
5. Validate the output: `python3 tools/validate.py <file>`

---

## Mode: Edit (large file, 500+ lines)

This is the critical mode. Most failures happen here.

### The workflow

```
extract section → edit in isolation → replace → validate → repeat
```

1. **Discover structure:** `html-tool.sh sections` to see all IDs and line ranges.
2. **Extract the target section:** `html-tool.sh extract <section-id> > /tmp/section.html`
3. **Edit the extracted section** (small, focused file — safe for LLM editing).
4. **Replace:** `html-tool.sh replace <section-id> /tmp/section.html`
5. **Validate:** `python3 tools/validate.py <file>` — **non-negotiable after every edit.**
6. **If validation fails, fix before proceeding.** Cascading div errors compound.

### For mechanical changes (CSS injection, class renaming, bulk updates)

Write a Python transform script. Don't use LLM subagents for pattern-based changes.

```python
#!/usr/bin/env python3
import re, sys

def transform(html):
    # pattern-based changes here
    return html

html = open(sys.argv[1]).read()
html = transform(html)
open(sys.argv[2], 'w').write(html)

# Always validate after
from validate import validate_html
issues, stats = validate_html(sys.argv[2])
if issues:
    print(f"WARNING: {len(issues)} issues")
    for i in issues: print(f"  {i}")
```

### What does NOT work

**Subagent full-file rewrites of 1500+ line HTML.** The API has output limits. A subagent tasked with rewriting a large HTML file will hit those limits, produce truncated output, or silently drop sections. The failure mode is insidious: the subagent reports success, but the output is incomplete.

**The Edit tool on large HTML files.** String matching breaks with encoded characters (`&amp;`, `&#8212;`, smart quotes). A single character mismatch in a 200-character `old_string` causes the edit to fail silently or match the wrong location.

**Mixing structural and content changes in one pass.** CSS injection, div wrapping, and class renaming are mechanical transforms. Content edits (rewriting prose, updating data) require understanding context. Separate them: transforms first, content edits second.

---

## Mode: Diagram

### Inline SVG flow diagrams

Hand-crafted SVG, no external libraries. Use the 4-role color system from STANDARD.md.

Key conventions:
- Box specs: ~120-160px wide, ~70px tall, rx="10", stroke-width="1.5"
- Two text lines: title (12.5px, weight 600) + subtitle (10px)
- Arrows: `<line>` with `marker-end`. Prefix all marker IDs with a unique name to avoid collisions.
- All connectors horizontal or L-shaped elbows. No diagonals.
- Zone labels below the diagram.

### Architecture annotation

Core principle: **annotate architecture, not fields.** One annotation that reveals a design decision is worth more than six that label individual fields.

---

## Mode: Render (HTML to PNG)

```bash
chromium --headless \
  --screenshot="/absolute/path/output.png" \
  --window-size=1400,700 \
  --force-device-scale-factor=2 \
  "file:///absolute/path/diagram.html"
```

- `--force-device-scale-factor=2` for retina quality
- Always use absolute paths with `file://` protocol
- For macOS: `/opt/homebrew/bin/chromium`

---

## Canon authority (for projects with markdown + HTML)

When a project maintains both markdown docs and HTML artifacts:

- **Substance** (reasoning, analysis, decisions) → edit markdown first, propagate to HTML
- **Presentation** (layout, styling, interactivity) → edit HTML directly
- **Structured reference** (tables of settled facts) → edit HTML directly, extractable via tooling

The test: "Is this substance or presentation?" Substance always gets a markdown home.

---

## Checklist (before publishing any artifact)

- [ ] Dark/light palette tokens applied
- [ ] Light mode uses higher-contrast accent values
- [ ] Version meta tags present
- [ ] Section IDs are taxonomic (§1, §2, §1.1)
- [ ] Document-class: comment widget present, sections[] matches actual sections
- [ ] All JS inline; no external CSS
- [ ] Structural validation passes (0 issues)
- [ ] Opened in browser and visually verified
