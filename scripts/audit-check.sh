#!/usr/bin/env bash
# Deterministic .audit checklist gate. Parses the Markdown requirement table and
# lists rows not yet implemented/verified or lacking evidence. Read-only.
#
# Usage: audit-check.sh <path-to-audit.md>
# Exit 0 when every requirement row is closed; exit 1 when any row is open.
set -u

file="${1:-}"
[ -n "$file" ] && [ -f "$file" ] || { echo "usage: audit-check.sh <audit.md>" >&2; exit 2; }

awk -F'|' '
function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
/^\|/ {
	# skip header and separator rows
	c1=trim($2)
	if (c1=="#" || c1 ~ /^:?-+:?$/) next
	if (NF < 7) next
	req=trim($3); impl=tolower(trim($4)); ver=tolower(trim($5)); ev=trim($6)
	open=0
	if (impl!="yes") open=1
	if (ver!="yes") open=1
	if (ev=="" || ev=="—" || ev=="-") open=1
	total++
	if (open){ gaps++; printf "OPEN #%s: %s [impl=%s ver=%s ev=%s]\n", c1, req, impl, ver, ev }
}
END {
	printf "rows=%d open=%d\n", total+0, gaps+0
	if (gaps>0) exit 1
	exit 0
}' "$file"