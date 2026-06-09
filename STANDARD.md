# STANDARD.md — Self-Contained HTML Artifact Specification

## Preamble

This is the single specification for producing production-quality, self-contained HTML artifacts. An LLM given this file and a content brief should produce a complete `.html` file that opens in any browser with no build step, no dependencies, no backend.

**The thesis:** HTML is a communication medium. Not a web app. Not a markdown preview. A well-built HTML artifact is a high-fidelity document that communicates structure, data, and interactivity in a single file that outlives the conversation that produced it. It has more expressive range than markdown (interactive calculators, flow diagrams, collapsible detail, inline annotation) without the complexity of a web application (no routing, no state management, no build toolchain).

**Who this is for:** LLMs generating HTML artifacts, and engineers reviewing or editing them.

**Invariants:**
- Every artifact is a single `.html` file. All CSS and JS inline. No external fonts, no CDN, no build step.
- The only permitted external dependency is D3.js (`https://d3js.org/d3.v7.min.js`) when a concept graph is present.
- Null/missing values display as `'—'` (em dash), never empty string or `null`.
- Version metadata: `<meta name="doc-version" content="X.Y">` and `<meta name="doc-updated" content="ISO8601">` in every `<head>`.

---

## 1. Design System

### 1.1 Color Tokens

Dark mode is the default. Light mode is a CSS class override on `<body>`.

```css
:root {
  --bg: #0b0d14;
  --surface: #141720;
  --surface2: #1c2030;
  --surface3: #232840;
  --border: #2a2f45;
  --border2: #363d5a;
  --text: #e4e6f0;
  --text2: #9aa0bb;
  --text3: #5c6480;
  --accent: #6ea8fe;
  --accent2: #a78bfa;
  --accent3: #34d399;
  --warn: #fb923c;
}

body.light-mode {
  --bg: #f8f9fb;
  --surface: #ffffff;
  --surface2: #f0f2f7;
  --surface3: #e8ecf4;
  --border: #dde1ee;
  --border2: #c8cedf;
  --text: #1a1d2e;
  --text2: #4a5068;
  --text3: #8890a8;
  --accent: #2563eb;
  --accent2: #7c3aed;
  --accent3: #059669;
  --warn: #ea580c;
}
```

Light mode overrides accent colors to higher-contrast values so text remains legible against light surfaces. Do not use the dark-mode accent values in light mode.

**Status badge tokens** (declare alongside the palette):

```css
:root {
  --done-col: #4ade80; --done-bg: #0a2e1a;
  --pend-col: #fbbf24; --pend-bg: #2a2008;
  --fail-col: #f87171; --fail-bg: #2e0a0a;
  --act-col: #60a5fa;  --act-bg: #0a1a2e;
  --cl-col: #9aa0bb;   --cl-bg: #1c2030;
}
body.light-mode {
  --done-col: #1a7a3c; --done-bg: #d4f7e0;
  --pend-col: #a06000; --pend-bg: #fef3cd;
  --fail-col: #c0392b; --fail-bg: #fde8e6;
  --act-col: #1565c0;  --act-bg: #e3f0ff;
  --cl-col: #666;      --cl-bg: #eee;
}
```

### 1.2 Typography

```css
body {
  font-family: system-ui, -apple-system, 'Segoe UI', sans-serif;
  font-size: 15px;
  line-height: 1.7;
  color: var(--text);
  background: var(--bg);
}
```

Monospace stack for code, IDs, and labels: `'SF Mono', 'Fira Code', ui-monospace, Menlo, Consolas, monospace`.

### 1.3 Layout

```css
* { box-sizing: border-box; margin: 0; padding: 0; }
.wrap { max-width: 820px; margin: 0 auto; padding: 56px 28px 120px; }
```

Document-class uses 820px max-width. Dashboard-class may use up to 1000px:

```css
.wrap { max-width: 1000px; margin: 0 auto; padding: 16px; }
```

All content lives inside a single `.wrap` div.

---

## 2. Artifact Classes

Every artifact is one of two classes. The class determines required features.

### 2.1 Document-class

**Use for:** reports, design docs, audits, proposals, structured presentations, analysis.

| Feature | Required? |
|---------|-----------|
| Light/dark toggle | Yes |
| Taxonomic section IDs (§-numbering) | Yes |
| Clipboard comment widget | Yes |
| Version meta tags | Yes |
| Canon badge in header | Optional |
| D3 concept graph | Optional |

### 2.2 Dashboard-class

**Use for:** data dashboards, interactive tools, monitoring views.

| Feature | Required? |
|---------|-----------|
| Light/dark toggle | Yes, if readable sections exist |
| Taxonomic section IDs | Yes, if readable sections exist |
| Clipboard comment widget | No (dashboards have their own interaction surface) |
| Filter bars | As needed |
| Status badges | As needed |
| Action buttons | As needed |
| `@media (prefers-color-scheme: dark)` alternative to toggle | Acceptable |

---

### 2.3 Presentation-class

**Use for:** slide-based presentations, storyboards, journey walkthroughs, experience comparisons, multi-track demos.

Full-viewport artifacts where content is organized into **tracks** (slide groups) and **slides** (individual steps within a track). The user navigates between tracks via tabs and between slides via step dots or arrow keys. Slides typically use a split-pane layout: one side shows a UI mockup (often with browser chrome), the other shows system-level context (API calls, state changes, webhook payloads).

Derived from production experience: LP Experience Storyboard (~2,237 lines, 9 tracks, 31 slides).

| Feature | Required? |
|---------|-----------|
| Light/dark toggle (3.1) | Yes |
| Track tabs (3.11 adapted) | Yes |
| Slide navigation with step dots (3.12 adapted) | Yes |
| Keyboard navigation (left/right arrows) | Yes |
| Full-viewport slides | Yes |
| Version meta tags | Yes |
| Split-pane layout (mockup + system panel) | Optional (common) |
| Browser chrome mockups (URL bar, back button) | Optional (common) |
| Comparison annotation tags (NEW/SAME/BETTER/REGRESSION) | Optional |
| Entry-point sub-toggles within tracks | Optional |
| JSON syntax highlighting in system panel | Optional |
| Taxonomic section IDs (3.2) | No (tracks + slide numbers replace section hierarchy) |
| Clipboard comment widget (3.4) | No (interaction surface is navigation, not annotation) |
| Status badges (3.5) | Optional (for comparison tags) |
| Stat cards (3.6) | No |
| Tables (3.7) | Optional (for system panel data) |
| Section cards (3.8) | No (slides replace cards) |
| Collapsible sections (3.10) | No (conflicts with full-viewport slide model) |
| Filter bars | No |

**Key distinctions from Document-class and Dashboard-class:**

- **Viewport model.** Documents scroll; dashboards scroll within cards; presentations fill the viewport per-slide. The `<body>` should suppress scroll. Each slide is `100vh`.
- **Navigation model.** Tracks are the top-level grouping (analogous to tabs but semantically distinct: each track is a self-contained narrative). Slides within a track are sequential steps. Arrow keys advance within the current track.
- **Content model.** Each slide typically presents a paired view: what the user sees (UI mockup) alongside what the system does (API/state). This split-pane is the dominant layout but not mandatory -- single-pane slides (e.g., a title slide or summary) are valid.

---

## 3. Components

### 3.1 Light/Dark Toggle

Fixed top-right. Persists via `localStorage`.

**CSS:**
```css
#theme-toggle {
  position: fixed;
  top: 14px;
  right: 18px;
  z-index: 1000;
  background: var(--surface2);
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 6px 12px;
  font-size: 12px;
  font-weight: 600;
  color: var(--text2);
  cursor: pointer;
  transition: background .15s, color .15s;
}
#theme-toggle:hover { background: var(--surface3); color: var(--text); }
```

**HTML** (just before `</body>`):
```html
<button id="theme-toggle" onclick="toggleTheme()">&#9788; Light</button>
```

**JS:**
```js
function toggleTheme() {
  var isLight = document.body.classList.toggle('light-mode');
  localStorage.setItem('theme', isLight ? 'light' : 'dark');
  document.getElementById('theme-toggle').textContent = isLight ? '☾ Dark' : '☆ Light';
}
(function() {
  if (localStorage.getItem('theme') === 'light') {
    document.body.classList.add('light-mode');
    var btn = document.getElementById('theme-toggle');
    if (btn) btn.textContent = '☾ Dark';
  }
})();
```

### 3.2 Taxonomic Section IDs

Every section gets a stable numeric ID displayed in the rendered HTML.

**Convention:** Top-level: `§1`, `§2`. Subsections: `§1.1`, `§1.2`. Sub-subsections: `§1.1.1`.

**HTML:**
```html
<div class="section" id="s1">
  <div class="section-header">
    <span class="section-id">&sect;1</span> Section Title
  </div>
  <!-- content -->
</div>

<div class="subsection" id="s1-1">
  <div class="subsection-header">
    <span class="subsection-id">&sect;1.1</span> Subsection Title
  </div>
  <!-- content -->
</div>
```

**CSS:**
```css
.section { margin-bottom: 56px; }
.section-header {
  font-size: 12px; font-weight: 700; text-transform: uppercase;
  letter-spacing: .1em; color: var(--text2); margin-bottom: 20px;
  padding-bottom: 10px; border-bottom: 1px solid var(--border);
  display: flex; align-items: center; gap: 8px;
}
.section-id {
  display: inline-block; font-size: 11px; font-weight: 700;
  color: var(--text3); font-family: 'SF Mono', 'Fira Code', monospace;
  user-select: none; flex-shrink: 0;
}
.subsection { margin-bottom: 32px; }
.subsection-header {
  font-size: 13px; font-weight: 700; color: var(--text);
  margin-bottom: 12px; display: flex; align-items: baseline; gap: 8px;
}
.subsection-id {
  font-size: 10px; font-weight: 700;
  font-family: 'SF Mono', 'Fira Code', monospace;
  color: var(--text3); user-select: none;
}
```

### 3.3 Document Header

**HTML:**
```html
<div class="doc-header">
  <!-- Optional canon badge -->
  <div class="canon-badge">Canon Entry &mdash; [Domain]</div>
  <div class="doc-title">Document Title</div>
  <div class="doc-subtitle">One-sentence framing of what this document establishes.</div>
</div>
```

**CSS:**
```css
.doc-header {
  margin-bottom: 56px; border-bottom: 1px solid var(--border); padding-bottom: 32px;
}
.doc-title {
  font-size: 26px; font-weight: 700; color: var(--text);
  letter-spacing: -.02em; margin-bottom: 10px; line-height: 1.3;
}
.doc-subtitle { font-size: 14px; color: var(--text3); line-height: 1.5; }
.canon-badge {
  display: inline-block; font-size: 10px; font-weight: 700;
  text-transform: uppercase; letter-spacing: .1em;
  color: var(--accent3); background: rgba(52, 211, 153, .1);
  border: 1px solid rgba(52, 211, 153, .25);
  border-radius: 4px; padding: 2px 8px; margin-bottom: 14px;
}
```

### 3.4 Clipboard Comment Widget (Document-class)

One text input per major section. "Copy comments" assembles `[§1] text | [§2] text` and writes to clipboard.

**HTML:**
```html
<div class="comment-widget" id="comment-widget">
  <div class="comment-widget-title">Section Comments</div>
  <div class="comment-inputs" id="comment-inputs"></div>
  <button class="copy-comments-btn" onclick="copyComments()">Copy comments</button>
  <div class="copy-feedback" id="copy-feedback"></div>
</div>
```

**CSS:**
```css
.comment-widget {
  margin-top: 48px; padding: 20px 24px;
  background: var(--surface); border: 1px solid var(--border); border-radius: 10px;
}
.comment-widget-title {
  font-size: 11px; font-weight: 700; text-transform: uppercase;
  letter-spacing: .09em; color: var(--text3); margin-bottom: 14px;
}
.comment-row { display: flex; align-items: center; gap: 10px; margin-bottom: 8px; }
.comment-label {
  font-size: 11px; font-weight: 700;
  font-family: 'SF Mono', 'Fira Code', monospace;
  color: var(--text3); min-width: 36px;
}
.comment-input {
  flex: 1; background: var(--surface2); border: 1px solid var(--border);
  border-radius: 6px; padding: 6px 10px; font-size: 12px;
  color: var(--text); outline: none;
}
.comment-input:focus { border-color: var(--accent); }
.copy-comments-btn {
  margin-top: 12px; padding: 8px 18px; background: var(--accent);
  color: #fff; border: none; border-radius: 6px;
  font-size: 12px; font-weight: 700; cursor: pointer; transition: opacity .15s;
}
.copy-comments-btn:hover { opacity: .85; }
.copy-feedback { margin-top: 8px; font-size: 11px; color: var(--accent3); min-height: 16px; }
```

**JS** (define `sections` array to match the document):
```js
var sections = [
  { id: 's1', label: '§1' },
  { id: 's2', label: '§2' },
  // match to actual document sections
];

(function buildCommentWidget() {
  var container = document.getElementById('comment-inputs');
  if (!container) return;
  sections.forEach(function(s) {
    var row = document.createElement('div');
    row.className = 'comment-row';
    row.innerHTML =
      '<span class="comment-label">' + s.label + '</span>' +
      '<input class="comment-input" type="text" id="ci-' + s.id +
      '" placeholder="Comment on ' + s.label + '…">';
    container.appendChild(row);
  });
})();

function copyComments() {
  var parts = sections.map(function(s) {
    var val = (document.getElementById('ci-' + s.id) || {}).value || '';
    return val.trim() ? '[' + s.label + '] ' + val.trim() : null;
  }).filter(Boolean);
  if (!parts.length) {
    document.getElementById('copy-feedback').textContent = 'Nothing to copy.';
    return;
  }
  navigator.clipboard.writeText(parts.join(' | ')).then(function() {
    document.getElementById('copy-feedback').textContent = 'Copied to clipboard.';
    setTimeout(function() {
      document.getElementById('copy-feedback').textContent = '';
    }, 2500);
  });
}
```

### 3.5 Status Badges

```css
.badge {
  display: inline-block; padding: 2px 7px; border-radius: 10px;
  font-size: .72rem; font-weight: 600; white-space: nowrap;
}
.bd { color: var(--done-col); background: var(--done-bg); }
.bp { color: var(--pend-col); background: var(--pend-bg); }
.bf { color: var(--fail-col); background: var(--fail-bg); }
.ba { color: var(--act-col);  background: var(--act-bg);  }
.bc { color: var(--cl-col);   background: var(--cl-bg);   }
```

**JS mapping convention** (adapt keys to your domain):
```js
var STATUS_BADGE_MAP = {
  'done': 'bd', 'complete': 'bd', 'success': 'bd',
  'pending': 'bp', 'proposed': 'bp', 'waiting': 'bp',
  'failed': 'bf', 'blocked': 'bf', 'error': 'bf',
  'active': 'ba', 'running': 'ba', 'executing': 'ba',
  'closed': 'bc', 'cancelled': 'bc', 'expired': 'bc',
};
```

