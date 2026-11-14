#!/usr/bin/env bash
# Deterministic .audit checklist gate. Parses the Markdown requirement table and
# lists rows not yet implemented/verified or lacking evidence. Read-only.
#
# Usage: audit-check.sh <path-to-audit.md>
# Exit 0 when every requirement row is closed.
# Exit 1 when a row is open, or when the file has no recognizable checklist.
# Exit 2 when the file is missing.
set -u

file="${1:-}"
[ -n "$file" ] && [ -f "$file" ] || { echo "usage: audit-check.sh <audit.md>" >&2; exit 2; }

awk -F'|' '
function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
function is_sep(s) { return (s ~ /^:?-+:?$/) }
BEGIN { seen = 0; rows = 0; gaps = 0; short = 0; opens = "" }
/^\|/ {
  n = 0
  for (i = 1; i <= NF; i++) {
    raw = trim($i)
    if ((i == 1 || i == NF) && raw == "") continue
    n++
    cell[n] = raw
  }
  if (n == 0) next
  if (is_sep(cell[1])) next
  if (n >= 5 && cell[1] == "#" && tolower(cell[2]) ~ /^requirement([^a-z]|$)/ && tolower(cell[3]) ~ /^implemented([^a-z]|$)/ && tolower(cell[4]) ~ /^verified([^a-z]|$)/ && tolower(cell[5]) ~ /^evidence([^a-z]|$)/) {
    seen = 1
    next
  }
  if (!seen) next
  if (n < 6) { short = 1; next }
  impl = tolower(cell[3])
  ver = tolower(cell[4])
  ev = cell[5]
  open = 0
  if (impl != "yes") open = 1
  if (ver != "yes") open = 1
  if (ev == "" || ev == "—" || ev == "-") open = 1
  rows++
  if (open) {
    gaps++
    opens = opens sprintf("OPEN #%s: %s [impl=%s ver=%s ev=%s]\n", cell[1], cell[2], impl, ver, ev)
  }
}
END {
  if (!seen) { print "INVALID: no requirement header"; exit 1 }
  if (short) { print "INVALID: short row"; exit 1 }
  if (rows == 0) { print "INVALID: no requirement rows"; exit 1 }
  printf "%s", opens
  printf "rows=%d open=%d\n", rows, gaps
  if (gaps > 0) exit 1
  exit 0
}' "$file"
