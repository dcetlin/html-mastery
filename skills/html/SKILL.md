---
name: html
description: Produce and maintain rich interactive HTML documents. Triggers on creating, editing, or rendering self-contained HTML artifacts. Covers design system, 28 components, SVG conventions, and production methodology for files up to 4,000+ lines.
---

# HTML Document Skill

Operational guide for producing and maintaining self-contained HTML artifacts using the html-mastery spec.

**Read `STANDARD.md` first.** This skill routes you to the right section — it does not duplicate the spec.

## Quick Reference

| You want to... | Read | Tool |
|----------------|------|------|
| Create a new artifact | §2 (artifact classes), §8 (skeletons) | Copy a skeleton, never start blank |
| Edit a large file (500+ lines) | §6.1 (workflows by scale) | `html-tool.sh extract/replace` |
| Add a section with CSS+HTML+JS | §6.3 (injection scripts) | Python three-point injection |
| Make bulk mechanical changes | §6.3 (transform scripts) | Python with `replace_once()` |
| Build an SVG diagram | §5 (SVG conventions) | Hand-crafted inline SVG |
| Render HTML to PNG | §7 (Chromium pipeline) | `chromium --headless` |
| Validate structure | §6.2 (validation) | `python3 tools/validate.py <file>` |

## Setup

```bash
export HTML_TOOL_FILE=my-document.html
```

## The Rules

1. **Validate after every edit.** `python3 tools/validate.py <file>`. Non-negotiable.
2. **Never full-file rewrite** of 500+ line HTML. Extract → edit → replace.
3. **Substance → markdown first.** Presentation → HTML directly. (§6.5)
4. **Dark mode is the default.** Light mode is the override. (§1.1)
5. **Prefix SVG marker IDs** per diagram to avoid collision. (§5.1)

## Artifact Classes

- **Document-class** — reports, design docs, decisions, audits. Required: toggle, section IDs, comment widget, version meta.
- **Dashboard-class** — data dashboards, monitoring tools. Required: toggle, filter bar, status badges.
- **Presentation-class** — slide-based storyboards, journey walkthroughs. Required: track tabs, slide nav, keyboard arrows, full-viewport.

## Anti-Patterns (memorize these)

- Subagent full-file rewrite of 1500+ lines → truncation, silent drops
- Edit tool on large HTML with entities → match failures
- Mixing structural + semantic changes in one pass → both degraded
- Reorganizing a large file → untraceable full-file diff
- Consolidating "duplicate" CSS → subtle breakage
- Reformatting whitespace → enormous noise diffs

See §6.4 for all 10 + the Append-Only Discipline.

## Operator Patterns (for intensive sessions)

- **`replace_once()`** — validate exactly one match before replacing (§6.9)
- **Bottom-up editing** — highest line numbers first when making multiple edits
- **Factual claim sweep** — `grep -n "old_value"` after changing any fact
- **Card sync** — CSS class + badge + info box + SVG must all agree
- **`.bak` recovery** — restore from backup, don't fix forward
- **Pre-publish sweep** — validate + grep + version check + both themes + interactivity