**HTML usage:**
```html
<span class="badge bd">Done</span>
<span class="badge bp">Pending</span>
<span class="badge bf">Failed</span>
<span class="badge ba">Active</span>
<span class="badge bc">Closed</span>
```

### 3.6 Stat Cards

```css
.pgrid {
  display: grid; grid-template-columns: repeat(auto-fit, minmax(110px, 1fr));
  gap: 10px; margin-bottom: 12px;
}
.scard {
  background: var(--surface2); border-radius: 8px;
  padding: 10px 12px; text-align: center;
}
.scard .n { font-size: 1.5rem; font-weight: 700; color: var(--accent); }
.scard .l {
  font-size: .65rem; color: var(--text3);
  text-transform: uppercase; letter-spacing: .04em;
}
```

**HTML:**
```html
<div class="pgrid">
  <div class="scard"><div class="n">42</div><div class="l">Total Items</div></div>
  <div class="scard"><div class="n">98%</div><div class="l">Success Rate</div></div>
  <div class="scard"><div class="n">3.2s</div><div class="l">Avg Latency</div></div>
</div>
```

### 3.7 Tables

```css
.tbl { width: 100%; border-collapse: collapse; font-size: .8rem; }
.tbl th {
  text-align: left; padding: 5px 8px; color: var(--text3);
  font-size: .68rem; font-weight: 600; text-transform: uppercase;
  letter-spacing: .04em; border-bottom: 1px solid var(--border);
}
.tbl td {
  padding: 6px 8px; border-bottom: 1px solid var(--border); vertical-align: top;
}
.tbl tr:last-child td { border-bottom: none; }
```

### 3.8 Section Cards

```css
.sec {
  background: var(--surface); border: 1px solid var(--border);
  border-radius: 10px; padding: 16px; margin-bottom: 14px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, .08);
}
```

### 3.9 Detail Grids

Key-value pairs in a responsive grid.

```css
.dgrid {
  display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 8px;
}
.dkv .k {
  color: var(--text3); font-size: .67rem;
  text-transform: uppercase; letter-spacing: .04em;
}
.dkv .v { color: var(--text); font-weight: 500; font-size: .8rem; }
```

**HTML:**
```html
<div class="dgrid">
  <div class="dkv"><div class="k">Status</div><div class="v">Active</div></div>
  <div class="dkv"><div class="k">Created</div><div class="v">2025-01-15</div></div>
  <div class="dkv"><div class="k">Owner</div><div class="v">Engineering</div></div>
</div>
```

### 3.10 Collapsible Sections

**HTML:**
```html
<details class="collapse">
  <summary class="collapse-header">Section Title <span class="collapse-hint">(click to expand)</span></summary>
  <div class="collapse-body">
    <!-- content -->
  </div>
</details>
```

**CSS:**
```css
.collapse {
  background: var(--surface); border: 1px solid var(--border);
  border-radius: 10px; margin-bottom: 10px;
}
.collapse-header {
  padding: 12px 16px; font-size: 13px; font-weight: 700;
  color: var(--text); cursor: pointer; list-style: none;
  display: flex; align-items: center; gap: 8px;
}
.collapse-header::-webkit-details-marker { display: none; }
.collapse-header::before {
  content: '\25b6'; font-size: 10px; color: var(--text3);
  transition: transform .15s;
}
.collapse[open] > .collapse-header::before { transform: rotate(90deg); }
.collapse-hint { font-size: 11px; font-weight: 400; color: var(--text3); }
.collapse[open] .collapse-hint { display: none; }
.collapse-body { padding: 0 16px 14px; }
```

### 3.11 Tabs

**HTML:**
```html
<div class="tab-bar" id="tab-bar">
  <button class="tab-btn active" onclick="switchTab('overview')">Overview</button>
  <button class="tab-btn" onclick="switchTab('detail')">Detail</button>
  <button class="tab-btn" onclick="switchTab('raw')">Raw Data</button>
</div>

<div class="tab-panel active" id="tab-overview">
  <!-- overview content -->
</div>
<div class="tab-panel" id="tab-detail">
  <!-- detail content -->
</div>
<div class="tab-panel" id="tab-raw">
  <!-- raw data content -->
</div>
```

**CSS:**
```css
.tab-bar {
  display: flex; gap: 4px; margin-bottom: 16px;
  border-bottom: 1px solid var(--border); padding-bottom: 8px;
}
.tab-btn {
  padding: 6px 14px; font-size: 12px; font-weight: 600;
  color: var(--text3); background: none; border: none;
  border-radius: 6px 6px 0 0; cursor: pointer; transition: all .15s;
}
.tab-btn:hover { color: var(--text); }
.tab-btn.active {
  color: var(--accent); border-bottom: 2px solid var(--accent);
}
.tab-panel { display: none; }
.tab-panel.active { display: block; }
```

**JS (container-scoped — safe with multiple tab bars):**
```js
function switchTab(name, container) {
  var scope = container || document;
  scope.querySelectorAll('.tab-btn').forEach(function(b) { b.classList.remove('active'); });
  scope.querySelectorAll('.tab-panel').forEach(function(p) { p.classList.remove('active'); });
  event.target.classList.add('active');
  scope.querySelector('#tab-' + name).classList.add('active');
}
```

### 3.12 Step Navigator

For multi-step processes or wizards.

**HTML:**
```html
<div class="steps">
  <div class="step done"><span class="step-num">1</span><span class="step-label">Configure</span></div>
  <div class="step active"><span class="step-num">2</span><span class="step-label">Review</span></div>
  <div class="step"><span class="step-num">3</span><span class="step-label">Execute</span></div>
</div>
```

**CSS:**
```css
.steps {
  display: flex; gap: 2px; margin-bottom: 20px;
}
.step {
  flex: 1; padding: 10px 14px; background: var(--surface2);
  border-radius: 8px; text-align: center; position: relative;
}
.step-num {
  display: block; font-size: 18px; font-weight: 700;
  color: var(--text3); margin-bottom: 2px;
}
.step-label { font-size: 11px; color: var(--text3); text-transform: uppercase; letter-spacing: .04em; }
.step.done { background: var(--done-bg); }
.step.done .step-num { color: var(--done-col); }
.step.done .step-label { color: var(--done-col); }
.step.active { background: var(--act-bg); border: 1px solid var(--act-col); }
.step.active .step-num { color: var(--act-col); }
.step.active .step-label { color: var(--act-col); }
```

### 3.13 Interactive Calculators

Use for: economics models, cost comparisons, scenario analysis, sizing tools.

**Structure:** Input controls (sliders, dropdowns, radio buttons) feed a single `update()` function that recomputes and renders results.

**HTML pattern:**
```html
<div class="calc-controls">
  <div class="calc-row">
    <label class="calc-label">Volume (units/month)</label>
    <input type="range" id="calc-volume" min="100" max="10000" value="1000" step="100">
    <span class="calc-value" id="val-volume">1,000</span>
  </div>
  <div class="calc-row">
    <label class="calc-label">Tier</label>
    <select id="calc-tier">
      <option value="basic">Basic</option>
      <option value="pro">Pro</option>
      <option value="enterprise">Enterprise</option>
    </select>
  </div>
</div>

<div class="calc-results" id="calc-results">
  <!-- populated by update() -->
</div>

<button class="calc-reset" onclick="resetCalc()">Reset to defaults</button>
```

**CSS:**
```css
.calc-controls {
  background: var(--surface); border: 1px solid var(--border);
  border-radius: 10px; padding: 16px; margin-bottom: 12px;
}
.calc-row {
  display: flex; align-items: center; gap: 12px;
  margin-bottom: 10px; flex-wrap: wrap;
}
.calc-label {
  font-size: 12px; font-weight: 600; color: var(--text2);
  min-width: 160px;
}
.calc-value {
  font-size: 13px; font-weight: 700; color: var(--accent);
  font-family: 'SF Mono', monospace; min-width: 80px;
}
.calc-results {
  background: var(--surface); border: 1px solid var(--border);
  border-radius: 10px; padding: 16px; margin-bottom: 12px;
}
.calc-reset {
  padding: 6px 14px; font-size: 12px; font-weight: 600;
  color: var(--text3); background: var(--surface2);
  border: 1px solid var(--border); border-radius: 6px; cursor: pointer;
}
.calc-cost { color: var(--fail-col); font-weight: 700; }
.calc-revenue { color: var(--done-col); font-weight: 700; }
.calc-unknown { color: var(--text3); font-style: italic; }

input[type="range"] {
  flex: 1; max-width: 300px; accent-color: var(--accent);
}
select {
  font-size: 12px; padding: 4px 8px; border-radius: 6px;
  border: 1px solid var(--border); background: var(--surface2);
  color: var(--text);
}
```

**JS pattern:**
```js
var DEFAULTS = { volume: 1000, tier: 'basic' };

function update() {
  var volume = Number(document.getElementById('calc-volume').value);
  var tier = document.getElementById('calc-tier').value;

  // Update displayed slider value
  document.getElementById('val-volume').textContent = volume.toLocaleString();

  // Compute results
  var unitCost = { basic: 0.10, pro: 0.07, enterprise: 0.04 }[tier];
  var totalCost = volume * unitCost;

  // Render results
  document.getElementById('calc-results').innerHTML =
    '<div class="dgrid">' +
    '<div class="dkv"><div class="k">Unit Cost</div><div class="v calc-cost">$' + unitCost.toFixed(2) + '</div></div>' +
    '<div class="dkv"><div class="k">Monthly Cost</div><div class="v calc-cost">$' + totalCost.toLocaleString() + '</div></div>' +
    '</div>';
}

function resetCalc() {
  document.getElementById('calc-volume').value = DEFAULTS.volume;
  document.getElementById('calc-tier').value = DEFAULTS.tier;
  update();
}

// Bind all controls
document.getElementById('calc-volume').addEventListener('input', update);
document.getElementById('calc-tier').addEventListener('input', update);
update(); // initial render
```

**Design rules for calculators:**
- ~100-150 lines of vanilla JS. No framework, no charting library.
- One `update()` function recomputes everything. Each control calls it via `addEventListener('input', update)`.
- Slider labels get emojis for visual scanning when there are 3+ sliders.
- Color-code outputs: `calc-cost` (red) for expenses, `calc-revenue` (green) for gains.
- Use `calc-unknown` (greyed italic) for values that depend on unknown data.
- Collapsible `<details>` for calculation breakdowns so the default view stays clean.

### 3.14 CSS Tooltips

Pure CSS tooltips using `data-tip` attributes. No native `title` attribute (too slow, unstyled).

**HTML:**
```html
<span class="has-tip" data-tip="Explanation of this term.">Term <span class="tip-icon">(?)</span></span>
```

**CSS:**
```css
.has-tip {
  position: relative; cursor: help;
  border-bottom: 1px dotted var(--text3);
}
.tip-icon {
  font-size: 10px; font-weight: 700; color: var(--text3);
  vertical-align: super;
}
.has-tip::after {
  content: attr(data-tip);
  position: absolute; bottom: 100%; left: 50%;
  transform: translateX(-50%); padding: 6px 10px;
  background: var(--surface3); border: 1px solid var(--border2);
  border-radius: 6px; font-size: 11px; color: var(--text);
  white-space: normal; width: max-content; max-width: 280px;
  line-height: 1.4; pointer-events: none;
  opacity: 0; transition: opacity .15s;
  z-index: 50;
}
.has-tip:hover::after { opacity: 1; }
```

**Vocab tooltip invariant:** Tooltip definitions must not contain nested tooltip markup. Terms that appear inside another term's definition render as plain text. Enforce via two-pass processing: (1) tokenize all term matches with placeholders, (2) restore placeholders as final `<span>` markup. Definitions are assembled separately and never re-wrapped.

### 3.15 Option Cards (Composable Card Pattern)

For comparing options, configurations, or alternatives in a consistent visual shape.

**Structure:** Each card follows the same shape: header, info box, optional SVG/diagram, dimension grid. All cards are collapsed by default. The recommended card is fully expanded; other cards reference it with a muted note ("see recommended card for full breakdown").

**HTML:**
```html
<details class="option-card recommended" open>
  <summary class="option-header">
    <span class="option-name">Option Alpha</span>
    <span class="badge bd">Recommended</span>
  </summary>
  <div class="option-body">
    <div class="option-info">Key differentiator or summary statement.</div>
    <!-- optional: inline SVG diagram -->
    <div class="dgrid">
      <div class="dkv"><div class="k">Dimension A</div><div class="v">Value</div></div>
      <div class="dkv"><div class="k">Dimension B</div><div class="v">Value</div></div>
    </div>
  </div>
</details>

<details class="option-card">
  <summary class="option-header">
    <span class="option-name">Option Beta</span>
    <span class="badge bp">Alternative</span>
  </summary>
  <div class="option-body">
    <div class="option-info">How this differs from the recommended option.</div>
    <p class="option-sparse">See Option Alpha for full dimension breakdown.</p>
  </div>
</details>
```

**CSS:**
```css
.option-card {
  background: var(--surface); border: 1px solid var(--border);
  border-radius: 10px; margin-bottom: 10px;
}
.option-card.recommended { border-color: var(--accent); }
.option-header {
  padding: 12px 16px; font-size: 13px; font-weight: 700;
  color: var(--text); cursor: pointer; list-style: none;
  display: flex; align-items: center; gap: 10px;
}
.option-header::-webkit-details-marker { display: none; }
.option-name { flex: 1; }
.option-body { padding: 0 16px 14px; }
.option-info {
  font-size: 13px; color: var(--text2); line-height: 1.6;
  padding: 10px 14px; background: var(--surface2);
  border-radius: 8px; margin-bottom: 12px;
}
.option-sparse { font-size: 12px; color: var(--text3); font-style: italic; }
```

### 3.16 Decision Analysis

Structured option comparison for architectural decisions. The analysis IS the decision work.

**Structure:** Numbered question header, named options (encode the structural difference in the name, not "Option A/B"), multi-lens table, context callout, recommended lean callout.

**Standard analysis dimensions** (use all that apply):

| Dimension | What it tests |
|-----------|--------------|
| Security | Data/credential leakage, attack vectors |
| System Design | Structural fit with existing architecture |
| Conventions | Conformance with project conventions |
| Right Layer | Responsibility assigned to correct component? |
| Throughput/Ops | Performance at expected load, operational overhead |
| Maintenance | Long-term cost, breakage when requirements change |

**CSS for the recommendation callout:**
```css
.decision-lean {
  border-left: 3px solid var(--accent);
  background: var(--surface2);
  padding: 10px 14px; border-radius: 0 6px 6px 0;
  margin-top: 10px; font-size: .82rem;
}
```

A decision analysis that concludes "it depends" has failed. Either a dimension was omitted, or the callout must name exactly what information is missing and who provides it.

### 3.17 Audit Timeline

```css
.tl { display: flex; flex-direction: column; gap: 4px; }
.tli { display: flex; gap: 8px; font-size: .75rem; align-items: flex-start; }
.tlts {
  color: var(--text3); white-space: nowrap; min-width: 115px;
  font-size: .68rem; padding-top: 1px;
}
```

