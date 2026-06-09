# Production Review of html-mastery — From the Session That Built the Artifacts

> **Author:** prism (Claude Opus session, forked from ember). **Date:** 2026-06-09.
> **Context:** This session built and maintained the AC/DC HTML decision document (~3900 lines, v8.30, 9 interactive sections) and the LP Experience Storyboard (~2237 lines, 9 tracks, 31 slides) across 20+ iterative editing sessions. This review comes from that direct experience.
>
> **How to use this document:** Sections 1-4 are the review. Section 5 is a prioritized action plan. Section 6 contains detailed implementation guidance for each action — enough for a worker session to execute without needing production context.

---

## 1. What the Spec Captures Well

These sections accurately reflect how large HTML artifacts work in practice:

1. **Dark-first color tokens with explicit light-mode overrides (§1.1, §3.1).** The dual-palette approach with higher-contrast accent values for light mode is correct. The `localStorage` persistence pattern that applies before paint prevents flash. This is one of the most common sources of subtle bugs — the spec gets it right.

2. **SVG marker ID collision prevention (§5.1).** The call-out about prefixing marker IDs with diagram-specific names is a genuine hard-won lesson. When a document has four flow diagrams, the second diagram's arrowheads silently disappear because `#arrow` was already claimed by the first. In the AC/DC doc, every SVG uses prefixed markers: `c1-gen-blue`, `m1b-gray`, `c3a-arrow-purple`.

3. **The anti-pattern about full-file rewrite by subagent (§6.4).** The description of what happens — truncation, silent section dropping, a shorter file with no indication of what was lost — is exactly accurate. This is the single most important rule.

4. **The D_JSON data injection pattern (§4.1).** Correct architecture for generated dashboards. The Python format-string `{`/`}` doubling note catches a real trap.

5. **The "substance vs. presentation" distinction (§6.5).** The framing that the question is about content nature, not filesystem state, is exactly right. The note about gaps being "things to fill" rather than "permission to go HTML-first" is a subtle but critical distinction that matches the AC/DC canon-to-HTML pipeline.

---

## 2. Critical Gaps from Production Experience

### 2.1 Python Injection Scripts Are THE Dominant Workflow

**Current state:** §6.3 mentions "multi-point injection" in one sentence (line 1214).

**What actually happens:** Every major addition to the AC/DC artifacts used a Python injection script as the primary editing tool. Not the Edit tool, not html-tool.sh — a purpose-built Python script.

**Scripts written during production:**
| Script | What it did | Lines injected |
|---|---|---|
| `inject.py` | Added §1.75 LP Experience to decision doc | CSS (80 lines) + HTML (400 lines) + JS (30 lines) |
| `inject-rail.py` | Added Rail baseline track to storyboard | Tab + 4 slides + JS track map update |
| `rebuild-tracks.py` | Restructured all tracks (KYC→Onboarding, M1a/M1b→LiqAddr/Static) | Replaced entire slide content (700+ lines) |
| `add-entry-toggles.py` | Added Closing Flow / Funding Accounts sub-toggles | Replaced slide 1 of 3 tracks + new JS handler |
| `add-dropdowns.py` | Added real chain/token dropdowns to all deposit wireframes | 5 targeted replacements across tracks |
| `coinbase-and-edges.py` | Added 4 new tracks (Coinbase Onboarding, Deposit Dest., Wallet M2, Edge Cases) | 12 slides + tab bar + JS track map |

**The pattern is always the same:**
```python
#!/usr/bin/env python3
"""Describe what this script changes."""

HTML_PATH = "path/to/file.html"

with open(HTML_PATH, 'r') as f:
    html = f.read()

# 1. CSS injection (before @media or </style>)
CSS_ANCHOR = "@media (max-width: 900px) {"
css_fragment = open("/tmp/css-fragment.css").read()
html = html.replace(CSS_ANCHOR, css_fragment + "\n" + CSS_ANCHOR, 1)
print("CSS injected")

# 2. HTML injection (between known section boundaries)
SECTION_ANCHOR = '<div class="top-section" id="ts-2">'
section_html = open("/tmp/section.html").read()
html = html.replace(SECTION_ANCHOR, section_html + "\n" + SECTION_ANCHOR, 1)
print("HTML section injected")

# 3. JS injection (before closing </script>)
JS_ANCHOR = "</script>"
js_fragment = open("/tmp/js-fragment.js").read()
# Use rfind to target the LAST </script> tag
idx = html.rfind(JS_ANCHOR)
html = html[:idx] + js_fragment + "\n" + html[idx:]
print("JS injected")

with open(HTML_PATH, 'w') as f:
    f.write(html)
print("Done.")
```

