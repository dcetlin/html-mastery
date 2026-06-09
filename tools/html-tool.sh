#!/usr/bin/env bash
# html-tool.sh — Section-aware HTML editor for large single-file HTML artifacts.
#
# Works with any HTML file that uses `id` attributes on div/section elements.
# Provides structural navigation, extraction, replacement, and validation
# without requiring a DOM parser — just bash and grep.
#
# The load-bearing algorithm is find_closing_div: it tracks div open/close
# depth to find the matching </div> for any opening <div>, which lets every
# other command resolve arbitrary id-based sections to line ranges.
#
# Usage: ./html-tool.sh <command> [args...]
# Run ./html-tool.sh help for full usage.

set -euo pipefail

# --- Configuration -----------------------------------------------------------

HTML_FILE="${HTML_TOOL_FILE:-}"

# --- Helpers -----------------------------------------------------------------

die() { printf 'error: %s\n' "$1" >&2; exit 1; }

# Count occurrences of a pattern in a string. Returns 0 if no match.
# This wrapper exists because grep -o | wc -l fails under set -eo pipefail
# when grep finds no matches (exit code 1 propagates through the pipeline).
count_pattern() {
  local pattern="$1" text="$2"
  local result
  result=$(grep -o "$pattern" <<< "$text" 2>/dev/null | wc -l | tr -d ' ') || result=0
  echo "$result"
}

require_file() {
  [[ -n "$HTML_FILE" ]] || die "No HTML file specified. Set HTML_TOOL_FILE or export it."
  [[ -f "$HTML_FILE" ]] || die "HTML file not found: $HTML_FILE"
}

# Find the closing line for a div that opens at $1 (line number).
# Uses div depth tracking: counts <div> opens and </div> closes.
# Prints the line number of the </div> that balances the opening div.
find_closing_div() {
  local start_line="$1"
  local depth=0
  local lineno=0

  while IFS= read -r line; do
    lineno=$((lineno + 1))
    [[ $lineno -lt $start_line ]] && continue

    # Count div opens and closes on this line
    local opens closes
    opens=$(count_pattern '<div\b' "$line")
    closes=$(count_pattern '</div>' "$line")
    depth=$((depth + opens - closes))

    if [[ $depth -le 0 && $lineno -gt $start_line ]]; then
      echo "$lineno"
      return 0
    fi
  done < "$HTML_FILE"

  echo ""
  return 1
}

# Find the opening line number for an element with the given id attribute.
find_element_by_id() {
  local target_id="$1"
  local lineno
  lineno=$(grep -n "id=\"${target_id}\"" "$HTML_FILE" | head -1 | cut -d: -f1)
  [[ -n "$lineno" ]] || return 1
  echo "$lineno"
}

# Resolve a section identifier (an id attribute value) to start_line end_line.
resolve_section() {
  local identifier="$1"

  local start_line
  if start_line=$(find_element_by_id "$identifier" 2>/dev/null); then
    local end_line
    end_line=$(find_closing_div "$start_line")
    [[ -n "$end_line" ]] || die "Could not find closing </div> for id=\"$identifier\" (opened at line $start_line)"
    echo "$start_line $end_line"
    return 0
  fi

  die "No element found with id=\"$identifier\".
Run './html-tool.sh sections' to see available IDs."
}

# --- Commands ----------------------------------------------------------------

cmd_help() {
  cat <<'HELPTEXT'
html-tool.sh — Section-aware HTML editor for large single-file artifacts

Navigates, extracts, replaces, and validates sections of an HTML file
using id attributes as anchors and div-depth tracking to find boundaries.

SYNOPSIS
  ./html-tool.sh <command> [args...]

COMMANDS
  sections [--hierarchical]
                        List all elements with id attributes (tag, class, line range).
                        --hierarchical (-H): indent children under parents by nesting depth.
  stats                 Show line counts per id-bearing section
  extract <id>          Extract a section by its id attribute value
  replace <id> <file>   Replace a section's content with contents of <file>
  inject-svg <id> <svg> Replace a container's inner content with an SVG file
  validate              Check HTML structure (delegates to validate.py when available,
                        falls back to inline div-balance check otherwise)
  preview               Open the HTML file in the default browser
  help                  Show this help message

ENVIRONMENT
  HTML_TOOL_FILE    Path to the HTML file to operate on (required).
                    No default — must be set before running.

EXAMPLES
  export HTML_TOOL_FILE=./my-dashboard.html

  ./html-tool.sh sections
  ./html-tool.sh sections --hierarchical
  ./html-tool.sh extract main-content
  ./html-tool.sh stats
  ./html-tool.sh replace sidebar updated-sidebar.html
  ./html-tool.sh inject-svg chart-panel flow.svg
  ./html-tool.sh validate
  ./html-tool.sh preview
HELPTEXT
}