Color convention per symbol: `✓` green (success), `✗` red (failure), `→` / `○` / `·` neutral.

### 3.18 Filter Bar (Dashboard-class)

```css
.filter-bar {
  display: flex; align-items: center; gap: 12px; flex-wrap: wrap;
  margin-bottom: 10px; padding: 8px 10px;
  background: var(--surface2); border-radius: 8px; font-size: .8rem;
}
.filter-bar select {
  font-size: .78rem; padding: 2px 6px; border-radius: 5px;
  border: 1px solid var(--border); background: var(--surface); color: var(--text);
}
```

**JS:**
```js
function applyFilters() {
  var statusVal = document.getElementById('status-filter').value;
  var flaggedOnly = document.getElementById('flagged-only').checked;
  document.querySelectorAll('#data-table tbody tr').forEach(function(row) {
    var status = row.dataset.status || '';
    var flagged = row.dataset.flagged === 'true';
    var show = true;
    if (statusVal && status !== statusVal) show = false;
    if (flaggedOnly && !flagged) show = false;
    row.style.display = show ? '' : 'none';
  });
}
```

### 3.19 Action Buttons (Dashboard-class)

```css
.act-btn {
  display: inline-block; padding: 2px 7px; border-radius: 6px;
  font-size: .7rem; font-weight: 600; text-decoration: none;
  color: var(--accent); border: 1px solid var(--accent);
  margin-right: 3px; white-space: nowrap;
}
.act-btn:hover { background: var(--act-bg); }
.act-esc { color: var(--pend-col); border-color: var(--pend-col); }
.act-esc:hover { background: var(--pend-bg); }
```

### 3.20 Empty States

```css
.empty {
  text-align: center; padding: 24px 20px;
  color: var(--text3); font-size: .85rem;
}
```

### 3.21 JS Helper Functions

Include in every artifact:

```js
function fmt(n) {
  return n == null ? '—' : Number(n).toLocaleString();
}

function fmtDate(s) {
  if (!s) return '—';
  try { return new Date(s).toISOString().slice(0, 16).replace('T', ' ') + ' UTC'; }
  catch (e) { return s.slice(0, 16); }
}

function fmtDuration(secs) {
  if (secs == null || secs < 0) return '—';
  if (secs < 60) return secs + 's';
  if (secs < 3600) return Math.floor(secs / 60) + 'm ' + (secs % 60) + 's';
  var h = Math.floor(secs / 3600);
  var m = Math.floor((secs % 3600) / 60);
  return h + 'h ' + m + 'm';
}
```

---

### 3.22 Coverage/Capability Matrix

A requirements-by-provider matrix with check/cross/pending marks and a gap-risk column. Used to evaluate providers against a structured set of requirements (jurisdictions, features, compliance items, coverage timelines). A summary row of color-coded callout boxes quantifies uncovered items across all providers.

**When to use:** Comparing providers against jurisdictions, features, compliance requirements, or coverage timelines where gap visibility drives the decision.

**CSS:**
```css
.cov-matrix { width: 100%; border-collapse: collapse; font-size: .8rem; }
.cov-matrix th {
  text-align: left; padding: 6px 8px; color: var(--text3);
  font-size: .68rem; font-weight: 600; text-transform: uppercase;
  letter-spacing: .04em; border-bottom: 1px solid var(--border);
}
.cov-matrix td {
  padding: 6px 8px; border-bottom: 1px solid var(--border);
  vertical-align: top; text-align: center;
}
.cov-matrix td:first-child { text-align: left; font-weight: 500; }
.cov-matrix td:last-child { text-align: left; }
.cov-matrix tr:last-child td { border-bottom: none; }

.cov-yes { color: #34d399; }
.cov-no { color: #f87171; }
.cov-pending { color: #fbbf24; }

.cov-risk-high {
  color: #f87171; font-weight: 600; font-size: .75rem;
}
.cov-risk-low {
  color: var(--text3); font-size: .75rem;
}
.cov-risk-med {
  color: #fbbf24; font-weight: 600; font-size: .75rem;
}

.cov-summary {
  display: flex; gap: 10px; margin-top: 14px; flex-wrap: wrap;
}
.cov-callout {
  flex: 1; min-width: 140px; padding: 10px 14px;
  border-radius: 8px; font-size: .78rem; font-weight: 600;
}
.cov-callout .cov-callout-n {
  font-size: 1.3rem; font-weight: 700; display: block; margin-bottom: 2px;
}
.cov-callout .cov-callout-l {
  font-size: .65rem; text-transform: uppercase; letter-spacing: .04em;
  font-weight: 600;
}
.cov-callout-full {
  background: rgba(52, 211, 153, .1); color: #34d399;
  border: 1px solid rgba(52, 211, 153, .25);
}
.cov-callout-gap {
  background: rgba(248, 113, 113, .1); color: #f87171;
  border: 1px solid rgba(248, 113, 113, .25);
}
.cov-callout-cond {
  background: rgba(251, 191, 36, .1); color: #fbbf24;
  border: 1px solid rgba(251, 191, 36, .25);
}
```

**HTML:**
```html
<table class="cov-matrix">
  <thead>
    <tr>
      <th>Requirement</th>
      <th>Provider A</th>
      <th>Provider B</th>
      <th>Provider C</th>
      <th>Gap Risk</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>US ACH</td>
      <td class="cov-yes">&#10003;</td>
      <td class="cov-yes">&#10003;</td>
      <td class="cov-no">&#10007;</td>
      <td class="cov-risk-low">Covered by A+B</td>
    </tr>
    <tr>
      <td>EU SEPA</td>
      <td class="cov-no">&#10007;</td>
      <td class="cov-pending">&#9207;</td>
      <td class="cov-yes">&#10003;</td>
      <td class="cov-risk-med">B timeline unconfirmed</td>
    </tr>
    <tr>
      <td>SOC 2 Type II</td>
      <td class="cov-yes">&#10003;</td>
      <td class="cov-no">&#10007;</td>
      <td class="cov-no">&#10007;</td>
      <td class="cov-risk-high">Single-provider dependency</td>
    </tr>
  </tbody>
</table>

<div class="cov-summary">
  <div class="cov-callout cov-callout-full">
    <span class="cov-callout-n">5</span>
    <span class="cov-callout-l">Fully Covered</span>
  </div>
  <div class="cov-callout cov-callout-gap">
    <span class="cov-callout-n">2</span>
    <span class="cov-callout-l">Uncovered Gaps</span>
  </div>
  <div class="cov-callout cov-callout-cond">
    <span class="cov-callout-n">1</span>
    <span class="cov-callout-l">Conditional</span>
  </div>
</div>
```

---

### 3.23 Question/Decision Registry

Prioritized list of open items grouped by urgency tier. Each tier has a count badge and a colored header. Rows carry a left-border color indicating resolution state: red for open, yellow for partial/in-progress, green for resolved. Tracks questions across sessions in a living decision document.

**When to use:** Tracking open questions, blocking decisions, and follow-ups across sessions in a decision or analysis document.

**CSS:**
```css
.qreg-tier {
  margin-bottom: 20px;
}
.qreg-tier-header {
  display: flex; align-items: center; gap: 8px;
  font-size: 12px; font-weight: 700; text-transform: uppercase;
  letter-spacing: .08em; margin-bottom: 10px;
  padding-bottom: 6px; border-bottom: 1px solid var(--border);
}
.qreg-tier-badge {
  display: inline-block; padding: 2px 8px; border-radius: 10px;
  font-size: 10px; font-weight: 700; color: #fff;
}
.qreg-tier-urgent .qreg-tier-badge { background: #ef4444; }
.qreg-tier-urgent .qreg-tier-label { color: #ef4444; }
.qreg-tier-follow .qreg-tier-badge { background: #eab308; }
.qreg-tier-follow .qreg-tier-label { color: #eab308; }
.qreg-tier-nice .qreg-tier-badge { background: var(--text3); }
.qreg-tier-nice .qreg-tier-label { color: var(--text3); }

.qreg-table { width: 100%; border-collapse: collapse; font-size: .8rem; }
.qreg-table th {
  text-align: left; padding: 5px 8px; color: var(--text3);
  font-size: .68rem; font-weight: 600; text-transform: uppercase;
  letter-spacing: .04em; border-bottom: 1px solid var(--border);
}
.qreg-table td {
  padding: 6px 8px; border-bottom: 1px solid var(--border); vertical-align: top;
}
.qreg-table tr:last-child td { border-bottom: none; }

.qreg-table tr { border-left: 3px solid transparent; }
.qreg-open { border-left-color: #ef4444; }
.qreg-partial { border-left-color: #eab308; }
.qreg-resolved { border-left-color: #34d399; }

.qreg-num {
  font-family: 'SF Mono', 'Fira Code', monospace;
  font-size: .72rem; color: var(--text3); font-weight: 600;
}
```

**HTML:**
```html
<div class="qreg-tier qreg-tier-urgent">
  <div class="qreg-tier-header">
    <span class="qreg-tier-label">Urgent / Blocking</span>
    <span class="qreg-tier-badge">3</span>
  </div>
  <table class="qreg-table">
    <thead>
      <tr><th>#</th><th>Question</th><th>Scope</th><th>Blocks</th><th>Status</th><th>Owner</th></tr>
    </thead>
    <tbody>
      <tr class="qreg-open">
        <td class="qreg-num">Q1</td>
        <td>What is the settlement cutoff time?</td>
        <td>Operations</td>
        <td>Payment flow design</td>
        <td><span class="badge bf">Open</span></td>
        <td>Treasury</td>
      </tr>
      <tr class="qreg-partial">
        <td class="qreg-num">Q2</td>
        <td>Multi-currency account structure?</td>
        <td>Architecture</td>
        <td>Data model</td>
        <td><span class="badge bp">Partial</span></td>
        <td>Engineering</td>
      </tr>
    </tbody>
  </table>
</div>

<div class="qreg-tier qreg-tier-follow">
  <div class="qreg-tier-header">
    <span class="qreg-tier-label">Fast Follow</span>
    <span class="qreg-tier-badge">2</span>
  </div>
  <table class="qreg-table">
    <thead>
      <tr><th>#</th><th>Question</th><th>Scope</th><th>Blocks</th><th>Status</th><th>Owner</th></tr>
    </thead>
    <tbody>
      <tr class="qreg-resolved">
        <td class="qreg-num">Q4</td>
        <td>Webhook retry policy?</td>
        <td>Integration</td>
        <td>Error handling</td>
        <td><span class="badge bd">Resolved</span></td>
        <td>Platform</td>
      </tr>
    </tbody>
  </table>
</div>

<div class="qreg-tier qreg-tier-nice">
  <div class="qreg-tier-header">
    <span class="qreg-tier-label">Nice to Have</span>
    <span class="qreg-tier-badge">1</span>
  </div>
  <table class="qreg-table">
    <thead>
      <tr><th>#</th><th>Question</th><th>Scope</th><th>Blocks</th><th>Status</th><th>Owner</th></tr>
    </thead>
    <tbody>
      <tr class="qreg-open">
        <td class="qreg-num">Q6</td>
        <td>Custom branding on hosted pages?</td>
        <td>UX</td>
        <td>Nothing</td>
        <td><span class="badge bf">Open</span></td>
        <td>Design</td>
      </tr>
    </tbody>
  </table>
</div>
```

---

### 3.24 Split-Panel Comparison

Side-by-side panels for comparing two states, providers, or journeys. Each panel has a header with an optional badge and a content area. Optional comparison annotation tags (see 3.28) classify individual elements. Optional system annotations appear in muted text. Grid layout ensures equal width at all viewport sizes.

**When to use:** Before/after UX flows, Provider A vs Provider B experience comparisons, current-state vs future-state.

**CSS:**
```css
.split-panel {
  display: grid; grid-template-columns: 1fr 1fr; gap: 14px;
  margin-bottom: 14px;
}
@media (max-width: 640px) {
  .split-panel { grid-template-columns: 1fr; }
}

.split-pane {
  background: var(--surface); border: 1px solid var(--border);
  border-radius: 10px; overflow: hidden;
}
.split-pane-header {
  display: flex; align-items: center; gap: 8px;
  padding: 10px 16px; font-size: 13px; font-weight: 700;
  color: var(--text); border-bottom: 1px solid var(--border);
  background: var(--surface2);
}
.split-pane-header .badge { flex-shrink: 0; }
.split-pane-body {
  padding: 14px 16px; font-size: .82rem; color: var(--text);
  line-height: 1.6;
}
.split-pane-body ol,
.split-pane-body ul {
  padding-left: 18px; margin: 0;
}
.split-pane-body li { margin-bottom: 6px; }

.split-annotation {
  font-size: 11px; color: var(--text3); font-style: italic;
  margin-top: 6px;
}
```

**HTML:**
```html
<div class="split-panel">
  <div class="split-pane">
    <div class="split-pane-header">
      Current Flow <span class="badge bp">Before</span>
    </div>
    <div class="split-pane-body">
      <ol>
        <li>User enters amount <span class="cmp-tag cmp-same">SAME</span></li>
        <li>Redirect to bank portal <span class="cmp-tag cmp-regression">REGRESSION</span></li>
        <li>Manual confirmation email</li>
      </ol>
      <div class="split-annotation">Source: production audit 2025-12</div>
    </div>
  </div>
  <div class="split-pane">
    <div class="split-pane-header">
      Proposed Flow <span class="badge bd">After</span>
    </div>
    <div class="split-pane-body">
      <ol>
        <li>User enters amount <span class="cmp-tag cmp-same">SAME</span></li>
        <li>Inline bank auth <span class="cmp-tag cmp-better">BETTER</span></li>
        <li>Real-time webhook confirmation <span class="cmp-tag cmp-new">NEW</span></li>
      </ol>
      <div class="split-annotation">Based on Provider B sandbox testing</div>
    </div>
  </div>
</div>
```

---

### 3.25 Convergence Confidence Display

Displays working direction, supporting evidence, confidence percentage, and "what could change" for decisions that are converging but not yet final. Confidence is color-coded: green above 80%, yellow 60-80%, red below 60%. A left-border accent reinforces the confidence level. A separate "Confirmed" section below shows fully resolved items.

**When to use:** Living decision documents where decisions converge over sessions and readers need to see how firm each direction is.

