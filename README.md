# HTML Mastery

The specification for producing and maintaining rich interactive HTML documents
with LLMs.

Markdown is flat. Web apps are heavy. Self-contained HTML is the sweet spot for
**rich knowledge artifacts**: decision documents with interactive calculators,
architecture explorations with SVG flow diagrams, orientation tools with
progressive disclosure over hundreds of items.

This repo contains:

- **[`STANDARD.md`](./STANDARD.md)** — the complete specification. An LLM given
  this file produces production-quality interactive documents without any other
  tooling. Design system, component patterns, SVG conventions, and the
  production methodology for maintaining large documents (4,000+ lines) across
  many editing sessions.
- **[`gallery/`](./gallery/)** — exemplary artifacts you can open in your
  browser. Each demonstrates the full capability set while being useful as a
  starting template.
- **[`tools/`](./tools/)** — two lightweight tools that earn their keep in
  practice: a structural validator and a section-based editor.

No build step. No dependencies beyond a browser. No pip install.

## What's in here

| Path | What it is |
|------|------------|
| [`STANDARD.md`](./STANDARD.md) | The product. Design system, components, SVG conventions, production methodology, anti-patterns. |
| [`gallery/decision-document.html`](./gallery/decision-document.html) | Exemplary decision document: interactive calculator, SVG flows, option cards, tabs, step navigator. |
| [`tools/html-tool.sh`](./tools/html-tool.sh) | Section-based HTML editor. Extract, replace, inject, validate, preview. The forcing function that makes section-based editing the default. |
| [`tools/validate.py`](./tools/validate.py) | Structural integrity checker. Div balance, depth tracking, unclosed tags. Run after every edit. |
| [`LICENSE`](./LICENSE) | MIT. |

## Quick start

### With an LLM (recommended)

Point your LLM at `STANDARD.md`:

**Claude Code** — add to your project's `CLAUDE.md`:
```
For HTML artifacts, follow conventions in path/to/html-mastery/STANDARD.md
```

**Cursor / Windsurf** — add `STANDARD.md` to your rules file.

**Any LLM** — paste `STANDARD.md` into context when producing HTML artifacts.

Then ask the LLM to produce a document. It will follow the design system,
use the component patterns, and know the anti-patterns to avoid.

### Without an LLM

1. Open `gallery/decision-document.html` in your browser to see the ceiling.
2. Copy it and modify for your use case.
3. Run `tools/validate.py your-file.html` after edits.

### Using the tools

```bash
# Set your target file
export HTML_TOOL_FILE=my-document.html

# Discover sections
./tools/html-tool.sh sections

# Extract a section to edit in isolation
./tools/html-tool.sh extract my-section-id > /tmp/section.html
# ... edit /tmp/section.html ...
./tools/html-tool.sh replace my-section-id /tmp/section.html

# Validate structural integrity (do this after EVERY edit)
python3 tools/validate.py my-document.html

# Preview in browser
./tools/html-tool.sh preview
```

## Design principles

1. **Self-contained.** All CSS and JS inline. No external fonts, no CDN, no
   framework. A finished artifact is a single `.html` file you can email,
   commit, or open from the filesystem.
2. **Dark-first.** Default palette is dark; light mode is a class override with
   higher-contrast accents. Persists via localStorage.
3. **Taxonomic navigation.** Sections are numbered (§1, §1.1, §1.1.1) so they
   can be referenced by ID, not just scrolled to.
4. **Section-based editing.** Large documents are edited by extracting a section,
   modifying it in isolation, and replacing it — never by rewriting the full
   file. This is enforced by tooling, not discipline.
5. **Validation after every edit.** A single unclosed `</div>` cascades silently
   through thousands of lines. The validator catches what humans and LLMs miss.

## Why this exists

We maintained a 4,460-line interactive decision document across 20+ editing
sessions — interactive calculators, SVG flow diagrams, collapsible option cards,
step navigators, and live comparison tables. The methodology in `STANDARD.md`
is what made that possible without the document ever breaking.

The gallery at [thariqs.github.io/html-effectiveness](https://thariqs.github.io/html-effectiveness/)
shows what HTML can do. This repo teaches how to do it at scale.

## License

MIT — see [`LICENSE`](./LICENSE).