cmd_sections() {
  local hierarchical=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --hierarchical|-H) hierarchical=1; shift ;;
      *) die "Unknown option for sections: $1" ;;
    esac
  done

  require_file

  if [[ $hierarchical -eq 1 ]]; then
    cmd_sections_hierarchical
    return
  fi

  printf '%-6s  %-40s  %-30s  %s\n' "TAG" "ID" "CLASS" "LINES"
  printf '%-6s  %-40s  %-30s  %s\n' "---" "--" "-----" "-----"

  grep -n 'id="[^"]*"' "$HTML_FILE" | while IFS=: read -r lineno rest; do
    # Extract the id value
    local elem_id
    elem_id=$(echo "$rest" | grep -o 'id="[^"]*"' | head -1 | sed 's/id="//;s/"//')
    [[ -n "$elem_id" ]] || continue

    # Extract the tag name (first < on the line)
    local tag
    tag=$(echo "$rest" | grep -o '<[a-zA-Z][a-zA-Z0-9]*' | head -1 | sed 's/<//')
    [[ -n "$tag" ]] || tag="?"

    # Extract class if present
    local cls
    cls=$(echo "$rest" | grep -o 'class="[^"]*"' | head -1 | sed 's/class="//;s/"//' || true)

    # Try to find closing div for div/section elements
    local line_range="line $lineno"
    if [[ "$tag" == "div" || "$tag" == "section" || "$tag" == "article" || "$tag" == "main" || "$tag" == "aside" || "$tag" == "nav" || "$tag" == "header" || "$tag" == "footer" ]]; then
      local end_line
      end_line=$(find_closing_div "$lineno" 2>/dev/null || true)
      if [[ -n "$end_line" ]]; then
        local count=$((end_line - lineno + 1))
        line_range="${lineno}-${end_line} (${count} lines)"
      fi
    fi

    printf '%-6s  %-40s  %-30s  %s\n' "$tag" "$elem_id" "${cls:--}" "$line_range"
  done
}