**CSS:**
```css
.conv-table { width: 100%; border-collapse: collapse; font-size: .8rem; }
.conv-table th {
  text-align: left; padding: 6px 8px; color: var(--text3);
  font-size: .68rem; font-weight: 600; text-transform: uppercase;
  letter-spacing: .04em; border-bottom: 1px solid var(--border);
}
.conv-table td {
  padding: 8px 8px; border-bottom: 1px solid var(--border); vertical-align: top;
}
.conv-table tr:last-child td { border-bottom: none; }

.conv-table tr { border-left: 3px solid transparent; }
.conv-high { border-left-color: #34d399; }
.conv-med { border-left-color: #eab308; }
.conv-low { border-left-color: #ef4444; }

.conv-pct {
  font-family: 'SF Mono', 'Fira Code', monospace;
  font-weight: 700; font-size: .82rem;
}
.conv-pct-high { color: #34d399; }
.conv-pct-med { color: #eab308; }
.conv-pct-low { color: #ef4444; }

.conv-evidence {
  font-size: .75rem; color: var(--text2); line-height: 1.5;
}
.conv-change {
  font-size: .75rem; color: var(--text3); font-style: italic;
}

.conv-confirmed {
  margin-top: 16px; padding: 12px 16px;
  background: rgba(52, 211, 153, .06);
  border: 1px solid rgba(52, 211, 153, .2);
  border-radius: 8px;
}
.conv-confirmed-header {
  font-size: 11px; font-weight: 700; text-transform: uppercase;
  letter-spacing: .08em; color: #34d399; margin-bottom: 8px;
}
.conv-confirmed-item {
  display: flex; align-items: baseline; gap: 8px;
  font-size: .8rem; margin-bottom: 4px;
}
.conv-confirmed-item .conv-check { color: #34d399; font-weight: 700; }
```

**HTML:**
```html
<table class="conv-table">
  <thead>
    <tr>
      <th>Direction</th>
      <th>Evidence</th>
      <th>Confidence</th>
      <th>What Could Change</th>
    </tr>
  </thead>
  <tbody>
    <tr class="conv-high">
      <td><strong>Use Provider B for EU payments</strong></td>
      <td class="conv-evidence">Sandbox tested; pricing confirmed in writing; SOC 2 cert reviewed</td>
      <td><span class="conv-pct conv-pct-high">90%</span></td>
      <td class="conv-change">Contract negotiation could surface volume minimums</td>
    </tr>
    <tr class="conv-med">
      <td><strong>Single ledger, multi-currency</strong></td>
      <td class="conv-evidence">Eng prototype works; accounting team verbal approval</td>
      <td><span class="conv-pct conv-pct-med">70%</span></td>
      <td class="conv-change">Regulatory review of sub-account structure</td>
    </tr>
    <tr class="conv-low">
      <td><strong>Real-time FX conversion</strong></td>
      <td class="conv-evidence">Provider claims API exists; no documentation found</td>
      <td><span class="conv-pct conv-pct-low">40%</span></td>
      <td class="conv-change">May need batch FX if API is not production-ready</td>
    </tr>
  </tbody>
</table>

<div class="conv-confirmed">
  <div class="conv-confirmed-header">Confirmed Decisions</div>
  <div class="conv-confirmed-item">
    <span class="conv-check">&#10003;</span>
    <span>USD as base currency for all ledger entries</span>
  </div>
  <div class="conv-confirmed-item">
    <span class="conv-check">&#10003;</span>
    <span>Webhook-first integration pattern (no polling)</span>
  </div>
</div>
```

---

### 3.26 Data Provenance Badges

Confidence markers for vendor and external claims. Orthogonal to task-status badges (3.5) -- these classify the provenance of a claim, not the status of a work item. Five tiers from highest to lowest confidence.

**When to use:** Marking pricing, capability, and timeline claims in comparison tables and decision documents where the reliability of vendor-provided information matters.

**Tiers:**

| Class | Symbol | Meaning |
|-------|--------|---------|
| `.prov-confirmed` | &#10003; | Confirmed in writing (contract, docs, email) |
| `.prov-verbal` | &#9684; | Claimed verbally, not in writing |
| `.prov-pre-ga` | &#9888;&#65039; | Documented but pre-GA / not production |
| `.prov-coming` | &#9203; | Mentioned as coming, not documented |
| `.prov-absent` | &#10060; | Not mentioned by vendor |

**CSS:**
```css
.prov {
  display: inline-block; padding: 2px 7px; border-radius: 10px;
  font-size: .68rem; font-weight: 600; white-space: nowrap;
  vertical-align: middle;
}
.prov-confirmed {
  color: #34d399; background: rgba(52, 211, 153, .12);
  border: 1px solid rgba(52, 211, 153, .25);
}
.prov-verbal {
  color: #60a5fa; background: rgba(96, 165, 250, .12);
  border: 1px solid rgba(96, 165, 250, .25);
}
.prov-pre-ga {
  color: #fbbf24; background: rgba(251, 191, 36, .12);
  border: 1px solid rgba(251, 191, 36, .25);
}
.prov-coming {
  color: #a78bfa; background: rgba(167, 139, 250, .12);
  border: 1px solid rgba(167, 139, 250, .25);
}
.prov-absent {
  color: #f87171; background: rgba(248, 113, 113, .12);
  border: 1px solid rgba(248, 113, 113, .25);
}
```

**HTML usage:**
```html
<!-- Inline in table cells or prose -->
<span class="prov prov-confirmed">&#10003; Confirmed</span>
<span class="prov prov-verbal">&#9684; Verbal</span>
<span class="prov prov-pre-ga">&#9888;&#65039; Pre-GA</span>
<span class="prov prov-coming">&#9203; Coming Soon</span>
<span class="prov prov-absent">&#10060; Absent</span>

<!-- Example: inside a coverage matrix cell -->
<td><span class="prov prov-verbal">&#9684; Verbal</span></td>

<!-- Example: inline in prose -->
<p>Real-time FX is <span class="prov prov-coming">&#9203; Coming Soon</span> per the Provider B sales call (2025-11-14). No API documentation exists.</p>
```

**Usage guidance:** Provenance badges can be composed with coverage marks (3.22) and comparison tags (3.28). In a coverage matrix, replace bare checkmarks with provenance badges when the reliability of the claim is decision-relevant. In prose, use inline to qualify specific vendor assertions. Do not use for internal team decisions -- those are task-status badges (3.5).

---

### 3.27 JSON Code Block

Syntax-highlighted code display for API payloads, webhook examples, and configuration snippets. Dark background with color classes for structural elements. Monospace font, horizontal scroll for long lines.

**When to use:** System panels, API documentation sections, webhook payload examples, configuration display in technical decision documents.

**CSS:**
```css
.json-block {
  background: #0d1117; border: 1px solid #30363d;
  border-radius: 8px; padding: 14px 16px; margin-bottom: 12px;
  overflow-x: auto; font-family: 'SF Mono', 'Fira Code', 'Consolas', monospace;
  font-size: .78rem; line-height: 1.6; color: #c9d1d9;
  tab-size: 2;
}
.json-block .jk { color: #7ee787; }           /* keys */
.json-block .js { color: #79c0ff; }           /* string values */
.json-block .jn { color: #56d4dd; }           /* numbers */
.json-block .jb { color: #ff7b72; }           /* booleans, null */
.json-block .jc { color: #8b949e; font-style: italic; } /* comments */
.json-block .jp { color: #c9d1d9; }           /* punctuation: {} [] , : */

.json-block-label {
  font-size: .65rem; font-weight: 600; text-transform: uppercase;
  letter-spacing: .06em; color: var(--text3); margin-bottom: 6px;
}
```

**HTML:**
```html
<div class="json-block-label">Webhook Payload</div>
<pre class="json-block"><code><span class="jp">{</span>
  <span class="jk">"event"</span><span class="jp">:</span> <span class="js">"payment.completed"</span><span class="jp">,</span>
  <span class="jk">"amount"</span><span class="jp">:</span> <span class="jn">15000</span><span class="jp">,</span>
  <span class="jk">"currency"</span><span class="jp">:</span> <span class="js">"USD"</span><span class="jp">,</span>
  <span class="jk">"idempotency_key"</span><span class="jp">:</span> <span class="js">"ik_abc123"</span><span class="jp">,</span>
  <span class="jk">"metadata"</span><span class="jp">:</span> <span class="jp">{</span>
    <span class="jk">"source"</span><span class="jp">:</span> <span class="js">"api"</span><span class="jp">,</span>
    <span class="jk">"retry_count"</span><span class="jp">:</span> <span class="jn">0</span><span class="jp">,</span>
    <span class="jk">"is_test"</span><span class="jp">:</span> <span class="jb">false</span>
  <span class="jp">}</span>
<span class="jp">}</span></code></pre>
```

**JS (optional -- auto-highlight from raw JSON):**
```js
function highlightJson(elementId) {
  var el = document.getElementById(elementId);
  if (!el) return;
  var raw = el.textContent;
  var highlighted = raw
    .replace(/("(?:[^"\\]|\\.)*")\s*:/g, '<span class="jk">$1</span><span class="jp">:</span>')
    .replace(/:\s*("(?:[^"\\]|\\.)*")/g, ': <span class="js">$1</span>')
    .replace(/:\s*(\d+\.?\d*)/g, ': <span class="jn">$1</span>')
    .replace(/:\s*(true|false|null)/g, ': <span class="jb">$1</span>')
    .replace(/([{}\[\],])/g, '<span class="jp">$1</span>')
    .replace(/\/\/(.*?)$/gm, '<span class="jc">//$1</span>');
  el.innerHTML = highlighted;
}
```

**Usage note:** For static documents, prefer hand-marked spans (the HTML example above) for precision. Use the JS auto-highlighter only when rendering dynamic or user-provided JSON where manual markup is impractical.

---

### 3.28 Comparison Annotation Tags

Inline pill-style badges for classifying elements in a comparison. Small, unobtrusive, and designed to sit inline with text or list items. Four classifications: NEW, SAME, BETTER, REGRESSION.

**When to use:** Any before/after or option-A vs option-B comparison where individual elements need classification. Compose with Split-Panel Comparison (3.24), tables (3.7), or inline prose.

**CSS:**
```css
.cmp-tag {
  display: inline-block; padding: 2px 6px; border-radius: 4px;
  font-size: 10px; font-weight: 700; letter-spacing: .02em;
  vertical-align: middle; white-space: nowrap; margin-left: 4px;
}
.cmp-new {
  color: #1e40af; background: #dbeafe;
}
.cmp-same {
  color: #6b7280; background: #f3f4f6;
}
.cmp-better {
  color: #065f46; background: #d1fae5;
}
.cmp-regression {
  color: #92400e; background: #fef3c7;
}
```

**HTML usage:**
```html
<!-- Inline in a list -->
<li>Webhook confirmation <span class="cmp-tag cmp-new">NEW</span></li>
<li>Amount entry <span class="cmp-tag cmp-same">SAME</span></li>
<li>Auth latency 200ms (was 800ms) <span class="cmp-tag cmp-better">BETTER</span></li>
<li>No fallback routing <span class="cmp-tag cmp-regression">REGRESSION</span></li>

<!-- Inline in a table cell -->
<td>Real-time settlement <span class="cmp-tag cmp-new">NEW</span></td>

<!-- Inline in prose -->
<p>The proposed flow introduces inline bank auth <span class="cmp-tag cmp-better">BETTER</span> but removes the manual override path <span class="cmp-tag cmp-regression">REGRESSION</span>.</p>
```

**Light mode note:** The background colors are chosen to work in both dark and light themes. In dark mode, the text colors provide sufficient contrast against the light backgrounds. No `[data-theme]` overrides needed.


## 4. Data Injection

### 4.1 The D_JSON Pattern

The generator serializes all page data to a single JSON blob injected as a JS constant. The page is fully self-contained -- no AJAX, no backend.

**Python generation side:**
```python
payload = {
    "items": items_data,
    "audit_trail": audit_trail,
    "generated_at": datetime.now(timezone.utc).isoformat(),
}
d_json = json.dumps(payload, ensure_ascii=False, separators=(",", ":"), default=str)
html = template.format(D_JSON=d_json)
```

**HTML template side:**
```html
<script>
var D = {D_JSON};
</script>
```

**JS rendering side:**
```js
var items = D.items;
// All render functions are pure: data in, HTML string out, assign to innerHTML
```

When the HTML template contains `{` or `}` (CSS, JS), double them: `{{` and `}}`.

### 4.2 Generator Script Conventions

| Function | Purpose |
|----------|---------|
| `generate_html(data, ...)` | Pure: data in, HTML string out. No I/O. |
| `generate_and_deliver(id, ...)` | Fetch data, call `generate_html`, write file, return URL/path. |
| `main(argv?)` | CLI entrypoint. Parse args, call `generate_and_deliver`, print result. |
| `_fetch_*(conn, id)` | Data helpers. Open connection in, plain dict/list out. |
| `_compute_*(...)` | Pure computation (elapsed time, cost estimates). |
| `_fmt_*(...)` | Formatting (durations, numbers). |

Keep `generate_html` pure. Delivery is separate. Resolve base URLs from configuration (env var or config file), never hardcode. Generate unique filenames (e.g., UUID) per artifact.

---

## 5. SVG Conventions

### 5.1 Flow Diagrams

Hand-crafted inline SVG. No external libraries.

**Role-based color system** (generalized for any domain):

| Role | Fill | Stroke | Title Text | Label Text |
|------|------|--------|-----------|------------|
| Primary | `#EEF2FF` | `#6366F1` | `#312E81` | `#6366F1` |
| Secondary | `#F5F3FF` | `#8B5CF6` | `#4C1D95` | `#7C3AED` |
| Highlight | `#FEF3C7` | `#F59E0B` | `#78350F` | `#B45309` |
| Muted | `#F0FDF4` | `#16A34A` | `#14532D` | `#16A34A` |

Use these roles semantically. Primary for the main flow, Secondary for controlled/owned components, Highlight for conversion boundaries or decision points, Muted for external or background systems.

**Box specs:**
- Width: 120-160px
- Height: ~70px
- Corner radius: `rx="10"`
- Stroke width: `1.5`
- Two text lines: title (12.5px, weight 600) + subtitle (10px)

**Arrow marker definition:**
```html
<defs>
  <marker id="arrow-flow" markerWidth="8" markerHeight="6" refX="8" refY="3"
          orient="auto" markerUnits="strokeWidth">
    <path d="M0,0 L8,3 L0,6" fill="#6366F1"/>
  </marker>
</defs>
```

**Arrows:**
- Solid lines with `marker-end="url(#arrow-flow)"` for normal flow.
- Dashed lines (`stroke-dasharray="6,3"`, `stroke-width="2"`) for conversion or conditional paths.

**viewBox:** Width 920-1120, height ~200. Adjust to content.

**ID collision prevention:** Prefix all marker IDs with a diagram-specific name (e.g., `id="arrow-config-a"`, `id="arrow-config-b"`). SVG marker IDs are document-global. Duplicate IDs across multiple diagrams cause one diagram to steal the other's arrowheads.

**Zone labels:** Place below the diagram as text elements, aligned to the regions they describe.

**Example box:**
```html
<g transform="translate(50, 50)">
  <rect width="140" height="70" rx="10" fill="#EEF2FF" stroke="#6366F1" stroke-width="1.5"/>
  <text x="70" y="30" text-anchor="middle" font-size="12.5" font-weight="600" fill="#312E81">Step Name</text>
  <text x="70" y="48" text-anchor="middle" font-size="10" fill="#6366F1">subtitle detail</text>
</g>
```

### 5.2 Architecture Diagrams

Primitives for system architecture visualization:

