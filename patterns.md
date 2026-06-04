# HTML Patterns Reference

The canonical component and convention reference for self-contained HTML
generation. New generators should match these patterns unless there is a
documented reason to diverge.

> This file is the **dashboard/component-derived** reference. The token system in
> [`STANDARDS.md`](./STANDARDS.md) §2 is the canonical palette for new
> document-class artifacts; the palette below is an alternate, lighter-weight set
> proven in data dashboards. Pick one palette per artifact and use it whole.

---

## CSS Custom Properties

All pages declare CSS variables on `:root`. Include the full block — light and dark — in every generator. Do not subset it.

### Light mode (`:root`)

| Variable | Value | Purpose |
|----------|-------|---------|
| `--bg` | `#f5f5f5` | Page background |
| `--surface` | `#fff` | Card/section background |
| `--surface2` | `#f0f0f0` | Secondary surface (stat cards, summary blocks) |
| `--border` | `#ddd` | Border color |
| `--text` | `#1a1a1a` | Primary text |
| `--text2` | `#555` | Secondary text (subheadings, labels) |
| `--text3` | `#888` | Tertiary text (timestamps, metadata, empty states) |
| `--accent` | `#4a7fc0` | Links, primary numbers, chart bars |
| `--accent-light` | `#e8f0fa` | Accent background tint |
| `--shadow` | `0 1px 4px rgba(0,0,0,.08)` | Card shadow |

**Status badge color pairs** (col = text, bg = background):

| Badge class | Variable pair | Semantic |
|-------------|--------------|---------|
| `.bd` | `--done-col` / `--done-bg` | done (`#1a7a3c` / `#d4f7e0`) |
| `.bp` | `--pend-col` / `--pend-bg` | pending (`#a06000` / `#fef3cd`) |
| `.bf` | `--fail-col` / `--fail-bg` | failed / blocked (`#c0392b` / `#fde8e6`) |
| `.ba` | `--act-col` / `--act-bg` | active / executing (`#1565c0` / `#e3f0ff`) |
| `.bc` | `--cl-col` / `--cl-bg` | closed / neutral (`#666` / `#eee`) |

### Dark mode (`@media(prefers-color-scheme:dark)`)

Override the same variables for dark. Key shifts:

| Variable | Dark value |
|----------|-----------|
| `--bg` | `#0f1117` |
| `--surface` | `#1c1f2a` |
| `--surface2` | `#252837` |
| `--border` | `#333` |
| `--text` | `#e8e8e8` |
| `--text3` | `#666` |
| `--accent` | `#6fa3e0` |
| `--accent-light` | `#1a2540` |
| `--shadow` | `0 1px 4px rgba(0,0,0,.4)` |

Status badge variables shift to higher-contrast dark equivalents (e.g. `--done-col: #4ade80`, `--done-bg: #0a2e1a`).

---

## Recurring CSS Patterns

### Layout

```css
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;background:var(--bg);color:var(--text);line-height:1.5}
.wrap{max-width:1000px;margin:0 auto;padding:16px}
```

Single `.wrap` div, max-width 1000px, centered. All content inside it.

### Section cards (`.sec`)

```css
.sec{background:var(--surface);border:1px solid var(--border);border-radius:10px;padding:16px;margin-bottom:14px;box-shadow:var(--shadow)}
```

Used for every major content block. Section heading uses `.h2` (`.85rem`, uppercase, `var(--text2)`).

### Stat cards (`.scard` inside `.pgrid`)

```css
.pgrid{display:grid;grid-template-columns:repeat(auto-fit,minmax(110px,1fr));gap:10px;margin-bottom:12px}
.scard{background:var(--surface2);border-radius:8px;padding:10px 12px;text-align:center}
.scard .n{font-size:1.5rem;font-weight:700;color:var(--accent)}
.scard .l{font-size:.65rem;color:var(--text3);text-transform:uppercase;letter-spacing:.04em}
```

For numeric metrics: large `.n` (number) + small `.l` (label). Auto-fills columns.

