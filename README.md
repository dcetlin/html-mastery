# HTML Mastery

A small, opinionated canon for generating **self-contained, dark-first HTML
artifacts** — reports, design docs, audits, dashboards, and interactive tools —
with no build step and (almost) no external dependencies.

It is the distillation of patterns proven across many generated documents: a
color-token system, a light/dark toggle, taxonomic section IDs, a clipboard
comment widget, a D3 force-directed concept graph, and a set of conventions for
the Python (or any language) scripts that emit these pages.

The goal is simple: **a new generator should never start from a blank file.**
Pull the tokens, components, and conventions from here so every artifact shares
one visual language and one delivery shape.

## What's in here

| File | What it gives you |
|------|-------------------|
| [`STANDARDS.md`](./STANDARDS.md) | The canon — what makes an artifact good, the two artifact classes (document vs. dashboard), required features, the full color-token system, and a per-artifact checklist. |
| [`patterns.md`](./patterns.md) | The component reference — recurring CSS (cards, badges, tables, stat grids, timelines), the `D_JSON` data-injection pattern, JS helper vocabulary, and generator-script conventions. |
| [`templates/document.template.html`](./templates/document.template.html) | A complete, self-contained document-class skeleton with the token system, theme toggle, and comment widget already wired in. Copy it and fill in content. |

## Design principles

1. **Self-contained.** All CSS and JS inline. No external fonts, no CSS
   frameworks, no CDN — except D3.js when (and only when) you render a concept
   graph. A finished artifact is a single `.html` file you can open anywhere.
2. **Dark-first, readable.** The default palette is dark; light mode is a class
   override that bumps accent contrast. Typography optimized for sustained
   reading.
3. **Taxonomic navigation.** Sections are numbered (§1, §1.1) so they can be
   referenced by ID in conversation, not just scrolled to.
4. **Pure generators.** The script that emits the HTML is a pure
   function: data in, HTML string out, no I/O. Delivery (writing the file,
   hosting it) is a separate, swappable concern.
5. **Data injection over AJAX.** Page data is serialized once into a single JSON
   blob (`D`) injected at generation time. The page never calls back to a server.

## Quick start

1. Copy `templates/document.template.html` to a new file.
2. Replace the title/subtitle and add your `<div class="section" id="sN">` blocks.
3. Update the `sections[]` array in the inline script so the comment widget
   matches your sections.
4. (Optional) If your document defines a vocabulary with relationships, add the
   D3 concept graph from `STANDARDS.md` §6.
5. Open the file. That's the whole build.

## A note on delivery

These artifacts are just static HTML files, so any static host works: open
locally, drop on object storage, serve from a tiny HTTP file server, or commit
to a static site. The generator conventions in `patterns.md` keep generation
(pure) and delivery (I/O) separate so you can swap delivery without touching the
rendering logic.

## License

MIT — see [`LICENSE`](./LICENSE).