| Primitive | Visual | Use |
|-----------|--------|-----|
| Layer band | Full-width rect, low opacity fill | Infrastructure layers (infra, platform, app) |
| Component box | Rect with stroke, label | Individual services or modules |
| Hub/registry | Component box with accent fill | Central coordinators, registries |
| Plugin slot | Dashed stroke box | Extension points, future components |
| Coupling boundary | Dashed line spanning width | Boundary between coupled/decoupled regions |
| Domain cluster | Grouped components with shared background | Components in the same domain |
| Abstract interface | Thin banner above a layer | Interface contracts between layers |
| Registration connector | Upward arrow from component to hub | Components registering with a central system |
| Progressive ghosting | Full opacity / reduced / dashed outline | Concrete / planned / open-slot components |

**Concrete SVG for the 4 most-used primitives:**

**Layer band:**
```svg
<rect x="30" y="Y" width="W" height="H" rx="10" fill="#EEF2FF"/>
<text transform="translate(20, MID) rotate(-90)" font-size="8.5" fill="#9CA3AF"
      text-anchor="middle" letter-spacing="0.1em">LAYER NAME</text>
```

**Component box:**
```svg
<g transform="translate(x, y)">
  <rect width="W" height="H" rx="8" fill="white" stroke="#E5E7EB" stroke-width="1.5"/>
  <text x="12" y="17" font-size="9" fill="#C0C6CE" letter-spacing="0.04em">// Module::Path</text>
  <line x1="12" y1="22" x2="W-12" y2="22" stroke="#F3F4F6" stroke-width="0.5"/>
  <text x="12" y="40" font-size="13" font-weight="700" fill="#1A1A2E">ClassName</text>
  <text x="12" y="57" font-size="10.5" fill="#6B7280">key interface or description</text>
</g>
```

**Plugin slot:**
```svg
<rect width="W" height="H" rx="8" fill="#FAFBFF"
      stroke="#C7D2FE" stroke-width="1.5" stroke-dasharray="6 3"/>
<text x="12" y="36" font-size="11" font-weight="600" fill="#A5B4FC">[SlotName]</text>
<text x="12" y="52" font-size="10" fill="#C7D2FE">future — not yet built</text>
```

**Coupling boundary:**
```svg
<line x1="30" y1="Y" x2="W-30" y2="Y" stroke="#E2E8F0" stroke-width="1.5" stroke-dasharray="8 4"/>
<text x="W/2" y="Y-6" text-anchor="middle" font-size="8.5" fill="#94A3B8" letter-spacing="0.06em">
  COUPLING BOUNDARY — direction annotation here
</text>
```

**Progressive ghosting levels:**

| Level | Border | Fill | Text | Use |
|-------|--------|------|------|-----|
| Concrete | #E5E7EB solid 1.5px | white | #374151 | Built |
| Planned | #C7D2FE dashed 6/3 | #FAFBFF | #A5B4FC | Scoped, not built |
| Open slot | #E2E8F0 dashed 6/3 | #FAFBFF | #CBD5E1 | Unspecified |

### 5.3 Technical Annotation Patterns

**Core principle:** Annotate architecture, not fields. Label the structural relationships, not every data attribute.

**Two-tier zone annotation:**
1. Outer zone brackets (SVG) spanning major regions
2. Inner inline comments (muted text, secondary)

**Right-panel legend:** Place code references and explanations in a panel beside the diagram, not overlaid on it.

```html
<div style="display:flex; gap:24px;">
  <svg viewBox="0 0 600 400" style="flex:1;">
    <!-- diagram content -->
  </svg>
  <div style="flex:0 0 260px; font-size:12px; color:var(--text2);">
    <div><strong>A</strong> &mdash; <code>src/core/registry.ts</code></div>
    <div><strong>B</strong> &mdash; <code>src/plugins/loader.ts</code></div>
  </div>
</div>
```

**Connector lines:** All horizontal or L-shaped elbows. No diagonals. Diagonals are ambiguous about which layer they connect to.

**Color discipline:** Single accent color throughout a diagram. Gray for secondary/annotation elements. Multiple accent colors in one diagram create visual noise without information gain.

### 5.4 Dual-Format Flow Diagrams

For artifacts that exist in both markdown and HTML:
- **Markdown source:** Mermaid syntax (LLM-readable, diffable)
- **HTML render:** Hand-crafted SVG (human-readable, precise layout control)

The Mermaid is the source of truth for the graph structure. The SVG is the presentation layer. When updating a flow diagram, update the Mermaid first, then rebuild the SVG.

---

## 6. Production Methodology

This section covers how to edit large HTML artifacts without destroying them. It is the section nobody else has.

### 6.0 Session Initialization

Before making any edit to a large HTML artifact, establish baselines. Without these, you cannot detect silent corruption.

```bash
# 1. Check version
grep -n 'doc-version\|version.*v[0-9]' file.html | head -3

# 2. Line count baseline
wc -l file.html

# 3. Div balance baseline
grep -c '<div' file.html && grep -c '</div>' file.html

# 4. Structure orientation
grep -n 'top-section\|data-track\|section-num\|id="' file.html | head -20
```

If v8.29 was 3269 lines with 564 divs, and after your edits it's 3200 lines with 550 divs, something was silently dropped. The baselines let you catch this before it compounds.

### 6.1 Editing Workflows by Scale

Large HTML artifacts (1500+ lines) cannot be edited as monolithic files by LLMs. Choose the right workflow for the edit scale:

| Edit type | Scale | Tool | Risk |
|---|---|---|---|
| Content update in identified section | <30 lines changed | Read + Edit tool | Low |
| CSS-only addition | Any size | Edit tool (unique anchor) or Python inject | Low |
| New section with HTML + CSS + JS | 50–500 lines | Python three-point injection | Medium |
| Section restructure (nesting changes) | Any size | Python replacement script | High |
| Full track/tab system addition | 200+ lines | Python injection + JS handler updates | High |

**The key heuristic:** If the edit changes the div nesting depth of a section, it is a rebuild, not a surgical edit. Surgical edits on nesting-depth changes are the #1 source of div-balance corruption.

#### Small edits (<30 lines, nesting unchanged)

1. `grep -n` to find the anchor
2. Read the target region
3. Edit tool with a carefully chosen unique `old_string`
4. Validate
5. Browser preview

#### Medium edits (new subsection or section rewrite)

1. `grep -n` to find boundaries
2. Write the new fragment to `/tmp/fragment.html`
3. Write a Python injection or replacement script
4. Run the script
5. Validate
6. Browser preview

#### Large additions (new track, new tab system, new interactive feature)

1. Write CSS to `/tmp/new-styles.css`
2. Write HTML to `/tmp/new-section.html`
3. Write JS to `/tmp/new-handlers.js`
4. Write a Python script that injects all three at their respective anchor points
5. Run the script
6. Validate
7. Browser preview
8. Version bump

### 6.1.1 Anchor Conventions

Before any edit, the first command is always `grep`:

```bash
grep -n 'id="ts-2"\|section-num\|top-section' file.html | head -20
```

This is not optional — it is the primary method for orienting within a large file.

**Deliberate anchors.** During initial file creation, insert HTML comments at key boundaries:

```html
<!-- ============================= M1a TRACK ============================= -->
<!-- LiqAddr 1: Deposit page — per-chain dropdown -->
<!-- Static 2: Send (same as LiqAddr) -->
```

These comments are the API contract between the initial author and future editors. They are what `grep` finds. Without them, you search for `<div class="slide" data-track="liqaddr" data-step="2">` which is less readable and more fragile.

**Injection-point markers.** For files that will receive repeated additions, mark the injection points explicitly:

```html
<!-- INJECT:new-sections-here -->
<div class="top-section" id="ts-next">
```

### 6.1.2 Section-Based Extract/Replace

The original section-based workflow still applies for edits within existing sections:

**Workflow:**
1. Identify the section to edit (by `id` attribute or `§` number)
2. Extract that section to a mental or physical working copy
3. Make changes in isolation
4. Replace the original section with the edited version
5. Validate the full document

Never edit a large HTML file by rewriting the whole thing. The output will be truncated, corrupted, or silently incomplete.

**Concrete tooling (`tools/html-tool.sh`):**

```bash
export HTML_TOOL_FILE=my-document.html

# Discover structure
./html-tool.sh sections          # list all IDs + line ranges
./html-tool.sh stats             # line counts per section

# Extract → edit → replace cycle
./html-tool.sh extract panel-id > /tmp/section.html
# ... edit /tmp/section.html (small, focused) ...
./html-tool.sh replace panel-id /tmp/section.html

# Inject an SVG into a container
./html-tool.sh inject-svg chart-panel new-flow.svg

# Validate (non-negotiable after every edit)
./html-tool.sh validate

# Preview in browser
./html-tool.sh preview
```

### 6.2 Validation After Every Edit

Non-negotiable. After every structural edit, verify:

| Check | What it catches |
|-------|----------------|
| Div balance | Count opening `<div` vs closing `</div>`. Must match. |
| Depth tracking | No section should nest deeper than expected. Walk the tree. |
| Card structure | Every `.section` has a `.section-header`. Every `.sec` has content. |
| ID uniqueness | `grep` all `id=` attributes. No duplicates. |
| Link targets | Every `href="#..."` has a matching `id`. |

A validation failure after edit means the edit introduced corruption. Revert and redo.

**Browser preview (equally non-negotiable).** Validation catches structural corruption. Browser preview catches *visual* corruption — CSS changes that are structurally valid but visually wrong. A column that's suddenly full-width, a color that's wrong in light mode, a tooltip positioned off-screen. After every structural edit:

```bash
open file.html          # macOS
xdg-open file.html      # Linux
```

Both validation and browser preview are required. Validation without preview misses visual regression. Preview without validation misses structural corruption that renders correctly by accident.

### 6.3 Transform Scripts

For mechanical changes across a large file (CSS injection, class renaming, div wrapping), write a Python or shell transform script. Do not do mechanical changes by hand-editing.

**When to use a transform script:**
- Renaming a CSS class across 50+ occurrences
- Injecting a new CSS block into the `<style>` tag
- Wrapping all instances of a pattern in a new container div
- Migrating from one component pattern to another

**When NOT to use a transform script:**
- Semantic changes (rewriting content, changing data structure)
- Changes to fewer than 5 instances
- Changes that require judgment per instance

**Transform script template:**

```python
#!/usr/bin/env python3
"""Transform: describe what this changes."""
import os, re, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def transform(html):
    # Pattern-based changes here.
    # Print what each step does so failures are traceable.
    return html

def main():
    html = open(sys.argv[1]).read()
    html = transform(html)
    open(sys.argv[2], 'w').write(html)
    print(f"Written to {sys.argv[2]}")

    from validate import validate_html
    issues, stats = validate_html(sys.argv[2])
    print(f"  Divs: {stats['total_opens']}/{stats['total_closes']}, max depth {stats['max_depth']}")
    if issues:
        print(f"  WARNING: {len(issues)} issues")
        for i in issues: print(f"    {i}")

if __name__ == '__main__':
    main()
```

#### Multi-Point Injection (the dominant pattern for large additions)

When adding a new feature (CSS + HTML + JS) to a monolithic HTML file, write a Python script with three surgical insertions. This is how 80% of real production edits happen.

**Template:**

```python
#!/usr/bin/env python3
"""Inject: [describe what this adds]."""
import sys

HTML_PATH = sys.argv[1]

with open(HTML_PATH, 'r') as f:
    html = f.read()

# 1. CSS injection (before @media or before </style>)
CSS_ANCHOR = "@media (max-width: 900px) {"
with open("/tmp/css-fragment.css", 'r') as f:
    css = f.read()
assert CSS_ANCHOR in html, "CSS anchor not found"
html = html.replace(CSS_ANCHOR, css + "\n" + CSS_ANCHOR, 1)
print("CSS injected")

# 2. HTML injection (between known section boundaries)
SECTION_ANCHOR = '<div class="top-section" id="ts-next">'
with open("/tmp/section.html", 'r') as f:
    section = f.read()
assert SECTION_ANCHOR in html, "Section anchor not found"
html = html.replace(SECTION_ANCHOR, section + "\n" + SECTION_ANCHOR, 1)
print("HTML section injected")

# 3. JS injection (before closing </script>)
JS_ANCHOR = "</script>"
with open("/tmp/js-fragment.js", 'r') as f:
    js = f.read()
# Use rfind to target the LAST </script> tag
idx = html.rfind(JS_ANCHOR)
assert idx != -1, "JS anchor not found"
html = html[:idx] + js + "\n" + html[idx:]
print("JS injected")

with open(HTML_PATH, 'w') as f:
    f.write(html)
print("Done.")
```

**Why this is the dominant pattern:**
- The Edit tool's `old_string` matching breaks on HTML entities (`&amp;`, `&#8212;`) and whitespace variation
- html-tool.sh's extract→replace cycle doesn't handle *additions* (no existing section to extract)
- Python scripts are traceable — you can read the script to see exactly what changed
- Each injection point has different failure modes: CSS is safest (additive), HTML is most dangerous (div balance), JS is moderate (syntax errors break the whole page)
- The script should validate after injection, not just at the end

**Naming convention:** `inject-[feature].py`, `rebuild-[section].py`, `add-[component].py`. The script name documents what it does.

### 6.4 Anti-Patterns

These fail reliably. Do not attempt them.

**Full-file rewrite of 1500+ line HTML by a subagent.** The LLM output will be truncated at the output limit. Sections will be silently dropped. The resulting file will be shorter than the original with no indication of what was lost. Use section-based editing instead.

**Edit tool on large HTML with encoded characters.** The Edit tool's string matching breaks on HTML entities (`&amp;`, `&#8212;`), smart quotes, and other encoded characters. The `old_string` in the tool call does not match the file content because the encoding is invisible in the tool's representation. Write a transform script instead, or extract the section, edit it as a standalone fragment, and replace.

**Mixing structural and semantic changes in one pass.** Structural changes (moving divs, changing nesting, adding containers) and semantic changes (rewriting text, updating data) use different cognitive modes. Mixing them in one edit degrades both. Do structural changes first, validate, then do semantic changes.

**Opening/closing tag pairing in transforms.** When converting one element type to another (e.g., tabs → cards), the transform must add BOTH the opening and closing tags. A transform that adds `<div class="card-body">` but relies on an existing `</div>` that was closing a different element breaks nesting silently and cascades through the entire document.

**Compressed taxonomic codes as primary UI.** Using short codes (C2, E1, T5) as the visible element with tooltips for meaning reads as noise to anyone who doesn't already hold the taxonomy. Plain-language names must always be visible; codes are secondary metadata. Design principle: expand, don't compress.

**"Helpful reorganization" of a large file.** A new editing session sees that sections could be reordered, CSS classes renamed, or functions regrouped. Catastrophic on a 3000+ line file — creates a diff touching every line, making it impossible to verify what actually changed. Rule: never reorganize a large HTML file. Only make targeted, traceable changes.

**Consolidating "duplicate" CSS.** After 15 editing sessions, CSS has near-duplicate rules. Consolidation frequently breaks styling because "duplicates" have subtle differences (`var(--text2)` vs `var(--text3)`) or target different specificity contexts. Rule: tolerate CSS redundancy in long-lived files. Only consolidate when you can visually verify every affected section.

