---
name: html
description: Produce and maintain rich interactive HTML documents. Triggers on creating, editing, or rendering self-contained HTML artifacts. Covers design system, 28 components, SVG conventions, and production methodology for files up to 4,000+ lines.
---

# HTML Document Skill

Build and maintain self-contained HTML artifacts — decision documents, dashboards, storyboards — using the html-mastery spec.

**Full spec:** `STANDARD.md` in the [html-mastery](https://github.com/dcetlin/html-mastery) repo. If available locally, check `~/Documents/html-mastery/STANDARD.md`. Load it for component details, design tokens, and skeletons. This skill gives you enough to start working; the spec gives you depth.

## Setup

```bash
export HTML_TOOL_FILE=my-document.html    # required for html-tool.sh
python3 tools/validate.py my-document.html # run after EVERY edit
```

## What To Do

| Task | How |
|------|-----|
| **Create** | Pick a class (Document / Dashboard / Presentation). Copy the skeleton from STANDARD.md §8. Never start blank. Dark mode is the default. |
| **Small edit** (<30 lines) | Read tool or Edit tool directly. Validate after. |
| **Large edit** (30-500 lines) | `html-tool.sh extract <id>` → edit fragment → `html-tool.sh replace <id>` → validate. |
| **New section** (CSS+HTML+JS) | Python three-point injection script: CSS before `@media`, HTML between sections, JS before `</script>`. Validate. |
| **Bulk changes** (5+ instances) | Python transform script with `replace_once()` — validates exactly one match per replacement. Never bare `str.replace()` on large files. |
| **SVG diagram** | Hand-crafted inline SVG. 4 color roles: indigo (primary), violet (secondary), amber (highlight), green (muted). Prefix all marker IDs per diagram. No diagonals. |
| **Render to PNG** | `chromium --headless --screenshot=out.png --window-size=1400,700 --force-device-scale-factor=2 file:///path.html` |

## The Rules

1. **Validate after every edit.** `python3 tools/validate.py <file>`. Non-negotiable. A single unclosed div cascades silently through thousands of lines.
2. **Never full-file rewrite** of 500+ line HTML. Extract → edit → replace, or transform scripts.
3. **Substance → markdown first.** New analysis, data, decisions go to markdown; propagate to HTML. Layout, styling, interactivity → edit HTML directly.
4. **Dark mode is the default.** Light mode is a class override with higher-contrast accents.
5. **Append-only discipline.** Existing content in long-lived files is load-bearing. Add to it; don't reorganize, consolidate CSS, reformat whitespace, or refactor inline JS.
6. **Parallelize thinking, serialize writing.** Dispatch research subagents in parallel. One session synthesizes and edits the HTML. Concurrent file writers don't work — CSS/JS are global state with no safe partition.

## Artifact Classes

- **Document-class** — reports, decisions, audits. Required: light/dark toggle, taxonomic section IDs, comment widget, version meta.
- **Dashboard-class** — data dashboards, monitoring. Required: light/dark toggle, filter bar, status badges.
- **Presentation-class** — slide storyboards, journey walkthroughs. Required: track tabs, slide nav with step dots, keyboard arrows, full-viewport.

## Anti-Patterns

These fail reliably. Do not attempt:

| Don't | Why |
|-------|-----|
| Subagent full-file rewrite of 1500+ lines | Truncation. Sections silently dropped. |
| Edit tool on large HTML with entities | `&amp;`, `&#8212;`, smart quotes break string matching. |
| Mix structural + semantic changes | Different cognitive modes. Both degrade. |
| Reorganize a large file | Untraceable full-file diff. |
| Consolidate "duplicate" CSS | Near-duplicates have subtle differences. |
| Reformat whitespace | Enormous noise diffs obscuring real changes. |
| Refactor inline JS | Breaks call sites throughout the file. |
| Remove/rename an `id` without grepping | Breaks CSS selectors, JS, internal links. |

## Operator Patterns

For intensive sessions (10+ edits):

- **`replace_once(html, old, new, label)`** — match-count validation. Warns on 0 or 2+ matches. Include enough surrounding context to guarantee uniqueness.
- **Bottom-up editing** — edit highest line numbers first so earlier targets stay stable.
- **Factual claim sweep** — `grep -n "old_value"` after every batch. One wrong word propagates to 6+ locations across sessions.
- **Card synchronization** — when changing a card's status, update all 4 layers: CSS class, badge text, info box, SVG annotations.
- **`.bak` recovery** — `html-tool.sh replace` creates backups. Restore from `.bak`; don't fix forward on a corrupted file.
- **Pre-publish sweep** — validate → grep stale claims → version-number check → card sync → browser preview (both themes) → click every interactive element.