# Hierarchical sections view: indents child sections under parents based on
# div nesting depth. Scans the file line-by-line tracking depth so each
# id-bearing element gets an accurate nesting level.
cmd_sections_hierarchical() {
  require_file

  # Collect all id-bearing elements with their div depth at the point they appear.
  # We scan the file once, tracking cumulative div depth.
  local depth=0
  local lineno=0
  local entries=()

  while IFS= read -r line; do
    lineno=$((lineno + 1))

    # Count opens/closes on this line. Opens are counted before we check for ids
    # so the element's own opening tag contributes to its depth.
    local opens closes
    opens=$(count_pattern '<div\b' "$line")
    closes=$(count_pattern '</div>' "$line")

    # Check for id attribute before updating depth for closes
    # (the element belongs at the depth after its own open)
    depth=$((depth + opens))

    if echo "$line" | grep -q 'id="[^"]*"'; then
      local elem_id tag cls
      elem_id=$(echo "$line" | grep -o 'id="[^"]*"' | head -1 | sed 's/id="//;s/"//')
      tag=$(echo "$line" | grep -o '<[a-zA-Z][a-zA-Z0-9]*' | head -1 | sed 's/<//')
      cls=$(echo "$line" | grep -o 'class="[^"]*"' | head -1 | sed 's/class="//;s/"//' || true)

      if [[ -n "$elem_id" && -n "$tag" ]]; then
        # Store entry as depth|lineno|tag|id|class
        entries+=("${depth}|${lineno}|${tag}|${elem_id}|${cls:--}")
      fi
    fi

    depth=$((depth - closes))
    if [[ $depth -lt 0 ]]; then
      depth=0
    fi
  done < "$HTML_FILE"

  # Find the minimum depth to use as baseline for indentation
  local min_depth=999
  for entry in "${entries[@]}"; do
    local d
    d=$(echo "$entry" | cut -d'|' -f1)
    if [[ $d -lt $min_depth ]]; then
      min_depth=$d
    fi
  done

  # Print with indentation
  printf '%-60s  %-6s  %s\n' "ID (hierarchical)" "TAG" "LINES"
  printf '%-60s  %-6s  %s\n' "------------------" "---" "-----"

  for entry in "${entries[@]}"; do
    local d elem_lineno tag elem_id cls
    d=$(echo "$entry" | cut -d'|' -f1)
    elem_lineno=$(echo "$entry" | cut -d'|' -f2)
    tag=$(echo "$entry" | cut -d'|' -f3)
    elem_id=$(echo "$entry" | cut -d'|' -f4)
    cls=$(echo "$entry" | cut -d'|' -f5)

    local indent_level=$((d - min_depth))
    local indent=""
    local i=0
    while [[ $i -lt $indent_level ]]; do
      indent="${indent}  "
      i=$((i + 1))
    done

    # Compute line range for container elements
    local line_range="line $elem_lineno"
    if [[ "$tag" == "div" || "$tag" == "section" || "$tag" == "article" || "$tag" == "main" || "$tag" == "aside" || "$tag" == "nav" || "$tag" == "header" || "$tag" == "footer" ]]; then
      local end_line
      end_line=$(find_closing_div "$elem_lineno" 2>/dev/null || true)
      if [[ -n "$end_line" ]]; then
        local count=$((end_line - elem_lineno + 1))
        line_range="${elem_lineno}-${end_line} (${count} lines)"
      fi
    fi

    local display_id="${indent}${elem_id}"
    printf '%-60s  %-6s  %s\n' "$display_id" "$tag" "$line_range"
  done
}

cmd_stats() {
  require_file
  local total
  total=$(wc -l < "$HTML_FILE" | tr -d ' ')
  printf 'Total: %s lines\n\n' "$total"
  printf '%-44s  %6s  %s\n' "SECTION (id)" "LINES" "BAR"
  printf '%-44s  %6s  %s\n' "------------" "-----" "---"

  # All div/section elements with id attributes
  grep -n 'id="[^"]*"' "$HTML_FILE" | while IFS=: read -r lineno rest; do
    local tag
    tag=$(echo "$rest" | grep -o '<[a-zA-Z][a-zA-Z0-9]*' | head -1 | sed 's/<//')
    [[ "$tag" == "div" || "$tag" == "section" || "$tag" == "article" || "$tag" == "main" || "$tag" == "aside" || "$tag" == "nav" || "$tag" == "header" || "$tag" == "footer" ]] || continue

    local elem_id
    elem_id=$(echo "$rest" | grep -o 'id="[^"]*"' | head -1 | sed 's/id="//;s/"//')
    [[ -n "$elem_id" ]] || continue

    local end_line
    end_line=$(find_closing_div "$lineno" 2>/dev/null || true)
    [[ -n "$end_line" ]] || continue

    local count=$((end_line - lineno + 1))
    local bar_len=$(( count / 10 ))
    [[ $bar_len -lt 1 ]] && bar_len=1
    [[ $bar_len -gt 60 ]] && bar_len=60
    local bar
    bar=$(printf '%*s' "$bar_len" '' | tr ' ' '#')
    printf '%-44s  %6s  %s\n' "$elem_id" "$count" "$bar"
  done

  # Style and script blocks
  printf '\n%-44s  %6s\n' "SPECIAL BLOCKS" "LINES"
  printf '%-44s  %6s\n' "--------------" "-----"

  local style_start style_end
  style_start=$(grep -n '<style' "$HTML_FILE" | head -1 | cut -d: -f1 || true)
  style_end=$(grep -n '</style>' "$HTML_FILE" | head -1 | cut -d: -f1 || true)
  if [[ -n "$style_start" && -n "$style_end" ]]; then
    printf '%-44s  %6s\n' "<style>" "$((style_end - style_start + 1))"
  fi

  local script_start script_end
  script_start=$(grep -n '<script' "$HTML_FILE" | tail -1 | cut -d: -f1 || true)
  script_end=$(grep -n '</script>' "$HTML_FILE" | tail -1 | cut -d: -f1 || true)
  if [[ -n "$script_start" && -n "$script_end" ]]; then
    printf '%-44s  %6s\n' "<script>" "$((script_end - script_start + 1))"
  fi
}

