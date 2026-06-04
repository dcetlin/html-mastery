# HTML Mastery

An opinionated **canon + toolkit** for generating and editing **self-contained,
dark-first HTML artifacts** — reports, design docs, audits, dashboards, and
interactive tools — with no build step and (almost) no external dependencies.

Two halves:

- **The toolkit (`htmlgen/`)** — a small Python package that compiles a JSON
  content manifest into one self-contained `.html` file, plus a DOM-aware,
  token-efficient editor for surgically changing an existing artifact without
  re-reading or regenerating the whole file.
- **The canon (`STANDARDS.md`, `patterns.md`)** — the design system the toolkit
  encodes: a color-token system, light/dark toggle, taxonomic section IDs, a
  clipboard comment widget, a D3 concept graph, component CSS, and generator
  conventions. Useful on its own even if you don't use the Python.

The goal: **a new artifact should never start from a blank file.**

## What's in here

| Path | What it is |
|------|------------|
| [`htmlgen/`](./htmlgen/) | The Python toolkit — renderer, editor, components, conventions, template registry. |
| [`htmlgen/renderer.py`](./htmlgen/renderer.py) | Compile a JSON content manifest + template → one self-contained `.html` file. |
| [`htmlgen/editor.py`](./htmlgen/editor.py) | DOM-aware, token-efficient editor: target nodes by selector and apply edits without rewriting the file. |
| [`htmlgen/components/`](./htmlgen/components/) | Reusable primitives: theme toggle, clipboard widget, D3 vocabulary network, vocab tooltips. |
| [`htmlgen/conventions.yaml`](./htmlgen/conventions.yaml) | The design tokens (palette, typography, layout) the renderer reads. |
| [`htmlgen/templates/`](./htmlgen/templates/) | Template registry: `document-class`, `dashboard-class`, `spec-document`. |
| [`STANDARDS.md`](./STANDARDS.md) | The canon: artifact classes, tokens, components, checklist. |
| [`patterns.md`](./patterns.md) | Component + generator-convention reference. |
| [`examples/document.template.html`](./examples/document.template.html) | A complete, openable document-class skeleton — copy and fill in (no Python needed). |

## The toolkit

### Install

```bash
# with uv
uv pip install -e .            # core (beautifulsoup4, pyyaml)
uv pip install -e ".[markdown]" # + Markdown rendering of section content

# or plain pip
pip install -e ".[markdown]"
```

### Render a manifest → HTML

```bash
uv run htmlgen/renderer.py --content manifest.json --template document-class --output out.html
```

```python
from htmlgen.renderer import render, render_and_write

render("manifest.json", "document-class", "out.html")

# Or write to HTMLGEN_OUTPUT_DIR and get back a URL/path:
url_or_path = render_and_write("manifest.json", "document-class", "my-doc.html")
```

Templates available: `document-class`, `dashboard-class`, `spec-document`
(see `htmlgen/templates/<id>/content-scaffold.*` for the expected manifest shape).

### Edit an existing artifact (token-efficient)

`htmlgen/editor.py` is DOM-aware: it parses the artifact, lets you target nodes
by selector, and applies edits in place — so an agent or script can change one
section without reading or regenerating the entire document. Edits are recorded
as a JSONL trace (path configurable via `HTMLGEN_TRACE_LOG`, default
`~/.htmlgen/html-edit-traces.jsonl`).

### Delivery is decoupled

`render()` is pure (manifest → HTML string → file). Where the file is written and
served is configured separately:

- `HTMLGEN_OUTPUT_DIR` — where compiled files are written (default `./out`)
- `HTMLGEN_BASE_URL` — base URL the output dir is served under (optional)

So the same generator works locally, on object storage, or behind any file server.

## Design principles

1. **Self-contained.** All CSS and JS inline. No external fonts or CSS
   frameworks — only D3.js when a concept graph is present. A finished artifact
   is a single `.html` file.
2. **Dark-first, readable.** Default palette is dark; light mode is a class
   override with higher-contrast accents.
3. **Taxonomic navigation.** Sections are numbered (§1, §1.1) so they can be
   referenced by ID, not just scrolled to.
4. **Pure generation, separate delivery.** Rendering takes data and returns
   HTML; hosting is a swappable concern.
5. **Data injection over AJAX.** Page data is serialized once into a single JSON
   blob injected at generation time. The page never calls back to a server.

## Quick start (no Python)

1. Copy `examples/document.template.html` to a new file.
2. Replace the title/subtitle and add your `<div class="section" id="sN">` blocks.
3. Update the `sections[]` array in the inline script so the comment widget
   matches your sections.
4. Open the file. That's the whole build.

## License

MIT — see [`LICENSE`](./LICENSE).