**Why this works and other approaches don't:**
- The Edit tool's `old_string` matching breaks on HTML entities (`&amp;`, `&#8212;`) and whitespace variation. A 200-character match string that's off by one entity encoding fails silently.
- html-tool.sh's extract→edit→replace cycle has friction for additions (no existing section to extract). Python scripts handle insertions at arbitrary points.
- Python scripts are **traceable** — you can read the script to see exactly what changed, unlike an Edit tool call that's buried in conversation context.

**Recommendation:** Add a "§6.3.1 Injection Script Pattern" subsection with the template above and the three-point injection pattern as a first-class workflow.

### 2.2 Anchor Discovery via Grep

**Current state:** Not mentioned. html-tool.sh's `sections` command is the clean version.

**What actually happens:** Before every edit, the first command is always:
```bash
grep -n 'id="ts-2"\|section-num\|top-section' file.html | head -20
```

This is not optional scaffolding — it's the primary method for orienting within a large file. In a 3900-line file, you cannot hold the structure in your head. You grep for it every time.

**The deliberate anchor convention:** During initial file creation, insert HTML comments at key boundaries:
```html
<!-- ============================= M1a TRACK ============================= -->
<!-- LiqAddr 1: Deposit page — per-chain dropdown -->
<!-- Static 2: Send (same as LiqAddr) -->
```

These comments are the API contract between the initial author and future editors. They're what `grep` finds. Without them, you're searching for `<div class="slide" data-track="liqaddr" data-step="2">` which is less readable and more fragile.

**Recommendation:** Add a "§6.1.1 Anchor Conventions" subsection documenting comment-based anchors and the grep-first workflow.

### 2.3 Three Distinct Editing Workflows

**Current state:** §6.1 presents one workflow. §6.3 presents transform scripts. These are actually three distinct workflows selected by edit scale.

**The decision matrix:**

| Edit type | Scale | Tool | Risk | Example from production |
|---|---|---|---|---|
| Content update in identified section | <30 lines changed | Read + Edit tool | Low | Updating yield text from "$412K" to "$281K-$412K" |
| CSS-only addition | Any | Edit tool (unique anchor) or Python inject | Low | Adding `.sys-json` class |
| New section with HTML+CSS+JS | 50-500 lines | Python three-point injection | Medium | Adding §1.75 LP Experience |
| Section restructure | Any | Python replacement script | High | Rebuilding M2 wallet slides as Funding Accounts |
| Full track/tab addition | 200+ lines | Python injection + JS handler updates | High | Adding Coinbase + Edge Cases (12 slides) |

**The key heuristic:** If the edit changes div nesting depth of a section, it's a rebuild, not a surgical edit. Surgical edits on nesting-depth changes are the #1 source of div-balance corruption.

**Recommendation:** Replace §6.1 with a decision matrix. Make the three workflows explicit: surgical edit, fragment injection, section rebuild.

### 2.4 Session Initialization Protocol

**Current state:** Not documented.

**What happens at the start of every editing session on a large file:**
```bash
# 1. Check version
grep -n 'doc-version\|version.*v[0-9]' file.html | head -3

# 2. Line count baseline
wc -l file.html

# 3. Div balance baseline
grep -c '<div' file.html && grep -c '</div>' file.html

# 4. Structure orientation
grep -n 'top-section\|data-track\|section-num' file.html | head -20
```

If v8.29 was 3269 lines with 564 divs, and after edits it's 3200 lines with 550 divs, something was silently dropped. Without the baseline, you don't know.

**Recommendation:** Add "§6.0 Session Initialization" before §6.1.

### 2.5 Version Management Is More Granular