cmd_extract() {
  local identifier="${1:-}"
  [[ -n "$identifier" ]] || die "Usage: html-tool.sh extract <id>"
  require_file

  local range
  range=$(resolve_section "$identifier")
  local start_line end_line
  start_line=$(echo "$range" | cut -d' ' -f1)
  end_line=$(echo "$range" | cut -d' ' -f2)

  local count=$((end_line - start_line + 1))
  printf '# Extracted: %s (lines %s-%s, %s lines)\n' "$identifier" "$start_line" "$end_line" "$count" >&2
  sed -n "${start_line},${end_line}p" "$HTML_FILE"
}

cmd_replace() {
  local identifier="${1:-}"
  local content_file="${2:-}"
  [[ -n "$identifier" ]] || die "Usage: html-tool.sh replace <id> <content-file>"
  [[ -n "$content_file" ]] || die "Usage: html-tool.sh replace <id> <content-file>"
  [[ -f "$content_file" ]] || die "Content file not found: $content_file"
  require_file

  local range
  range=$(resolve_section "$identifier")
  local start_line end_line
  start_line=$(echo "$range" | cut -d' ' -f1)
  end_line=$(echo "$range" | cut -d' ' -f2)

  local count=$((end_line - start_line + 1))
  local total_before
  total_before=$(wc -l < "$HTML_FILE" | tr -d ' ')
  local new_content_lines
  new_content_lines=$(wc -l < "$content_file" | tr -d ' ')

  # Create backup
  cp "$HTML_FILE" "${HTML_FILE}.bak"

  # Build the new file: head + new content + tail
  local tmpfile
  tmpfile=$(mktemp)
  head -n "$((start_line - 1))" "$HTML_FILE" > "$tmpfile"
  cat "$content_file" >> "$tmpfile"
  tail -n "+$((end_line + 1))" "$HTML_FILE" >> "$tmpfile"
  mv "$tmpfile" "$HTML_FILE"

  local total_after
  total_after=$(wc -l < "$HTML_FILE" | tr -d ' ')
  local delta=$((total_after - total_before))

  printf 'Replaced %s (was lines %s-%s, %s lines)\n' "$identifier" "$start_line" "$end_line" "$count"
  printf 'New content: %s lines (delta: %+d)\n' "$new_content_lines" "$delta"
  printf 'Backup: %s.bak\n' "$HTML_FILE"
}

cmd_inject_svg() {
  local target_id="${1:-}"
  local svg_file="${2:-}"
  [[ -n "$target_id" ]] || die "Usage: html-tool.sh inject-svg <id> <svg-file>"
  [[ -n "$svg_file" ]] || die "Usage: html-tool.sh inject-svg <id> <svg-file>"
  [[ -f "$svg_file" ]] || die "SVG file not found: $svg_file"
  require_file

  # Find the target element
  local target_start
  target_start=$(find_element_by_id "$target_id" 2>/dev/null) || die "Element not found: id=\"$target_id\""
  local target_end
  target_end=$(find_closing_div "$target_start")
  [[ -n "$target_end" ]] || die "Could not find closing </div> for id=\"$target_id\""

  local count=$((target_end - target_start + 1))

  # Extract the opening tag line to preserve it
  local opening_line
  opening_line=$(sed -n "${target_start}p" "$HTML_FILE")

  # Create backup
  cp "$HTML_FILE" "${HTML_FILE}.bak"

  # Build replacement: original opening tag + SVG content + closing tag
  local tmpfile replacement_file
  tmpfile=$(mktemp)
  replacement_file=$(mktemp)

  printf '%s\n' "$opening_line" > "$replacement_file"
  cat "$svg_file" >> "$replacement_file"
  printf '    </div>\n' >> "$replacement_file"

  head -n "$((target_start - 1))" "$HTML_FILE" > "$tmpfile"
  cat "$replacement_file" >> "$tmpfile"
  tail -n "+$((target_end + 1))" "$HTML_FILE" >> "$tmpfile"
  mv "$tmpfile" "$HTML_FILE"
  rm -f "$replacement_file"

  printf 'Injected SVG into id="%s" (was lines %s-%s, %s lines)\n' "$target_id" "$target_start" "$target_end" "$count"
  printf 'SVG file: %s\n' "$svg_file"
  printf 'Backup: %s.bak\n' "$HTML_FILE"
}

