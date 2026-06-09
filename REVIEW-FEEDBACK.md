# Review Feedback — html-mastery PR

> **From:** Production operator session (4,460-line decision document, 664 divs, 20+ editing sessions, 50+ surgical edits in the review session alone).
> **For:** Integration into STANDARD.md, tools, skill, and gallery.
> **Principle:** Broader patterns only. Specific examples only where the meta-pattern alone is insufficient.

---

## STANDARD.md Additions

### §3: New Components

#### Coverage/Capability Matrix (new component)

A requirements-by-provider matrix with ✓/✗/⏱ marks and a gap-risk column. Summary row aggregates uncovered volume/count with color-coded callout boxes.

**When to use:** Any decision comparing providers/options against a known set of requirements (jurisdictions, features, compliance, coverage timelines).

**Structure:**
- Header row: Requirement | Provider A | Provider B | Provider C | Gap Risk
- Cell values: ✓ (covered), ✗ (absent), ⏱ (roadmapped with date), partial text
- Summary row: 3 color-coded callout boxes (green = full coverage, red = gap with quantified impact, yellow = conditional)

**Why a component, not just a table:** The gap-risk column and summary callouts are the differentiator. A plain comparison table shows facts; a coverage matrix shows *what's at stake* per gap.

---

#### Question/Decision Registry (new component)

A prioritized list of open items with scope, blocking relationships, status, and ownership. Groups by urgency tier with color-coded left borders and count badges.

**Structure:**
- Tier headers: Urgent (red) / Fast Follow (yellow) / Nice to Have (muted), each with item count badge
- Table columns: # | Question | Scope | Blocks | Status / Next Step | Owner
- Left border colors: red (open/blocking), yellow (partially resolved), green (resolved)
- Status cells support rich content: confirmed items (✓), partial resolution with remaining gaps, linked references to other sections

**Why a component:** Decision documents accumulate questions across sessions. Without a registry, open items scatter across sections and get lost. The registry is both a tracking tool and a presentation surface for stakeholders.

---

#### Convergence Confidence Display (new component)

Shows working direction + evidence + confidence percentage + "what could change" for converging decisions.

**Structure:**
- Table: Direction | Evidence | Confidence | What Could Change
- Left border: accent color (all items are "converging" — fully resolved items move to a separate "Confirmed" section)
- Confidence as colored percentage: green (>80%), yellow (60-80%), red (<60%)

---

#### Split-Panel Comparison (new component)

Side-by-side panels showing two states, providers, or journeys. Each panel has a header, content area, and optional change-classification tags.

**When to use:** Before/after UX flows, provider A vs provider B experience, current state vs proposed state.

**Structure:**
- Container: `display: grid; grid-template-columns: 1fr 1fr; gap: 16px`
- Each panel: header (label + optional badge), content area
- Change tags: inline badges classifying each element as NEW / SAME / BETTER / REGRESSION
- Optional: system annotations in muted text below each step (API calls, webhooks, latency)

---

### §3.13: Calculator Enhancements

**Add: Multi-scenario branching pattern.**

When a calculator models multiple providers or configurations with different cost structures:

1. **Named constant blocks** at the top of the IIFE, one per provider:
   ```js
   // Provider A constants
   const A_TIERS = [...], A_MIN = 4000;
   // Provider B constants  
   const B_BURN = 0.0005, B_WIRE = 25;
   ```

2. **Provider read** in `update()`:
   ```js
   const provider = document.querySelector('input[name="provider"]:checked').value;
   const isB = provider === 'b';
   ```

3. **Conditional branches** per cost line — orchestration, settlement, burn, yield, AUM all branch on provider.

4. **Control visibility** — hide irrelevant inputs when a provider is selected (e.g., hide burn toggle when provider B always charges 5 bps). Show contextual caveat notes.

5. **Label updates** — result row labels change to reflect selected provider.

6. **Radio button styling** — active provider gets accent border/background; switch resets all labels and re-runs `update()`.

---

### §3.15: Option Card Synchronization Checklist

**Add to the Option Card component spec:**

An option card has 4 synchronized layers. When changing a card's status, all must be updated together:

| Layer | What to change |
|-------|---------------|
| CSS class on card div | `recommended` / `alternative` / `blocked` |
| Badge text and class | `rec` / `alt` / `blk` (or expanded names) |
| Info box severity | `good` / `warn` / `bad` / `neutral` + content |
| SVG annotations | Colors (red→amber→green), labels, border style (dashed→solid) |

Failure mode: updating the info box text but forgetting the CSS class leaves a red-bordered card with content saying "now available" — visually contradictory.

---

### §3.5: Data Provenance Badges (new status tier)

**Add alongside existing status badges:**

Decision documents need a confidence spectrum for vendor/external claims that maps to data provenance, not task status:

| Badge | Meaning | Marker | Use |
|-------|---------|--------|-----|
| Confirmed | In writing (contract, term sheet, docs) | ✅ | Pricing, feature availability |
| Verbal | Claimed in calls/meetings, not written | ◐ | Rate estimates, timelines |
| Documented-pre-GA | API docs exist but feature not production-ready | ⚠️ | Pre-release features |
| Coming Soon | Mentioned but not documented | ⏳ | Roadmap items |
| Absent | Not mentioned in any source | ❌ | Coverage gaps |

These are orthogonal to task status badges (Done/Pending/Failed). A cell can be "Done" (we've researched it) but "Verbal" (the data is unconfirmed).

---

### §5: SVG Theme Awareness

**Add to §5.1 Flow Diagrams:**

SVG fills and strokes should work on both dark and light themes. The 4 semantic color roles (indigo/violet/amber/green) already have good contrast on dark backgrounds. Avoid:
- Hardcoded white (`#FFFFFF`) fills — invisible on light backgrounds, stark on dark
- Hardcoded black text — invisible on dark backgrounds
- Theme-specific fills without a fallback

Test every SVG on both themes before committing. The gallery artifact's SVGs currently have hardcoded light-mode fills that break on dark backgrounds.

---

## §6: Methodology Additions

### 6.1: Bottom-Up Editing Discipline

When editing multiple sections interactively (not via a single transform script), line numbers shift after each replacement. Two safe approaches:

1. **Work bottom-up** — edit the highest line-number section first, so earlier sections' line numbers remain stable.
2. **Re-index after each replacement** — run `html-tool.sh sections` after every `replace` to get updated line numbers.

Transform scripts avoid this problem entirely (all replacements happen in one pass on the in-memory string).

### 6.2: `.bak` Recovery Workflow

`html-tool.sh replace` creates a `.bak` file. When validation fails after a replace:

1. Restore: `cp file.bak file.html`
2. Diff: `diff file.bak replacement-content.html` to find the discrepancy
3. Fix the replacement content
4. Re-run `replace` + `validate`

The `.bak` file is the safety net. Mention it explicitly.

### 6.3: Transform Script Template Enhancement

Replace the bare `str.replace()` in the template with:

```python
def replace_once(html, old, new, label):
    count = html.count(old)
    if count == 0:
        print(f"  WARNING: '{label}' — target not found!")
        return html
    if count > 1:
        print(f"  WARNING: '{label}' — {count} matches, replacing first only")
        return html.replace(old, new, 1)
    print(f"  OK {label}")
    return html.replace(old, new)
```

This is the single most impactful pattern for maintaining large documents. Without match-count validation, transforms silently hit the wrong instance or miss entirely. Large HTML files have many identical cell structures — surrounding context is required for uniqueness, and the count check proves it.

### 6.4: Add Anti-Pattern — Factual Claim Cascade

When a factual claim (pricing, status, capability) appears in a comparison table, it tends to propagate to downstream sections via copy-paste across sessions: negotiation levers, registry entries, info boxes, tooltips, prose summaries. Changing the claim in one location without sweeping for echoes leaves contradictions.

**Required step after any batch of factual edits:**

```bash
grep -n "old_claim_text" artifact.html
```

Update every instance or document why an instance is intentionally different. This is not structural validation — it's semantic consistency. The validator won't catch it.

### 6.5: Substance vs. Presentation — Concrete Decision Examples

The "is this substance or presentation?" test benefits from examples:

| Edit | Classification | Reason |
|------|---------------|--------|
| Filling pricing data from a term sheet into table cells | Substance | New factual data entering the document |
| Enabling a disabled radio button in a calculator | Presentation | UI control change, no new analysis |
| Updating SVG annotation colors from red to amber | Presentation | Visual status indicator |
| Adding a "feature X is coming soon" warning box | Substance | New finding about capability availability |
| Changing card CSS class from `blocked` to `alternative` | Presentation | Visual status change (but triggered by substance change) |

### 6.7: Version Number Locations

Version numbers may appear in multiple document locations. All must be updated together:

- Header meta-pill or badge
- Footer/colophon text
- `<meta>` tags (`doc-version`, `doc-updated`)

A version bump checklist:
1. Validate clean (prerequisite)
2. Update ALL version-number locations
3. Validate again
4. Record in commit: `v9.2 → v9.3, 4442 lines, 662 divs`

### New §6.8: Pre-Publish Sweep

After all edits are complete, before declaring the document updated:

1. `python3 validate.py <file>` — full three-pass validation
2. `grep -n` sweep for stale factual claims (old provider names, superseded pricing, outdated status language)
3. Version-number locations all match
4. Card layer synchronization check (CSS class, badge, info box, SVG all agree)
5. Browser preview on both themes
6. Check calculator behavior with each provider/scenario selected

---

## Tools

### validate.py — Add Configurable Containment Check

The original project's validator checks that every container of class X has required children Y and Z, both properly closed before the next X. This catches child-escaping-parent bugs that div-balance and block-element tracking miss.

**Recommendation:** Add a `--require-children` flag:
```bash
python3 validate.py artifact.html --require-children "option-card:option-card-header,option-card-body"
```

Or read from a `.validate.json` config:
```json
{
  "containment": [
    {"parent": "option-card", "children": ["option-card-header", "option-card-body"]}
  ]
}
```

### html-tool.sh — Wire Validate to Python

`html-tool.sh validate` currently runs inline bash div-balance checking. `validate.py` provides strictly more validation. The bash tool should delegate to `validate.py` when present in the same directory (as the original project's tool does), falling back to inline bash only when Python is unavailable.

### html-tool.sh — Hierarchical Section Display

The flat `sections` table loses parent-child relationships. When sections are nested (cards inside panels inside sections), indent child sections under their parent:

```
panel-omnibus              546-1130  (585 lines)
  provider-omnibus-bridge    800-962   (163 lines)
  provider-omnibus-cb        969-1062  (94 lines)
panel-hold                 1207-1703 (497 lines)
  provider-hold-bridgecb    1288-1420 (133 lines)
```

This is operationally useful for navigating large documents with nested structure.

---

## Skill (SKILL.md)

1. **Add `HTML_TOOL_FILE` setup instruction.** First thing an operator needs before any `html-tool.sh` command.

2. **Add the `replace_once()` template.** Copy the helper function as a code block. This is the highest-impact addition for operators.

3. **Clarify validator hierarchy.** State that `python3 validate.py` is the authoritative validator; `html-tool.sh validate` is a convenience wrapper that should delegate to it.

4. **Add multi-section editing note.** Work bottom-up or re-index after each replace.

5. **Add `.bak` recovery mention.** One sentence: "If validation fails after a replace, restore from the `.bak` file created by `html-tool.sh replace`."

---

## Gallery

**Recommendation: Add a second artifact.**

The current `decision-document.html` demonstrates component breadth at 1,285 lines. Add a `complex-decision-document.html` at 2,000+ lines that demonstrates:

- Multi-section comparison with nested cards (3+ levels of hierarchy)
- Interactive calculator with provider/scenario branching (conditional constants, control visibility)
- Coverage/capability matrix with gap quantification
- Question registry with urgency tiers
- Split-panel comparison layouts
- Theme-aware SVGs
- TOC with anchor navigation
- Multiple tab systems
- ARIA roles on all interactive components
- Convergence confidence display

This closes the "template vs. production" gap and gives operators a reference for what the spec produces at scale.

Also for the existing gallery piece:
- Remove dead code (`fmt`, `fmtDate`, `fmtDuration` — defined but never called)
- Fix theme-unaware SVG fills
- Expand badge classes from cryptic (`.bd`, `.bp`) to readable (`.badge-done`, `.badge-pending`)
- Add ARIA roles to tabs and step-nav