### Status badges (`.badge`)

```css
.badge{display:inline-block;padding:2px 7px;border-radius:10px;font-size:.72rem;font-weight:600;white-space:nowrap}
```

Apply one of `.bd`, `.bp`, `.bf`, `.ba`, `.bc` as a modifier. Mapping convention (JS) — adapt the keys to your own domain's statuses:

```js
const STATUS_BADGE_MAP = {
  'done':'bd','closed':'bc','expired':'bc','cancelled':'bc',
  'failed':'bf','blocked':'bf','needs-review':'bf',
  'active':'ba','executing':'ba','running':'ba',
  'proposed':'bp','pending':'bp',
};
```

### Tables (`.tbl`)

```css
.tbl{width:100%;border-collapse:collapse;font-size:.8rem}
.tbl th{text-align:left;padding:5px 8px;color:var(--text3);font-size:.68rem;font-weight:600;text-transform:uppercase;letter-spacing:.04em;border-bottom:1px solid var(--border)}
.tbl td{padding:6px 8px;border-bottom:1px solid var(--border);vertical-align:top}
.tbl tr:last-child td{border-bottom:none}
```

### Detail grid (`.dgrid` + `.dkv`)

```css
.dgrid{display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:8px}
.dkv .k{color:var(--text3);font-size:.67rem;text-transform:uppercase;letter-spacing:.04em}
.dkv .v{color:var(--text);font-weight:500;font-size:.8rem}
```

Key-value pairs in a responsive grid. Use for structured metadata (created at, status, etc).

### Audit timeline (`.tl` / `.tli`)

```css
.tl{display:flex;flex-direction:column;gap:4px}
.tli{display:flex;gap:8px;font-size:.75rem;align-items:flex-start}
.tlts{color:var(--text3);white-space:nowrap;min-width:115px;font-size:.68rem;padding-top:1px}
```

Each row: timestamp (`.tlts`) + symbol + event name + optional note. Color convention:
- `✓` / `.tlto` — successful completion (`var(--done-col)`)
- `✗` / `.tlfr` — failure (`var(--fail-col)`)
- `→`, `○`, `·` / `.tlsym` — neutral events (`var(--text3)`)

### Empty states

```css
.empty{text-align:center;padding:24px 20px;color:var(--text3);font-size:.85rem}
```

Use inside any section when the data list is empty.

---

## Data Injection: The `D_JSON` Pattern

The generator serializes all page data to a single JSON blob, then injects it as a JS constant named `D`.

**Generation side (Python example):**

```python
payload = {
    "items": items_data,
    "audit_trail": audit_trail,
    # ... all page data
    "generated_at": datetime.now(timezone.utc).isoformat(),
}
d_json = json.dumps(payload, ensure_ascii=False, separators=(",", ":"), default=str)
html = template.format(D_JSON=d_json, ...)
```

Key points:
- `separators=(",", ":")` — compact JSON (no whitespace)
- `default=str` — handles non-serializable types (datetime, etc.) gracefully
- `ensure_ascii=False` — allows unicode

**HTML template side:**

```html
<script>
const D = {D_JSON};
</script>
```

**JS side:**

```js
const items = D.items;
const meta = D.generated_at;
// etc.
```

All rendering logic reads from `D`. No separate AJAX calls. The page is fully self-contained.

### Template variable naming

Use named placeholders (e.g. Python `str.format()`). The `D_JSON` placeholder is the data blob. Additional placeholders (e.g. `{title}`) are for static values needed in `<title>` or as bare text before JS runs.

When the HTML template itself contains `{` or `}` (CSS, JS), double them: `{{` and `}}`.

---

## JavaScript Conventions

### No external dependencies

All pages are fully self-contained. No CDN URLs (except the D3 link when a concept graph is present). Simple charts are built with raw CSS/HTML (bar charts as `<div>` elements with inline `height` styles).

### Data access pattern