**Reformatting whitespace.** Re-indenting or adding line breaks for "readability" creates enormous diffs that obscure real changes and increase risk of accidentally modifying content. Rule: preserve existing whitespace patterns. New sections match the indentation of adjacent sections; never reformat existing content.

**Refactoring inline JavaScript.** Seeing repeated patterns and extracting shared functions changes call sites throughout the file, risking breakage of interactive features that were working. Rule: inline JS in HTML artifacts is append-only. New functions are fine. Refactoring existing functions is not, unless you can test every interactive feature.

**Silent anchor destruction.** An edit removes or renames an `id` attribute that other parts of the file reference — CSS `#id` selectors, JS `getElementById` calls, internal `href="#..."` links. Failures are invisible until someone clicks a link or triggers a feature. Rule: before modifying any `id` attribute, `grep` the entire file for references to that ID.

### The Append-Only Discipline

The anti-patterns above share a root cause: treating a long-lived HTML file as a codebase to maintain, rather than a document to extend. The correct mental model is **append-only**: existing content is load-bearing infrastructure. You add to it; you don't reshape it. New CSS goes at the end of the `<style>` block. New JS goes at the end of the `<script>` block. New sections go between existing sections. Nothing gets moved, renamed, or consolidated unless the change is surgically targeted and fully tested.

### 6.5 Substance vs. Presentation

Before editing any HTML artifact, ask: "Is this a substance change or a presentation change?"

| Type | Examples | Where the edit lives |
|------|----------|---------------------|
| Substance | New section, changed analysis, updated data | Source material (markdown, data), then regenerate HTML |
| Presentation | CSS tweaks, layout changes, component swap | HTML directly |

If the artifact was generated from markdown or data, substance changes go to the source and the HTML is regenerated. Editing substance directly in HTML creates drift between source and presentation.

The question is never "does a doc exist?" — that makes the rule dependent on filesystem state, not content nature. A section with no upstream doc that contains new analysis is a *gap to fill*, not permission to go HTML-first.

### 6.6 Canon Authority Tiers

For artifacts that have both a source format and an HTML rendering:

| Tier | Description | Edit where? |
|------|-------------|-------------|
| Markdown-sourced | Content originates in `.md`, HTML is generated | Edit the markdown, regenerate |
| HTML-native | Content was authored directly in HTML | Edit the HTML |
| Extractable | HTML content can be extracted back to structured data | Edit HTML directly. Use `html-tool.sh extract` if a future agent needs the content as text. No parallel markdown to maintain. |

Why not dual-canon for everything? Maintaining parallel markdown copies of presentation content creates drift. Extraction tooling provides the read path without the maintenance cost. But substance always gets a markdown home — that's non-negotiable.

### 6.7 Version Discipline

1. Run validation (div balance, structural integrity) before any version bump.
2. Increment minor version for content changes, major for structural changes.
3. Update the `doc-version` and `doc-updated` meta tags.
4. Update the **footer text** if the document has one: `"Settlement Architecture v8.30 — Updated 2026-06-07"` — visible in the rendered document.
5. Record the transition in a commit message or log: old version → new version, **line count, div count.**

**Corruption detection via baselines.** At each version, record the line count and div count. If v8.29 was 3269 lines with 564 divs and v8.30 is 3200 lines with 550 divs, something was silently dropped. This is the cheapest and most effective corruption detection.

**Version history as HTML comment (optional but recommended for long-lived files):**

```html
<!-- VERSION LOG
  v8.28: 3269 lines, 564 divs. 9 sections. 2026-06-06.
  v8.30: 3927 lines, 564 divs. Added §1.75 LP Experience. 2026-06-07.
  v9.0:  restructured tracks. 2026-06-08.
-->
```

---

### 6.8 CSS Scoping for Long-Lived Files

When adding section N+1 to a file that already has N sections with their own CSS:

**Class name collision.** A new section that introduces `.card` or `.header` styles bleeds into existing sections. Two practices:
- **Prefix all new classes** with the section abbreviation: `lpx-step`, `lpx-mockup`, `sys-json`, `wire-tag`
- **Scope via ancestor ID:** `#section-15 .card { ... }` — only applies within that section

**CSS ordering.** New CSS injected before `</style>` goes after all existing rules, winning specificity ties by cascade order. This is usually fine but causes unexpected overrides when the new section uses generic class names. If in doubt, prefix.

**Media query interaction.** If the file has an existing `@media` block, new responsive rules must go inside it — not create a duplicate `@media` block. Duplicate `@media` blocks work but are confusing and create maintenance ambiguity about which one to edit.

**Color tokens.** New sections should always use the existing CSS custom properties (`var(--accent)`, `var(--text-muted)`, etc.) rather than hard-coding hex values. This ensures light/dark mode works automatically. Exception: inline styles on wireframe-class content that intentionally uses a fixed light palette (the "app screen" being mocked up).

### 6.9 Operator-Level Patterns

These patterns emerged from maintaining production artifacts (4,460 lines, 664 divs) across intensive editing sessions. They complement the framework-level methodology above.

---

#### The `replace_once()` Pattern (for editing existing content)

The injection template above handles *additions* — new CSS, HTML, or JS inserted at anchor points. The other dominant operation is *editing existing content*: changing a status badge, updating a pricing cell, swapping an info box severity.

Large HTML files contain many structurally identical fragments. A comparison table with 9 providers has 9 cells that all look like `<td style="padding: 8px; text-align: center;">OPEN</td>`. Bare `str.replace()` matches the first occurrence regardless of which row you intended. The edit lands in the wrong row with no error.

**`replace_once()` validates uniqueness before replacing:**

```python
def replace_once(html, old, new, label):
    """Replace exactly one occurrence. Warn if zero or multiple matches."""
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

**Usage in a transform script:**

```python
# BAD — hits whichever "OPEN" cell comes first
html = html.replace('<td style="padding: 8px;">OPEN</td>',
                     '<td style="padding: 8px;">CLOSED</td>')

# GOOD — include surrounding context to guarantee a unique match
html = replace_once(html,
    'data-provider="bridge-xyz">\n              <td style="padding: 8px;">OPEN</td>',
    'data-provider="bridge-xyz">\n              <td style="padding: 8px;">CLOSED</td>',
    "Bridge XYZ status → CLOSED")
```

**The rule:** include enough surrounding context in the `old` string — the parent row's `data-` attribute, a neighboring cell, or the preceding comment — so that `html.count(old) == 1`. If `replace_once()` prints a warning, your context window is too narrow. Widen it; do not suppress the warning.

---

#### Factual Claim Cascade

**Factual claim cascade across sections.** A factual claim in a comparison table (pricing number, status, capability flag) propagates to downstream sections via copy-paste across editing sessions: negotiation lever summaries, registry entries, info boxes, tooltips, calculator defaults. Changing the claim in one location without sweeping for echoes leaves contradictions — the table says "$0.30" but the negotiation section still says "$0.25" because it was written two sessions ago.

**Rule:** After any batch of factual edits, sweep the full file:

```bash
grep -n "old_value" file.html
```

Update every instance, or document in a code comment why one instance is intentionally different (e.g., a historical reference vs. current pricing). The sweep is mandatory because factual inconsistency in a decision document destroys trust in the entire artifact — the reader cannot know which value is current.

---

#### Card Status Synchronization (cross-reference: §3.15)

An option or provider card has four synchronized layers. Changing the card's status (e.g., from "blocked" to "recommended") requires updating all four. Partial updates produce visually contradictory cards — an info box that says "now available" inside a card with a red `blocked` border.

| Layer | What to update | Example values |
|-------|---------------|----------------|
| **1. CSS class** | The class on the card's root element that controls border color and background | `recommended`, `alternative`, `blocked`, `neutral` |
| **2. Badge** | Badge text and badge CSS class (color, icon) | Text: "Recommended" / "Blocked"; Class: `badge-green`, `badge-red` |
| **3. Info box** | Content text and severity class inside the card's info/callout box | Text: "Available in all corridors"; Class: `info-box-success`, `info-box-warning`, `info-box-danger` |
| **4. SVG annotations** | Colors, labels, border styles, and connector arrows in any associated diagram | Border stroke: `#27ae60` (green) vs `#e74c3c` (red); Label text; Arrow routing |

**Checklist when changing a card's status:**

1. `grep -n 'card-id-or-data-attr'` to find all four layers
2. Update the CSS class on the root element
3. Update badge text and badge class
4. Update info box content and severity class
5. Update SVG annotation colors, labels, and border style
6. Browser preview to visually confirm consistency
7. Check both light and dark themes (badge colors that work on dark backgrounds may be invisible on light)

---

#### Bottom-Up Edit Ordering

When making multiple edits to a file interactively (using the Edit tool, not a transform script), **work from the bottom of the file upward** — highest line numbers first. Each replacement may add or remove lines, shifting all subsequent line numbers. If you edit line 200 first, the target you found at line 1800 via `grep -n` is now at a different line.

Bottom-up ordering keeps all unprocessed targets at their original line numbers.

**If bottom-up is impractical** (e.g., edits depend on each other top-down), re-run `html-tool.sh sections` or `grep -n` after each replacement to reacquire accurate line numbers before the next edit.

**This does not apply to transform scripts.** A Python script that reads the file into a string and performs all replacements before writing operates on the original content — line-number shift is not a concern.

---

#### Recovery from `.bak` Files

`html-tool.sh replace` creates a `.bak` file before overwriting. This is the safety net for failed replacements.

**Recovery workflow when validation fails after a replace:**

```bash
# 1. Restore the pre-edit version
cp file.html.bak file.html

# 2. Diff to find what the replacement actually changed
diff file.html.bak file-after-failed-edit.html | head -40

# 3. Identify the discrepancy — missing closing tag, wrong section boundary, etc.

# 4. Fix the replacement fragment in /tmp/section.html

# 5. Re-run the replace
./html-tool.sh replace panel-id /tmp/section.html

# 6. Validate again
./html-tool.sh validate
```

**Do not attempt to "fix forward"** by making corrective edits on top of a corrupted file. The `.bak` exists so you can revert cleanly. Forward-fixing compounds corruption — each corrective edit may introduce its own imbalance, and the resulting diff becomes unreadable.

---

#### Pre-Publish Sweep

After all edits are complete and before the artifact is shared, delivered, or committed, run the full sweep. This is the final gate — it catches accumulated drift from multi-session editing that per-edit validation misses.

**The sweep:**

| Step | Command / Action | What it catches |
|------|-----------------|-----------------|
| 1. Full validation | `python3 validate.py <file>` (three-pass: structure, links, semantics) | Div imbalance, broken internal links, orphaned IDs |
| 2. Stale factual claims | `grep -n "<old_value>"` for every value changed in this session | Factual claim cascade — echoes of old data in sections you didn't edit |
| 3. Version consistency | Check `doc-version` meta tag, footer text, and version log comment all match | Version string drift between locations |
| 4. Card layer sync | For every card whose status changed: verify CSS class, badge, info box, and SVG all agree | Partial status updates (see Card Status Synchronization checklist) |
| 5. Dual-theme preview | Open in browser, toggle light/dark theme | Colors that work on one background but are invisible or unreadable on the other |
| 6. Interactive feature check | If the file has calculators, toggles, or tab systems: click through every provider/scenario combination | JS breakage from renamed IDs, missing event handlers, or stale selector strings |

**Rule:** No artifact ships without completing all six steps. Steps 1-3 are mechanical and fast. Steps 4-6 require visual inspection and cannot be automated away. If time pressure tempts you to skip steps 5-6, that is precisely when visual regressions are most likely — the edits were rushed, and rushed edits are the ones that break themes and interactions.


## 7. Rendering Pipeline

For generating PNG output from HTML artifacts (diagrams, screenshots, visual artifacts).

### 7.1 Chromium Headless

```bash
/opt/homebrew/bin/chromium \
  --headless \
  --screenshot="/path/to/output.png" \
  --window-size=1400,700 \
  --force-device-scale-factor=2 \
  "file:///path/to/source.html"
```

- `--force-device-scale-factor=2` produces retina-quality output (2x pixel density).
- Adjust `--window-size` to match the artifact's intended viewport.
- The file URL must be absolute (`file:///`).

### 7.2 Embedding PNGs in SVG

For compositing screenshots with SVG annotations:

```html
<svg viewBox="0 0 1400 700" xmlns="http://www.w3.org/2000/svg">
  <image href="file:///path/to/screenshot.png" x="0" y="0" width="1400" height="700"/>
  <!-- annotation overlays -->
</svg>
```

**Coordinate mapping:** With `--force-device-scale-factor=2`, the actual pixel dimensions are 2x the `--window-size`. SVG coordinates correspond to the viewport size (not pixel size), so: `SVG coordinate = actual_pixel / 2`.

**Measuring element positions:** Use PIL pixel-color sampling to locate elements in a screenshot:
```python
from PIL import Image
img = Image.open('screenshot.png')
for y in range(0, img.height, 4):
    for x in range(0, img.width, 4):
        r, g, b = img.getpixel((x, y))[:3]
        if r > 200 and g < 160 and b < 160:
            red_pixels.append((x, y))
```

**Offset trap:** If the screenshot is embedded at `x=18, y=4` in the SVG, add (18, 4) to ALL overlay coordinates. Miss this and everything drifts.

**Window-size clipping:** `--window-size` clips content silently if too small. Size to your layout. Check the output dimensions match expectations.

### 7.3 Annotation Overlays

After embedding a screenshot, add SVG annotation elements:

- **Arrowhead markers** for callout lines
- **L-shaped elbow connectors** (horizontal + vertical segments, no diagonals)
- **Dashed connectors** for optional/conditional relationships
- **Text labels** using the monospace stack: `ui-monospace, "SF Mono", Menlo, Consolas, monospace`

Layout options:
- **Full-width SVG** with annotations overlaid directly
- **SVG + right annotation panel** using CSS flexbox (SVG on left, legend on right)

---

## 8. Skeletons

### 8.1 Document-Class Skeleton