**Current state:** §6.7 says "minor for content, major for structural."

**What's missing:**
- **Version in footer text** (not just meta tags): `"Settlement Architecture v8.30 — Updated 2026-06-07"` — visible in the rendered document, updated via Python transform.
- **Recording line count + div count at each version** as corruption detection. The LOG.md entry for each version includes: `"v8.30, 3927 lines, 564/564 divs balanced."`
- **Version history as HTML comment** at the top of the file: `<!-- v8.28: 3269 lines, 9 sections. v8.30: 3927 lines, added §1.75 LP Experience. -->`

**Recommendation:** Expand §6.7 with these practical conventions.

### 2.6 CSS Scoping When Adding Section N+1

**Current state:** Not addressed.

**The real problems:**
- **Class name collision:** A new section with `.card` or `.header` bleeds into existing sections. Practice: prefix all new classes with section abbreviation: `lpx-step`, `lpx-mockup`, `sys-json`, `wire-tag`.
- **CSS ordering:** New CSS injected before `</style>` goes after all existing rules, winning specificity ties. Usually fine, but causes surprises with generic class names.
- **Media query interaction:** New responsive rules must go inside the existing `@media` block, not create a duplicate.

**Recommendation:** Add "§6.8 CSS Scoping for Long-Lived Files."

### 2.7 Browser Preview Is Non-Negotiable

**Current state:** §6.1 mentions `html-tool.sh preview` as one of several commands.

**Reality:** `open file.html` (macOS) or equivalent runs after every major edit. Validation catches structural corruption (div balance). Browser preview catches visual corruption — CSS that's structurally valid but visually wrong. A column that's suddenly full-width, a color that's wrong in light mode, a tooltip that's positioned off-screen. Both are required.

**Recommendation:** Elevate browser preview to the same mandatory status as validation in §6.2. Add it to the checklist in the skill.

---

## 3. Missing Anti-Patterns

§6.4 has five anti-patterns. These five are also critical:

### 3.1 "Helpful Reorganization"
A new session sees that the file could be "better organized" and restructures sections, renames CSS classes, or reorders functions. **Catastrophic** on a 3000+ line file because it creates a diff touching every line, making it impossible to verify what changed. **Rule: Never reorganize a large HTML file. Only make targeted, traceable changes.**

### 3.2 "Consolidate Duplicate CSS"
After 15 sessions, CSS has near-duplicate rules. Consolidation frequently breaks styling because "duplicates" have subtle differences (`var(--text2)` vs `var(--text3)`) or target different specificity contexts. **Rule: Tolerate CSS redundancy in long-lived files. Only consolidate when you can visually verify every affected section.**

### 3.3 "Improve Whitespace/Formatting"
Reformatting HTML (re-indenting, adding line breaks) creates enormous diffs obscuring real changes. **Rule: Preserve existing whitespace. Match adjacent sections for new content, but never reformat existing content.**

### 3.4 "Extract to Function" in Inline JS
Seeing repeated patterns in inline JavaScript and refactoring into shared functions changes call sites throughout the file. **Rule: Inline JS in HTML artifacts is append-only. New functions fine. Refactoring existing functions is not, unless you test every interactive feature.**

### 3.5 Silent Anchor Destruction
An edit removes or renames an `id` attribute that serves as anchor for CSS selectors, JS `getElementById`, or internal `href="#..."` links. Creates failures invisible until someone interacts with the feature. **Rule: Before modifying any `id`, grep the entire file for references to that ID.**

---

## 4. Gallery Critique

### What the gallery does well
- Clean token-based design system with functional light/dark toggle
- Demonstrates the core component vocabulary: cards, tables, details, tabs, step navigator, calculator, tooltips, SVG, badges
- Coherent fictional scenario
- Self-contained, no dependencies

### What's missing vs production artifacts