JS reads from the injected `D` constant. All render functions are pure: they take data and return HTML strings, then assign to `element.innerHTML`.

### Helper functions (shared vocabulary)

Every generator should include these standard helpers or equivalent:

```js
function fmt(n) { return n == null ? '—' : Number(n).toLocaleString(); }
function fmtDate(s) {
  if (!s) return '—';
  try { return new Date(s).toISOString().slice(0, 16).replace('T', ' ') + ' UTC'; }
  catch(e) { return s.slice(0, 16); }
}
function fmtDuration(secs) {
  if (secs == null || secs < 0) return '—';
  if (secs < 60) return secs + 's';
  if (secs < 3600) return Math.floor(secs/60) + 'm ' + (secs%60) + 's';
  const h = Math.floor(secs/3600);
  const m = Math.floor((secs%3600)/60);
  return h + 'h ' + m + 'm';
}
```

Null/missing values always display as `'—'` (em dash), not empty string or `null`.

### Meta line

Every page sets a generated-at timestamp via JS so it reflects the viewer's browser time:

```js
document.getElementById('meta-line').textContent = 'Generated ' + new Date().toUTCString();
```

---

## Generator Script Conventions

These conventions assume a Python generator, but the shape (pure render +
separate delivery + CLI) translates to any language.

### File location

Put generators in a dedicated module/package, not the repository root or your
task/cron scripts. One module per artifact type.

### Module docstring

Every generator starts with a module-level docstring stating:
- What it produces
- Entry points (functions and CLI)
- Design notes (pure function composition, data-access pattern)

Example structure:
```
"""
my_generator.py — Generate a standalone HTML page for X.

Entry points:
    generate_and_deliver(id, db_path?) -> str   # returns URL/path
    generate_html(data_dict) -> str             # pure: data -> HTML

CLI:
    my_generator --id <id> [--db PATH]

Design:
- Pure function composition; delivery is separate from rendering.
"""
```

### Function naming

| Function | Purpose |
|----------|---------|
| `generate_html(data, ...)` | Pure function: data → HTML string. No I/O. |
| `generate_and_deliver(id, ...)` | Fetch data, call `generate_html`, write/host the file, return URL or path. |
| `main(argv?)` | CLI entrypoint. Parse args, call `generate_and_deliver`, print the result. |
| `_fetch_*(conn, id)` | Data fetch helpers. Each takes an open connection, returns a plain dict or list. |
| `_compute_*(...)` | Pure computation helpers (elapsed time, cost estimates). |
| `_fmt_*(...)` | Formatting helpers (durations, numbers). |

### CLI pattern

```python
def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="...")
    parser.add_argument("--id", required=True)
    parser.add_argument("--db", default=None)
    args = parser.parse_args(argv)
    try:
        url = generate_and_deliver(args.id, db_path=Path(args.db) if args.db else None)
        print(url)
        return 0
    except ValueError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    sys.exit(main())
```

### DB access (if you read from SQLite)

Use WAL mode + busy_timeout for concurrency safety:

```python
def _connect(db_path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(str(db_path), timeout=10.0)
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA busy_timeout=5000")
    conn.row_factory = sqlite3.Row
    return conn
```

Open once, pass to all `_fetch_*` functions, close in a `finally` block.

### Error handling

- `ValueError` for not-found entities (propagate to CLI as exit 1)
- Graceful `[]` returns for missing optional tables (try/except `sqlite3.OperationalError`)
- File write errors: let them propagate (do not silently swallow)

---

## Decision Analysis Component

A reusable pattern for structured option comparison. Use when a decision has 2–4 options and the implicit constraints need surfacing before the choice becomes clear. Works best for architectural and design decisions where the "obvious" answer only becomes obvious after analysis — if the recommendation was clear before writing the table, the table was unnecessary; if it became clear after, the table did real epistemic work.

### When to use

- Any architectural or design decision with 2–4 named options
- When the naive answer is defensible but may not be correct under your specific constraints
- When you want to prevent the decision from being revisited — written analysis creates a durable record of why the alternative was rejected
- Does not apply to preference decisions (style, naming) where analysis dimensions don't differ meaningfully between options