Complete, copy-pasteable starting point:

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="doc-version" content="1.0">
<meta name="doc-updated" content="YYYY-MM-DDTHH:MM:SSZ">
<title>Document Title</title>
<style>
:root {
  --bg:#0b0d14; --surface:#141720; --surface2:#1c2030; --surface3:#232840;
  --border:#2a2f45; --border2:#363d5a;
  --text:#e4e6f0; --text2:#9aa0bb; --text3:#5c6480;
  --accent:#6ea8fe; --accent2:#a78bfa; --accent3:#34d399; --warn:#fb923c;
}
body.light-mode {
  --bg:#f8f9fb; --surface:#ffffff; --surface2:#f0f2f7; --surface3:#e8ecf4;
  --border:#dde1ee; --border2:#c8cedf;
  --text:#1a1d2e; --text2:#4a5068; --text3:#8890a8;
  --accent:#2563eb; --accent2:#7c3aed; --accent3:#059669; --warn:#ea580c;
}
* { box-sizing:border-box; margin:0; padding:0; }
body { font-family:system-ui,-apple-system,sans-serif; background:var(--bg); color:var(--text); font-size:15px; line-height:1.7; }
.wrap { max-width:820px; margin:0 auto; padding:56px 28px 120px; }
.doc-header { margin-bottom:56px; border-bottom:1px solid var(--border); padding-bottom:32px; }
.doc-title { font-size:26px; font-weight:700; color:var(--text); letter-spacing:-.02em; margin-bottom:10px; line-height:1.3; }
.doc-subtitle { font-size:14px; color:var(--text3); line-height:1.5; }
.section { margin-bottom:56px; }
.section-header { font-size:12px; font-weight:700; text-transform:uppercase; letter-spacing:.1em; color:var(--text2); margin-bottom:20px; padding-bottom:10px; border-bottom:1px solid var(--border); display:flex; align-items:center; gap:8px; }
.section-id { font-size:11px; font-weight:700; color:var(--text3); font-family:'SF Mono','Fira Code',monospace; user-select:none; flex-shrink:0; }
.subsection { margin-bottom:32px; }
.subsection-header { font-size:13px; font-weight:700; color:var(--text); margin-bottom:12px; display:flex; align-items:baseline; gap:8px; }
.subsection-id { font-size:10px; font-weight:700; font-family:'SF Mono','Fira Code',monospace; color:var(--text3); user-select:none; }
#theme-toggle { position:fixed; top:14px; right:18px; z-index:1000; background:var(--surface2); border:1px solid var(--border); border-radius:8px; padding:6px 12px; font-size:12px; font-weight:600; color:var(--text2); cursor:pointer; transition:background .15s,color .15s; }
#theme-toggle:hover { background:var(--surface3); color:var(--text); }
.comment-widget { margin-top:48px; padding:20px 24px; background:var(--surface); border:1px solid var(--border); border-radius:10px; }
.comment-widget-title { font-size:11px; font-weight:700; text-transform:uppercase; letter-spacing:.09em; color:var(--text3); margin-bottom:14px; }
.comment-row { display:flex; align-items:center; gap:10px; margin-bottom:8px; }
.comment-label { font-size:11px; font-weight:700; font-family:monospace; color:var(--text3); min-width:36px; }
.comment-input { flex:1; background:var(--surface2); border:1px solid var(--border); border-radius:6px; padding:6px 10px; font-size:12px; color:var(--text); outline:none; }
.comment-input:focus { border-color:var(--accent); }
.copy-comments-btn { margin-top:12px; padding:8px 18px; background:var(--accent); color:#fff; border:none; border-radius:6px; font-size:12px; font-weight:700; cursor:pointer; transition:opacity .15s; }
.copy-comments-btn:hover { opacity:.85; }
.copy-feedback { margin-top:8px; font-size:11px; color:var(--accent3); min-height:16px; }
</style>
</head>
<body>
<button id="theme-toggle" onclick="toggleTheme()">&#9788; Light</button>
<div class="wrap">

<div class="doc-header">
  <div class="doc-title">Document Title</div>
  <div class="doc-subtitle">One-sentence framing.</div>
</div>

<div class="section" id="s1">
  <div class="section-header"><span class="section-id">&sect;1</span> First Section</div>
  <p>Content.</p>
</div>

<div class="section" id="s2">
  <div class="section-header"><span class="section-id">&sect;2</span> Second Section</div>
  <p>Content.</p>
</div>

<div class="comment-widget" id="comment-widget">
  <div class="comment-widget-title">Section Comments</div>
  <div class="comment-inputs" id="comment-inputs"></div>
  <button class="copy-comments-btn" onclick="copyComments()">Copy comments</button>
  <div class="copy-feedback" id="copy-feedback"></div>
</div>

</div>
<script>
function toggleTheme() {
  var isLight = document.body.classList.toggle('light-mode');
  localStorage.setItem('theme', isLight ? 'light' : 'dark');
  document.getElementById('theme-toggle').textContent = isLight ? '☾ Dark' : '☆ Light';
}
(function() {
  if (localStorage.getItem('theme') === 'light') {
    document.body.classList.add('light-mode');
    var btn = document.getElementById('theme-toggle');
    if (btn) btn.textContent = '☾ Dark';
  }
})();

var sections = [
  { id: 's1', label: '§1' },
  { id: 's2', label: '§2' },
];
(function() {
  var container = document.getElementById('comment-inputs');
  if (!container) return;
  sections.forEach(function(s) {
    var row = document.createElement('div');
    row.className = 'comment-row';
    row.innerHTML = '<span class="comment-label">' + s.label + '</span>' +
      '<input class="comment-input" type="text" id="ci-' + s.id +
      '" placeholder="Comment on ' + s.label + '…">';
    container.appendChild(row);
  });
})();
function copyComments() {
  var parts = sections.map(function(s) {
    var val = (document.getElementById('ci-' + s.id) || {}).value || '';
    return val.trim() ? '[' + s.label + '] ' + val.trim() : null;
  }).filter(Boolean);
  if (!parts.length) { document.getElementById('copy-feedback').textContent = 'Nothing to copy.'; return; }
  navigator.clipboard.writeText(parts.join(' | ')).then(function() {
    document.getElementById('copy-feedback').textContent = 'Copied to clipboard.';
    setTimeout(function() { document.getElementById('copy-feedback').textContent = ''; }, 2500);
  });
}

function fmt(n) { return n == null ? '—' : Number(n).toLocaleString(); }
function fmtDate(s) {
  if (!s) return '—';
  try { return new Date(s).toISOString().slice(0, 16).replace('T', ' ') + ' UTC'; }
  catch (e) { return s.slice(0, 16); }
}
function fmtDuration(secs) {
  if (secs == null || secs < 0) return '—';
  if (secs < 60) return secs + 's';
  if (secs < 3600) return Math.floor(secs / 60) + 'm ' + (secs % 60) + 's';
  var h = Math.floor(secs / 3600);
  var m = Math.floor((secs % 3600) / 60);
  return h + 'h ' + m + 'm';
}
</script>
</body>
</html>
```

### 8.2 Dashboard-Class Skeleton

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="doc-version" content="1.0">
<meta name="doc-updated" content="YYYY-MM-DDTHH:MM:SSZ">
<title>Dashboard Title</title>
<style>
:root {
  --bg:#0b0d14; --surface:#141720; --surface2:#1c2030; --surface3:#232840;
  --border:#2a2f45; --border2:#363d5a;
  --text:#e4e6f0; --text2:#9aa0bb; --text3:#5c6480;
  --accent:#6ea8fe; --accent2:#a78bfa; --accent3:#34d399; --warn:#fb923c;
  --done-col:#4ade80; --done-bg:#0a2e1a;
  --pend-col:#fbbf24; --pend-bg:#2a2008;
  --fail-col:#f87171; --fail-bg:#2e0a0a;
  --act-col:#60a5fa;  --act-bg:#0a1a2e;
  --cl-col:#9aa0bb;   --cl-bg:#1c2030;
}
body.light-mode {
  --bg:#f8f9fb; --surface:#ffffff; --surface2:#f0f2f7; --surface3:#e8ecf4;
  --border:#dde1ee; --border2:#c8cedf;
  --text:#1a1d2e; --text2:#4a5068; --text3:#8890a8;
  --accent:#2563eb; --accent2:#7c3aed; --accent3:#059669; --warn:#ea580c;
  --done-col:#1a7a3c; --done-bg:#d4f7e0;
  --pend-col:#a06000; --pend-bg:#fef3cd;
  --fail-col:#c0392b; --fail-bg:#fde8e6;
  --act-col:#1565c0;  --act-bg:#e3f0ff;
  --cl-col:#666;      --cl-bg:#eee;
}
* { box-sizing:border-box; margin:0; padding:0; }
body { font-family:system-ui,-apple-system,'Segoe UI',sans-serif; background:var(--bg); color:var(--text); line-height:1.5; font-size:14px; }
.wrap { max-width:1000px; margin:0 auto; padding:16px; }
.sec { background:var(--surface); border:1px solid var(--border); border-radius:10px; padding:16px; margin-bottom:14px; }
.h2 { font-size:.85rem; font-weight:700; text-transform:uppercase; color:var(--text2); margin-bottom:10px; letter-spacing:.04em; }
.pgrid { display:grid; grid-template-columns:repeat(auto-fit,minmax(110px,1fr)); gap:10px; margin-bottom:12px; }
.scard { background:var(--surface2); border-radius:8px; padding:10px 12px; text-align:center; }
.scard .n { font-size:1.5rem; font-weight:700; color:var(--accent); }
.scard .l { font-size:.65rem; color:var(--text3); text-transform:uppercase; letter-spacing:.04em; }
.badge { display:inline-block; padding:2px 7px; border-radius:10px; font-size:.72rem; font-weight:600; white-space:nowrap; }
.bd { color:var(--done-col); background:var(--done-bg); }
.bp { color:var(--pend-col); background:var(--pend-bg); }
.bf { color:var(--fail-col); background:var(--fail-bg); }
.ba { color:var(--act-col);  background:var(--act-bg); }
.bc { color:var(--cl-col);   background:var(--cl-bg); }
.tbl { width:100%; border-collapse:collapse; font-size:.8rem; }
.tbl th { text-align:left; padding:5px 8px; color:var(--text3); font-size:.68rem; font-weight:600; text-transform:uppercase; letter-spacing:.04em; border-bottom:1px solid var(--border); }
.tbl td { padding:6px 8px; border-bottom:1px solid var(--border); vertical-align:top; }
.tbl tr:last-child td { border-bottom:none; }
.filter-bar { display:flex; align-items:center; gap:12px; flex-wrap:wrap; margin-bottom:10px; padding:8px 10px; background:var(--surface2); border-radius:8px; font-size:.8rem; }
.filter-bar select { font-size:.78rem; padding:2px 6px; border-radius:5px; border:1px solid var(--border); background:var(--surface); color:var(--text); }
.dgrid { display:grid; grid-template-columns:repeat(auto-fit,minmax(140px,1fr)); gap:8px; }
.dkv .k { color:var(--text3); font-size:.67rem; text-transform:uppercase; letter-spacing:.04em; }
.dkv .v { color:var(--text); font-weight:500; font-size:.8rem; }
.empty { text-align:center; padding:24px 20px; color:var(--text3); font-size:.85rem; }
#theme-toggle { position:fixed; top:14px; right:18px; z-index:1000; background:var(--surface2); border:1px solid var(--border); border-radius:8px; padding:6px 12px; font-size:12px; font-weight:600; color:var(--text2); cursor:pointer; }
#theme-toggle:hover { background:var(--surface3); color:var(--text); }
#meta-line { font-size:.7rem; color:var(--text3); text-align:right; margin-bottom:10px; }
</style>
</head>
<body>
<button id="theme-toggle" onclick="toggleTheme()">&#9788; Light</button>
<div class="wrap">

<div id="meta-line"></div>

<div class="sec">
  <div class="h2">Summary</div>
  <div class="pgrid" id="stats"></div>
</div>

<div class="sec">
  <div class="h2">Data</div>
  <div class="filter-bar">
    <label>Status:</label>
    <select id="status-filter" onchange="applyFilters()">
      <option value="">All</option>
      <option value="done">Done</option>
      <option value="pending">Pending</option>
      <option value="failed">Failed</option>
    </select>
  </div>
  <table class="tbl" id="data-table">
    <thead><tr><th>Name</th><th>Status</th><th>Updated</th></tr></thead>
    <tbody id="data-body"></tbody>
  </table>
  <div class="empty" id="empty-state" style="display:none;">No items match filters.</div>
</div>

</div>
<script>
var D = {}; // inject via D_JSON pattern

function toggleTheme() {
  var isLight = document.body.classList.toggle('light-mode');
  localStorage.setItem('theme', isLight ? 'light' : 'dark');
  document.getElementById('theme-toggle').textContent = isLight ? '☾ Dark' : '☆ Light';
}
(function() {
  if (localStorage.getItem('theme') === 'light') {
    document.body.classList.add('light-mode');
    var btn = document.getElementById('theme-toggle');
    if (btn) btn.textContent = '☾ Dark';
  }
})();

document.getElementById('meta-line').textContent = 'Generated ' + new Date().toUTCString();

function fmt(n) { return n == null ? '—' : Number(n).toLocaleString(); }
function fmtDate(s) {
  if (!s) return '—';
  try { return new Date(s).toISOString().slice(0, 16).replace('T', ' ') + ' UTC'; }
  catch (e) { return s.slice(0, 16); }
}

function applyFilters() {
  var statusVal = document.getElementById('status-filter').value;
  var rows = document.querySelectorAll('#data-table tbody tr');
  var visible = 0;
  rows.forEach(function(row) {
    var show = !statusVal || row.dataset.status === statusVal;
    row.style.display = show ? '' : 'none';
    if (show) visible++;
  });
  document.getElementById('empty-state').style.display = visible ? 'none' : '';
}
</script>
</body>
</html>
```

---

### 8.3 Presentation-Class Skeleton

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="doc-version" content="1.0">
<meta name="doc-updated" content="YYYY-MM-DDTHH:MM:SSZ">
<title>Presentation Title</title>
<style>
:root {
  --bg:#0b0d14; --surface:#141720; --surface2:#1c2030; --surface3:#232840;
  --border:#2a2f45; --border2:#363d5a;
  --text:#e4e6f0; --text2:#9aa0bb; --text3:#5c6480;
  --accent:#6ea8fe; --accent2:#a78bfa; --accent3:#34d399; --warn:#fb923c;
  --chrome-bg:#1e2233; --chrome-border:#2a2f45;
  --tag-new:#34d399; --tag-same:#9aa0bb; --tag-better:#6ea8fe; --tag-regression:#fb923c;
}
body.light-mode {
  --bg:#f8f9fb; --surface:#ffffff; --surface2:#f0f2f7; --surface3:#e8ecf4;
  --border:#dde1ee; --border2:#c8cedf;
  --text:#1a1d2e; --text2:#4a5068; --text3:#8890a8;
  --accent:#2563eb; --accent2:#7c3aed; --accent3:#059669; --warn:#ea580c;
  --chrome-bg:#e8ecf4; --chrome-border:#c8cedf;
  --tag-new:#059669; --tag-same:#8890a8; --tag-better:#2563eb; --tag-regression:#ea580c;
}
* { box-sizing:border-box; margin:0; padding:0; }
html, body { height:100%; overflow:hidden; }
body { font-family:system-ui,-apple-system,sans-serif; background:var(--bg); color:var(--text); font-size:14px; line-height:1.5; }

/* Theme toggle */
#theme-toggle { position:fixed; top:14px; right:18px; z-index:1000; background:var(--surface2); border:1px solid var(--border); border-radius:8px; padding:6px 12px; font-size:12px; font-weight:600; color:var(--text2); cursor:pointer; transition:background .15s,color .15s; }
#theme-toggle:hover { background:var(--surface3); color:var(--text); }

/* Track tabs */
.track-bar { position:fixed; top:0; left:0; right:0; z-index:900; display:flex; gap:0; background:var(--surface); border-bottom:1px solid var(--border); padding:0 60px; }
.track-btn { padding:12px 18px; font-size:12px; font-weight:600; color:var(--text3); background:none; border:none; border-bottom:2px solid transparent; cursor:pointer; transition:all .15s; white-space:nowrap; }
.track-btn:hover { color:var(--text); }
.track-btn.active { color:var(--accent); border-bottom-color:var(--accent); }

/* Step dots */
.step-dots { position:fixed; bottom:20px; left:50%; transform:translateX(-50%); z-index:900; display:flex; gap:8px; background:var(--surface); border:1px solid var(--border); border-radius:20px; padding:8px 16px; }
.step-dot { width:10px; height:10px; border-radius:50%; background:var(--surface3); border:1px solid var(--border2); cursor:pointer; transition:all .15s; }
.step-dot.active { background:var(--accent); border-color:var(--accent); }
.step-dot:hover { background:var(--text3); }
.step-label { font-size:11px; color:var(--text3); margin-left:8px; font-weight:600; align-self:center; }

/* Slide container */
.track { display:none; }
.track.active { display:block; }
.slide { display:none; height:100vh; padding:52px 24px 60px; }
.slide.active { display:flex; gap:20px; }

/* Split pane */
.pane-mockup { flex:1; display:flex; flex-direction:column; min-width:0; }
.pane-system { width:380px; flex-shrink:0; display:flex; flex-direction:column; gap:12px; overflow-y:auto; }

/* Browser chrome */
.browser-chrome { background:var(--chrome-bg); border:1px solid var(--chrome-border); border-radius:10px; flex:1; display:flex; flex-direction:column; overflow:hidden; }
.chrome-bar { display:flex; align-items:center; gap:8px; padding:8px 12px; border-bottom:1px solid var(--chrome-border); }
.chrome-dots { display:flex; gap:5px; }
.chrome-dots span { width:10px; height:10px; border-radius:50%; }
.chrome-dots span:nth-child(1) { background:#ff5f57; }
.chrome-dots span:nth-child(2) { background:#ffbd2e; }
.chrome-dots span:nth-child(3) { background:#28c840; }
.chrome-url { flex:1; background:var(--surface2); border:1px solid var(--border); border-radius:5px; padding:4px 10px; font-size:11px; color:var(--text2); font-family:ui-monospace,'SF Mono',Menlo,monospace; }
.chrome-body { flex:1; padding:20px; overflow-y:auto; background:var(--bg); }

/* System panel */
.sys-card { background:var(--surface); border:1px solid var(--border); border-radius:8px; padding:12px; }
.sys-card-title { font-size:10px; font-weight:700; text-transform:uppercase; letter-spacing:.08em; color:var(--text3); margin-bottom:8px; }
.sys-card pre { font-size:11px; font-family:ui-monospace,'SF Mono',Menlo,monospace; color:var(--accent); white-space:pre-wrap; word-break:break-all; line-height:1.5; }

/* Comparison tags */
.ctag { display:inline-block; padding:1px 6px; border-radius:3px; font-size:9px; font-weight:700; text-transform:uppercase; letter-spacing:.06em; vertical-align:middle; margin-left:4px; }
.ctag-new { color:#fff; background:var(--tag-new); }
.ctag-same { color:#fff; background:var(--tag-same); }
.ctag-better { color:#fff; background:var(--tag-better); }
.ctag-regression { color:#fff; background:var(--tag-regression); }

/* Keyboard hint */
.key-hint { position:fixed; bottom:20px; right:24px; font-size:11px; color:var(--text3); z-index:900; }
.key-hint kbd { display:inline-block; padding:2px 6px; background:var(--surface2); border:1px solid var(--border); border-radius:4px; font-family:ui-monospace,'SF Mono',Menlo,monospace; font-size:10px; }
</style>
</head>
<body>
<button id="theme-toggle" onclick="toggleTheme()">&#9788; Light</button>

<div class="track-bar" id="track-bar"></div>

<div class="track active" id="track-onboarding" data-track="onboarding">
  <div class="slide active" data-slide="0">
    <div class="pane-mockup">
      <div class="browser-chrome">
        <div class="chrome-bar">
          <div class="chrome-dots"><span></span><span></span><span></span></div>
          <div class="chrome-url">app.example.com/onboarding</div>
        </div>
        <div class="chrome-body">
          <h2 style="margin-bottom:12px;">Welcome Screen <span class="ctag ctag-new">NEW</span></h2>
          <p style="color:var(--text2);">Onboarding step 1 mockup content.</p>
        </div>
      </div>
    </div>
    <div class="pane-system">
      <div class="sys-card">
        <div class="sys-card-title">API Call</div>
        <pre>POST /api/v1/onboarding/start
{ "user_id": "usr_123" }</pre>
      </div>
      <div class="sys-card">
        <div class="sys-card-title">State Change</div>
        <pre>status: null -> onboarding_started</pre>
      </div>
    </div>
  </div>
  <div class="slide" data-slide="1">
    <div class="pane-mockup">
      <div class="browser-chrome">
        <div class="chrome-bar">
          <div class="chrome-dots"><span></span><span></span><span></span></div>
          <div class="chrome-url">app.example.com/onboarding/profile</div>
        </div>
        <div class="chrome-body">
          <h2 style="margin-bottom:12px;">Profile Setup <span class="ctag ctag-same">SAME</span></h2>
          <p style="color:var(--text2);">Onboarding step 2 mockup content.</p>
        </div>
      </div>
    </div>
    <div class="pane-system">
      <div class="sys-card">
        <div class="sys-card-title">API Call</div>
        <pre>PUT /api/v1/users/usr_123/profile
{ "name": "Jane Doe" }</pre>
      </div>
    </div>
  </div>
  <div class="slide" data-slide="2">
    <div class="pane-mockup">
      <div class="browser-chrome">
        <div class="chrome-bar">
          <div class="chrome-dots"><span></span><span></span><span></span></div>
          <div class="chrome-url">app.example.com/onboarding/complete</div>
        </div>
        <div class="chrome-body">
          <h2 style="margin-bottom:12px;">Confirmation <span class="ctag ctag-better">BETTER</span></h2>
          <p style="color:var(--text2);">Onboarding step 3 mockup content.</p>
        </div>
      </div>
    </div>
    <div class="pane-system">
      <div class="sys-card">
        <div class="sys-card-title">Webhook</div>
        <pre>POST /webhooks/onboarding_complete
{ "user_id": "usr_123",
  "completed_at": "2026-06-09T..." }</pre>
      </div>
    </div>
  </div>
</div>

<div class="track" id="track-wallet" data-track="wallet">
  <div class="slide" data-slide="0">
    <div class="pane-mockup">
      <div class="browser-chrome">
        <div class="chrome-bar">
          <div class="chrome-dots"><span></span><span></span><span></span></div>
          <div class="chrome-url">app.example.com/wallet</div>
        </div>
        <div class="chrome-body">
          <h2 style="margin-bottom:12px;">Wallet Overview</h2>
          <p style="color:var(--text2);">Wallet journey step 1.</p>
        </div>
      </div>
    </div>
    <div class="pane-system">
      <div class="sys-card">
        <div class="sys-card-title">API Call</div>
        <pre>GET /api/v1/wallets/wal_456
-> { "balance": "$10,000.00" }</pre>
      </div>
    </div>
  </div>
  <div class="slide" data-slide="1">
    <div class="pane-mockup">
      <div class="browser-chrome">
        <div class="chrome-bar">
          <div class="chrome-dots"><span></span><span></span><span></span></div>
          <div class="chrome-url">app.example.com/wallet/transfer</div>
        </div>
        <div class="chrome-body">
          <h2 style="margin-bottom:12px;">Initiate Transfer <span class="ctag ctag-regression">REGRESSION</span></h2>
          <p style="color:var(--text2);">Wallet journey step 2.</p>
        </div>
      </div>
    </div>
    <div class="pane-system">
      <div class="sys-card">
        <div class="sys-card-title">API Call</div>
        <pre>POST /api/v1/transfers
{ "from": "wal_456", "amount": 500 }</pre>
      </div>
    </div>
  </div>
  <div class="slide" data-slide="2">
    <div class="pane-mockup">
      <div class="browser-chrome">
        <div class="chrome-bar">
          <div class="chrome-dots"><span></span><span></span><span></span></div>
          <div class="chrome-url">app.example.com/wallet/transfer/confirm</div>
        </div>
        <div class="chrome-body">
          <h2 style="margin-bottom:12px;">Transfer Confirmed</h2>
          <p style="color:var(--text2);">Wallet journey step 3.</p>
        </div>
      </div>
    </div>
    <div class="pane-system">
      <div class="sys-card">
        <div class="sys-card-title">State Change</div>
        <pre>transfer.status: pending -> completed
wallet.balance: $10,000 -> $9,500</pre>
      </div>
    </div>
  </div>
</div>

<div class="step-dots" id="step-dots"></div>
<div class="key-hint"><kbd>&larr;</kbd> <kbd>&rarr;</kbd> navigate slides</div>

<script>
var TRACKS = [
  { id: 'onboarding', label: 'Onboarding Flow' },
  { id: 'wallet', label: 'Wallet Journey' },
];
var currentTrack = 'onboarding';
var currentSlide = {};

(function init() {
  /* Build track tabs */
  var bar = document.getElementById('track-bar');
  TRACKS.forEach(function(t) {
    var btn = document.createElement('button');
    btn.className = 'track-btn' + (t.id === currentTrack ? ' active' : '');
    btn.textContent = t.label;
    btn.setAttribute('data-track', t.id);
    btn.onclick = function() { switchTrack(t.id); };
    bar.appendChild(btn);
  });

  /* Initialize slide indices */
  TRACKS.forEach(function(t) { currentSlide[t.id] = 0; });

  /* Build step dots for initial track */
  buildDots();

  /* Theme restore */
  if (localStorage.getItem('theme') === 'light') {
    document.body.classList.add('light-mode');
    var btn = document.getElementById('theme-toggle');
    if (btn) btn.textContent = '☾ Dark';
  }
})();

function switchTrack(id) {
  currentTrack = id;
  document.querySelectorAll('.track').forEach(function(t) { t.classList.remove('active'); });
  document.getElementById('track-' + id).classList.add('active');
  document.querySelectorAll('.track-btn').forEach(function(b) {
    b.classList.toggle('active', b.getAttribute('data-track') === id);
  });
  showSlide(currentSlide[id] || 0);
  buildDots();
}

function showSlide(idx) {
  var track = document.getElementById('track-' + currentTrack);
  var slides = track.querySelectorAll('.slide');
  if (idx < 0 || idx >= slides.length) return;
  currentSlide[currentTrack] = idx;
  slides.forEach(function(s) { s.classList.remove('active'); });
  slides[idx].classList.add('active');
  updateDots();
}

function buildDots() {
  var track = document.getElementById('track-' + currentTrack);
  var count = track.querySelectorAll('.slide').length;
  var container = document.getElementById('step-dots');
  container.innerHTML = '';
  for (var i = 0; i < count; i++) {
    var dot = document.createElement('div');
    dot.className = 'step-dot' + (i === (currentSlide[currentTrack] || 0) ? ' active' : '');
    dot.setAttribute('data-idx', i);
    dot.onclick = (function(idx) { return function() { showSlide(idx); }; })(i);
    container.appendChild(dot);
  }
  var label = document.createElement('span');
  label.className = 'step-label';
  label.id = 'step-counter';
  container.appendChild(label);
  updateDots();
}

function updateDots() {
  var track = document.getElementById('track-' + currentTrack);
  var total = track.querySelectorAll('.slide').length;
  var idx = currentSlide[currentTrack] || 0;
  document.querySelectorAll('.step-dot').forEach(function(d, i) {
    d.classList.toggle('active', i === idx);
  });
  var counter = document.getElementById('step-counter');
  if (counter) counter.textContent = (idx + 1) + ' / ' + total;
}

/* Keyboard navigation */
document.addEventListener('keydown', function(e) {
  if (e.key === 'ArrowRight') showSlide((currentSlide[currentTrack] || 0) + 1);
  else if (e.key === 'ArrowLeft') showSlide((currentSlide[currentTrack] || 0) - 1);
});

function toggleTheme() {
  var isLight = document.body.classList.toggle('light-mode');
  localStorage.setItem('theme', isLight ? 'light' : 'dark');
  document.getElementById('theme-toggle').textContent = isLight ? '☾ Dark' : '☆ Light';
}
</script>
</body>
</html>
```

## 9. Checklist

Before publishing any artifact, verify every applicable item.

### Universal (all artifacts)

- [ ] Single self-contained `.html` file, no external dependencies (except D3 if concept graph present)
- [ ] All CSS inline in `<style>`, all JS inline in `<script>`
- [ ] `<meta name="doc-version">` and `<meta name="doc-updated">` present
- [ ] Dark mode is the default rendering
- [ ] Light mode overrides use higher-contrast accent values (`#2563eb` not `#6ea8fe`)
- [ ] Full color token block present (no partial copies)
- [ ] Null/missing values render as em dash, not empty or `null`
- [ ] No hardcoded URLs for delivery (resolved from config)
- [ ] Unique filename per artifact if multiple callers write to same directory

### Document-class

- [ ] Light/dark toggle present, fixed top-right, persists via `localStorage`
- [ ] Taxonomic section IDs (`§1`, `§1.1`) on every section, displayed in rendered HTML
- [ ] Clipboard comment widget present, `sections[]` array matches actual document sections
- [ ] Document header with title and subtitle
- [ ] `id` attributes on all sections, no duplicates

### Dashboard-class

- [ ] Stat cards render current metrics
- [ ] Filter bar filters actually work (toggle visibility, show empty state)
- [ ] Status badges use correct color class (`.bd`, `.bp`, `.bf`, `.ba`, `.bc`)
- [ ] Action buttons have valid targets

### Presentation-class

- [ ] Track tabs present and switch slide groups correctly
- [ ] Slide navigation with step dots (done/active/future states)
- [ ] Keyboard navigation: left/right arrows change slides within active track
- [ ] Slides are full-viewport (`100vh`, `overflow: hidden` on body)
- [ ] Split-pane layout renders on both themes (if used)
- [ ] Browser chrome mockups have correct URL display (if used)
- [ ] Comparison annotation tags visible and correctly classified (if used)

### SVG diagrams

- [ ] All marker IDs prefixed with diagram name (no cross-diagram collisions)
- [ ] Box dimensions within spec (120-160px wide, ~70px tall, `rx="10"`)
- [ ] Role colors applied consistently (Primary, Secondary, Highlight, Muted)
- [ ] No diagonal connectors (horizontal or L-shaped elbows only)
- [ ] `viewBox` set appropriately for content

### Post-edit validation

- [ ] Div count: opening `<div` matches closing `</div>`
- [ ] No orphaned or duplicated `id` attributes
- [ ] All internal `href="#..."` links have matching targets
- [ ] File opens in browser without console errors