**Interactive depth:**
- No top-level collapsible sections with chevron rotation (production uses custom divs with JS toggle + CSS transform, not native `<details>`)
- No nested provider-card-with-dimensions pattern (three levels: section > card > dimension, each collapsible independently)
- No split-screen slide layout (the storyboard's `grid-template-columns: 1fr 380px` is an entirely different artifact class)
- No entry-point sub-toggles, JSON syntax highlighting, browser chrome wireframes, or comparison annotation tags

**SVG quality:**
- Gallery SVGs use fixed `width`/`height` (don't scale). Production uses `viewBox` with `max-width: 100%; height: auto`
- No zone labels below diagrams, no annotation boxes, no `role="img"` + `aria-label` accessibility

**Calculator sophistication:**
- Gallery: 3 sliders + 3 radio buttons
- Production: 13 inputs, graduated tier computation with `TIERS` array, milestone selector toggling row visibility, Rail baseline comparison, CSS tooltips on every input, break-even dwell calculation

**Missing patterns that should be demonstrated:**
1. Thesis/orientation banner (gradient-bordered, frames the decision context before any sections)
2. Meta pills in header (inline data points with pill styling)
3. Milestone badges on tabs (`<span class="milestone ms1">M1a</span>`)
4. Verdict boxes (green left-border for recommended, red for not-recommended)
5. Keyboard navigation on tabs
6. At least one composable card with nested collapsible dimensions

### Priority recommendations for the gallery

1. **Replace at least 2 native `<details>` sections with custom collapsible sections** using the `div.top-section` + JS toggle pattern. This is the structural backbone of production documents.
2. **Add one provider-card with 3+ collapsible dimensions** showing the nested interactivity pattern.
3. **Upgrade all SVGs** to use `viewBox`, responsive sizing, zone labels, and accessibility attributes.
4. **Enrich the calculator** with a scenario/tier selector, named constant array, and at least one CSS tooltip input.
5. **Add milestone badges to tabs and a thesis banner** at the top.
6. **Add keyboard navigation** (arrow keys) to the tab bar.

---

## 5. Broader Suggestions

### 5.1 Missing Artifact Class: Presentation/Storyboard

The spec defines Document-class and Dashboard-class. The LP storyboard is a third class: **Presentation-class** — full-viewport slides, track tabs, keyboard navigation, split-screen wireframe+system panels, step progress dots, entry-point toggles. This needs:
- Its own section in §2
- Its own skeleton in §8
- Component definitions for: slides, tracks, split-pane wireframe, browser chrome mock, system panel, comparison tags, step dots

### 5.2 The Gallery Should Have Two Examples

One Document-class (the current database doc, elevated to production quality) and one Presentation-class (a simplified storyboard). These are fundamentally different artifact types. Demonstrating only one leaves the other unspecified.

### 5.3 Component §3.12 (Step Navigator) Is Underspecified

The production step navigator has: clickable steps that update panel visibility, done/active/future states with connecting lines, per-journey scoping (multiple navigators on the same page with independent state). The spec shows a static 3-step display with no interactivity and no click handler.

### 5.4 Component §3.15 (Option Cards) Should Show the Custom Div Pattern

The current spec uses `<details>`. Production uses custom divs with JS toggle, left-border status indicator (recommended/alternative/blocked), and nested dimension sub-sections. The `<details>` version can't compose with rich nested interactivity.

### 5.5 JSON Code Block Component

A recurring pattern in system panels and API documentation sections. Needs a component definition:
```css
.sys-json {
  background: #0d1117; border: 1px solid #30363d; border-radius: 6px;
  padding: 10px 12px; font-family: monospace; font-size: 10px;
  color: #c9d1d9; white-space: pre; overflow-x: auto;
}
.sys-json .jk { color: #7ee787; }  /* keys */
.sys-json .js { color: #a5d6ff; }  /* strings */
.sys-json .jn { color: #79c0ff; }  /* numbers */
.sys-json .jc { color: #8b949e; }  /* comments */
```

### 5.6 Comparison Annotation Tags

A reusable pattern for any before/after or option comparison:
```css
.wire-tag-new { background: #dbeafe; color: #1e40af; }     /* new feature */
.wire-tag-same { background: #f3f4f6; color: #6b7280; }    /* unchanged */
.wire-tag-better { background: #d1fae5; color: #065f46; }  /* improvement */
.wire-tag-regress { background: #fef3c7; color: #92400e; } /* regression */
```

### 5.7 The Append-Only Discipline

Long-lived HTML files require an append-only mental model. Existing content is load-bearing infrastructure. You add to it; you don't reshape it. This principle underlies most anti-patterns (no reorganization, no CSS consolidation, no whitespace reformatting, no JS refactoring) but isn't stated explicitly as a governing philosophy. It should be — it's the single sentence that, if internalized, prevents most corruption.

---

## 6. Prioritized Action Plan

| # | Action | Section affected | Effort | Impact |
|---|---|---|---|---|
| 1 | Add injection script template + three-point pattern as first-class workflow | §6.3 (new §6.3.1) | Medium | **Critical** — this is how 80% of edits actually happen |
| 2 | Add session initialization protocol | New §6.0 | Small | High — prevents corruption from blind starts |
| 3 | Add decision matrix: which tool for which edit | §6.1 | Small | High — prevents wrong tool choice |
| 4 | Add 5 missing anti-patterns | §6.4 | Small | High — each prevents a class of corruption |
| 5 | Add anchor convention documentation | §6.1 (new §6.1.1) | Small | Medium — makes future edits reliable |
| 6 | Add CSS scoping guidance | New §6.8 | Small | Medium — prevents style bleed |
| 7 | Elevate browser preview to non-negotiable | §6.2 | Tiny | Medium — catches visual corruption |
| 8 | Expand version management | §6.7 | Small | Medium — catches silent data loss |
| 9 | Upgrade gallery SVGs | gallery HTML | Medium | High — currently below production standard |
| 10 | Add custom collapsible sections to gallery | gallery HTML | Medium | High — demonstrates the real structural pattern |
| 11 | Enrich gallery calculator | gallery HTML | Medium | Medium — shows production sophistication |
| 12 | Define Presentation-class artifact type | §2 (new §2.3), §8 (new §8.3) | Large | High — entirely missing artifact class |
| 13 | Add second gallery example (Presentation-class) | gallery/ | Large | High — demonstrates the other half of the spec |
| 14 | Upgrade Step Navigator component | §3.12 | Medium | Medium — currently non-interactive |
| 15 | Add JSON code block + comparison tags components | §3 (new §3.22, §3.23) | Small | Medium — commonly used patterns |

---

*This review is from the session that maintained 4000+ lines of interactive HTML across 20+ editing cycles. Every recommendation traces to a specific failure mode or production pattern encountered during that work.*

---

## Appendix: Direct Edits Made to STANDARD.md

The following edits were applied directly to `STANDARD.md` by the reviewing session (prism). These correspond to action items 1-8 from the prioritized plan above. Gallery edits (items 9-15) are documented but not yet applied.

| # | Edit | Lines added | Section |
|---|---|---|---|
| 1 | Session initialization protocol | ~20 | New §6.0 |
| 2 | Decision matrix: which tool for which edit | ~40 | §6.1 (rewritten as "Editing Workflows by Scale") |
| 3 | Three distinct workflows (small/medium/large) | ~30 | §6.1 (under decision matrix) |
| 4 | Anchor conventions + grep-first workflow | ~25 | New §6.1.1 |
| 5 | Section-based extract/replace (preserved) | — | Renumbered as §6.1.2 |
| 6 | Injection script template (full Python template) | ~50 | §6.3 (expanded multi-point injection) |
| 7 | 5 additional anti-patterns + append-only discipline | ~25 | §6.4 |
| 8 | Browser preview elevated to non-negotiable | ~10 | §6.2 |
| 9 | CSS scoping guidance | ~15 | New §6.8 |
| 10 | Version discipline expanded (baselines, footer, HTML comment log) | ~15 | §6.7 |

**Net change:** 1648 → 1841 lines (+193 lines, all in §6 Production Methodology).

**Remaining work for a follow-up session:**
- Gallery HTML upgrades (items 9-15: SVGs, collapsible sections, calculator, Presentation-class example)
- Component spec upgrades (§3.12 Step Navigator interactivity, §3.15 custom div cards)
- New artifact class definition (§2.3 Presentation-class, §8.3 skeleton)
- New component definitions (§3.22 JSON code blocks, §3.23 comparison annotation tags)