### Structure

**Section header:** Question number (01, 02, 03) + bold title. Numbering groups related decisions and makes cross-references unambiguous.

**Named options:** Descriptive names, not "Option A / Option B." Names should encode the key structural difference (e.g., "Collocated" vs. "Standalone"). A reader should be able to recall which option is which from the name alone.

**Multi-lens analysis table:** Rows = options, columns = analysis dimensions. Use `.tbl` for styling.

Standard dimensions (use all that apply; omit irrelevant ones):

| Dimension | What it tests |
|-----------|--------------|
| Security | Data/credential leakage surface, replay attack vectors |
| System Design | Structural fit with existing architecture; does it require new abstractions? |
| Conventions | Conformance with established project conventions |
| Right Layer | Is the responsibility being assigned to the correct component? |
| Throughput/Ops | Performance at expected load; operational overhead |
| Maintenance | Long-term cost; what breaks when requirements change |

Cell values are brief verdicts, not explanations. The explanation lives in the callouts below.

**Context callout:** 2–3 bullets on what makes this decision non-generic. This is the section that prevents the analysis from being lifted and reapplied incorrectly elsewhere — name the project-specific constraints that ruled out an option.

**Recommended lean callout:** Accent-colored box with a firm recommendation and one key non-obvious reason. No hedging language ("probably", "might"). If the analysis is genuinely ambiguous, say so and name what additional information would resolve it.

### CSS classes

```css
.tbl          /* Analysis table — see Recurring CSS Patterns */
.sec          /* Section wrapper */
.decision-lean {
    border-left: 3px solid var(--accent);
    background: var(--accent-light);
    padding: 10px 14px;
    border-radius: 0 6px 6px 0;
    margin-top: 10px;
    font-size: .82rem;
}
```

### Meta principle

The value of the format is making implicit constraints explicit. The recommendation emerges from the analysis — writing the analysis IS the decision work. A decision analysis that concludes "it depends" has failed: either a required dimension was omitted, or the decision genuinely requires more information — in which case the callout should name exactly what information is missing and who can provide it.

---

## Hygiene Rules

**What to replicate vs. what to reference**

| Element | Rule |
|---------|------|
| CSS custom properties block | Copy the full `:root` + dark media query verbatim into every generator's template. No partial copies. |
| CSS class definitions | Copy the shared classes (`.sec`, `.badge`, `.scard`, `.pgrid`, `.tbl`, etc.) into every generator. They are self-contained. |
| JS helpers (`fmt`, `fmtDate`, `fmtDuration`) | Copy into every generator's inline `<script>`. |
| `D_JSON` injection pattern | Copy exactly: `json.dumps(payload, ensure_ascii=False, separators=(",", ":"), default=str)` |
| Delivery plumbing | Keep it in one place; consider extracting to a shared module once you have more than one generator. |
| DB connection helper | Copy `_connect()` exactly; WAL + busy_timeout is required. |

**What NOT to do**

- Do not pull CSS from a CDN or external stylesheet (the D3 link is the only allowed exception)
- Do not use an HTML templating library (Jinja2, etc.) — the f-string/`.format()` pattern is intentional for self-containment
- Do not create a new color palette; extend the existing custom properties if new semantic colors are needed
- Do not put HTML generation logic in unrelated entrypoints (schedulers, request handlers); put it in a dedicated generator module
- Do not share the same output filename across multiple callers — always generate a unique (e.g. `uuid4().hex`) filename

**Before creating a new generator**

1. Check if an existing generator can be extended rather than duplicated
2. Confirm the CSS block is the full shared set (not a subset)
3. Confirm `generate_html()` is a pure function (no DB calls, no file I/O)
4. Confirm the delivery step creates its output dir with `mkdir(parents=True, exist_ok=True)`
5. Confirm the CLI prints the URL/path to stdout and exits 0 on success, 1 on error