cmd_validate() {
  require_file
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local validator="${script_dir}/validate.py"

  if [[ -f "$validator" ]] && command -v python3 &>/dev/null; then
    python3 "$validator" "$HTML_FILE"
    return $?
  fi

  # Fallback: inline bash validation if validate.py or Python not available
  printf '=== Div Validation: %s ===\n' "$HTML_FILE"

  local total_opens total_closes
  total_opens=$(grep -c '<div\b' "$HTML_FILE" || true)
  total_closes=$(grep -c '</div>' "$HTML_FILE" || true)
  local total_lines
  total_lines=$(wc -l < "$HTML_FILE" | tr -d ' ')

  local depth=0
  local max_depth=0
  local lineno=0
  local has_issues=0
  local negative_lines=""

  while IFS= read -r line; do
    lineno=$((lineno + 1))
    local opens closes
    opens=$(count_pattern '<div\b' "$line")
    closes=$(count_pattern '</div>' "$line")
    depth=$((depth + opens - closes))
    if [[ $depth -gt $max_depth ]]; then
      max_depth=$depth
    fi
    if [[ $depth -lt 0 ]]; then
      negative_lines="${negative_lines}  Line ${lineno}: depth went negative (${depth})\n"
      has_issues=1
    fi
  done < "$HTML_FILE"

  printf '  Total lines:  %s\n' "$total_lines"
  printf '  Div opens:    %s\n' "$total_opens"
  printf '  Div closes:   %s\n' "$total_closes"
  printf '  Max depth:    %s\n' "$max_depth"
  printf '  Final depth:  %s\n\n' "$depth"

  if [[ "$total_opens" -ne "$total_closes" ]]; then
    printf 'ISSUES FOUND:\n'
    printf '  Div imbalance: %s opens vs %s closes (delta: %+d)\n' "$total_opens" "$total_closes" "$((total_opens - total_closes))"
    has_issues=1
  fi

  if [[ -n "$negative_lines" ]]; then
    [[ $has_issues -eq 0 ]] && printf 'ISSUES FOUND:\n'
    printf '%b' "$negative_lines"
    has_issues=1
  fi

  if [[ $has_issues -eq 0 ]]; then
    printf 'All checks passed — divs are balanced.\n'
    printf '(Install validate.py alongside this script for deeper structural checks.)\n'
  fi

  return $has_issues
}

cmd_preview() {
  require_file
  if command -v open &>/dev/null; then
    open "$HTML_FILE"
    printf 'Opened in default browser: %s\n' "$HTML_FILE"
  elif command -v xdg-open &>/dev/null; then
    xdg-open "$HTML_FILE"
    printf 'Opened in default browser: %s\n' "$HTML_FILE"
  else
    die "No 'open' or 'xdg-open' command found. Open manually: $HTML_FILE"
  fi
}

# --- Main dispatcher ---------------------------------------------------------

main() {
  local cmd="${1:-help}"
  shift 2>/dev/null || true

  case "$cmd" in
    help|--help|-h)     cmd_help ;;
    sections|sec|ls)    cmd_sections "$@" ;;
    stats|st)           cmd_stats ;;
    extract|ex|get)     cmd_extract "$@" ;;
    replace|rep|set)    cmd_replace "$@" ;;
    inject-svg|svg)     cmd_inject_svg "$@" ;;
    validate|val)       cmd_validate ;;
    preview|open|view)  cmd_preview ;;
    *)                  die "Unknown command: $cmd. Run './html-tool.sh help' for usage." ;;
  esac
}

main "$@"
