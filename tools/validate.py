#!/usr/bin/env python3
"""
validate.py — General-purpose HTML structure validation.

Checks:
  - Total <div> and </div> counts match
  - Depth never goes negative at any line
  - Common block elements are properly closed (<details>, <section>, <article>,
    <aside>, <nav>, <main>, <header>, <footer>, <figure>, <dialog>, <template>)
  - Elements with id attributes have matching closing tags

Usage as standalone:
    python3 validate.py <file.html>

Usage as module:
    from validate import validate_html
    issues = validate_html("path/to/file.html")
    # issues is a list of strings; empty means clean
"""
import re
import sys

# Block-level elements worth tracking for unclosed-tag detection.
# Excludes void elements and ubiquitous inlines.
TRACKED_ELEMENTS = {
    'details', 'section', 'article', 'aside', 'nav', 'main',
    'header', 'footer', 'figure', 'dialog', 'template', 'fieldset',
    'blockquote', 'table', 'thead', 'tbody', 'tfoot', 'tr',
}

_OPEN_RE = re.compile(r'<(\w+)\b[^>]*/?>?', re.IGNORECASE)
_CLOSE_RE = re.compile(r'</(\w+)\s*>', re.IGNORECASE)
_SELF_CLOSE_RE = re.compile(r'<\w+\b[^>]*/>', re.IGNORECASE)
_ID_RE = re.compile(r'<(\w+)\b[^>]*\bid=["\'][^"\']*["\'][^>]*>', re.IGNORECASE)

# HTML void elements — self-closing by spec, never have a closing tag.
VOID_ELEMENTS = {
    'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input',
    'link', 'meta', 'param', 'source', 'track', 'wbr',
}
_DIV_OPEN = re.compile(r'<div\b')
_DIV_CLOSE = re.compile(r'</div>')


def validate_html(filepath):
    """Validate HTML structure.

    Returns (issues, stats) where issues is a list of strings (empty = clean)
    and stats is a dict of counters.
    """
    with open(filepath) as f:
        lines = f.readlines()

    issues = []

    # --- Pass 1: div balance and depth ---
    depth = 0
    max_depth = 0
    total_opens = 0
    total_closes = 0

    for i, line in enumerate(lines, start=1):
        opens = len(_DIV_OPEN.findall(line))
        closes = len(_DIV_CLOSE.findall(line))
        total_opens += opens
        total_closes += closes
        depth += opens - closes
        if depth > max_depth:
            max_depth = depth
        if depth < 0:
            issues.append(f"Line {i}: div depth went negative ({depth})")

    if total_opens != total_closes:
        issues.append(
            f"Div imbalance: {total_opens} opens vs {total_closes} closes "
            f"(delta: {total_opens - total_closes:+d})"
        )

    # --- Pass 2: tracked block elements ---
    tag_stacks = {}  # tag_name -> list of (line_number,)
    for tag in TRACKED_ELEMENTS:
        tag_stacks[tag] = []

    for i, line in enumerate(lines, start=1):
        # Skip self-closing tags
        clean = _SELF_CLOSE_RE.sub('', line)

        for m in _OPEN_RE.finditer(clean):
            tag = m.group(1).lower()
            if tag in tag_stacks:
                # Verify it's not self-closed in the original match
                if not m.group(0).rstrip().endswith('/>'):
                    tag_stacks[tag].append(i)

        for m in _CLOSE_RE.finditer(clean):
            tag = m.group(1).lower()
            if tag in tag_stacks:
                if tag_stacks[tag]:
                    tag_stacks[tag].pop()
                else:
                    issues.append(f"Line {i}: extra </{tag}> with no matching open")

    for tag, stack in tag_stacks.items():
        for line_num in stack:
            issues.append(f"Line {line_num}: unclosed <{tag}>")

    # --- Pass 3: id-bearing elements have closing tags ---
    id_stacks = {}  # tag_name -> list of (line_number, id_value)

    for i, line in enumerate(lines, start=1):
        clean = _SELF_CLOSE_RE.sub('', line)

        for m in _ID_RE.finditer(clean):
            tag = m.group(1).lower()
            if tag in VOID_ELEMENTS:
                continue
            id_val = re.search(r'\bid=["\']([^"\']*)["\']', m.group(0))
            if id_val and not m.group(0).rstrip().endswith('/>'):
                id_stacks.setdefault(tag, []).append((i, id_val.group(1)))

        for m in _CLOSE_RE.finditer(clean):
            tag = m.group(1).lower()
            if tag in id_stacks and id_stacks[tag]:
                id_stacks[tag].pop()

    for tag, stack in id_stacks.items():
        for line_num, id_val in stack:
            issues.append(f"Line {line_num}: element <{tag} id=\"{id_val}\"> not closed")

    stats = {
        'total_opens': total_opens,
        'total_closes': total_closes,
        'max_depth': max_depth,
        'final_depth': depth,
        'total_lines': len(lines),
        'issue_count': len(issues),
    }

    return issues, stats


def print_report(filepath):
    """Run validation and print a human-readable report. Returns exit code."""
    issues, stats = validate_html(filepath)

    print(f"=== HTML Validation: {filepath} ===")
    print(f"  Total lines:  {stats['total_lines']}")
    print(f"  Div opens:    {stats['total_opens']}")
    print(f"  Div closes:   {stats['total_closes']}")
    print(f"  Max depth:    {stats['max_depth']}")
    print(f"  Final depth:  {stats['final_depth']}")
    print()

    if issues:
        print(f"ISSUES FOUND ({len(issues)}):")
        for issue in issues:
            print(f"  x {issue}")
        return 1
    else:
        print("OK — all checks passed.")
        return 0


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python3 validate.py <file.html>")
        sys.exit(1)
    sys.exit(print_report(sys.argv[1]))
