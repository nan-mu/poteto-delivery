#!/usr/bin/env bash
# Test C: implementation passes its tests but misses a task-book requirement.
# The .audit gate must flag the gap (green tests are not requirement closure),
# then the fix closes it. Local only, no network.
set -u
HERE=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
ok(){ echo "PASS: $1"; pass=$((pass+1)); }
no(){ echo "FAIL: $1"; fail=$((fail+1)); }

git -C "$tmp" init -q -b main
# Partial implementation: satisfies req 1 (bounding) but NOT req 2 (ValueError).
cat > "$tmp/clamp.py" <<'EOF'
def clamp(value, lo, hi):
    return min(max(value, lo), hi)
EOF
# Tests only exercise req 1, so the suite is green despite the missing req 2.
cat > "$tmp/test_clamp.py" <<'EOF'
from clamp import clamp
def test_mid(): assert clamp(5,0,10)==5
def test_below(): assert clamp(-1,0,10)==0
def test_above(): assert clamp(99,0,10)==10
EOF
cat > "$tmp/audit.md" <<'EOF'
# Audit: clamp-dev
| # | Requirement | Implemented | Verified | Evidence | Open issue |
|---|---|---|---|---|---|
| 1 | bound value to [lo,hi] | yes | yes | test_clamp.py::test_mid | — |
| 2 | raise ValueError when lo>hi | no | no | — | requirement missed |
EOF

PY=$(command -v python3 || command -v python)
if [ -n "$PY" ] && "$PY" -c 'import pytest' 2>/dev/null; then
	( cd "$tmp" && "$PY" -m pytest -q >/dev/null 2>&1 ) && ok "C: suite is green on the partial impl" || no "C: suite green on partial impl"
else
	echo "SKIP: C pytest-green check (no pytest in this interpreter)"
fi
# The audit gate must catch the missed requirement even though tests pass.
"$HERE/scripts/audit-check.sh" "$tmp/audit.md" 2>/dev/null | grep -q 'OPEN #2' && ok "C: audit flags missed req despite green tests" || no "C: audit flags missed req"
"$HERE/scripts/audit-check.sh" "$tmp/audit.md" >/dev/null 2>&1; [ $? -eq 1 ] && ok "C: audit gate blocks completion (exit 1)" || no "C: audit gate blocks completion"

# Drive the fix: add the guard + its test, close the audit row.
cat > "$tmp/clamp.py" <<'EOF'
def clamp(value, lo, hi):
    if lo > hi:
        raise ValueError("invalid range")
    return min(max(value, lo), hi)
EOF
cat >> "$tmp/test_clamp.py" <<'EOF'
def test_inverted():
    try:
        clamp(1, 10, 0); assert False
    except ValueError: pass
EOF
sed -i.bak 's#| 2 | raise ValueError when lo>hi | no | no | — | requirement missed |#| 2 | raise ValueError when lo>hi | yes | yes | test_clamp.py::test_inverted | — |#' "$tmp/audit.md"
"$HERE/scripts/audit-check.sh" "$tmp/audit.md" >/dev/null 2>&1; [ $? -eq 0 ] && ok "C: audit closes after the fix (exit 0)" || no "C: audit closes after fix"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]