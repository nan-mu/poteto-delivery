#!/usr/bin/env bash
# Isolation and fail-closed gates. Local temp repos only. No network.
set -u
HERE=$(cd "$(dirname "$0")/.." && pwd)
V="$HERE/scripts/verify-workspace.sh"
A="$HERE/scripts/audit-check.sh"
pass=0
fail=0
ok() { echo "PASS: $1"; pass=$((pass + 1)); }
no() { echo "FAIL: $1"; fail=$((fail + 1)); }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

line_is() {
  printf '%s\n' "$1" | grep -qx "$2"
}

cat > "$tmp/header-only.md" <<'EOF'
| # | Requirement | Implemented | Verified | Evidence | Open issue |
|---|---|---|---|---|---|
EOF
header_out=$("$A" "$tmp/header-only.md" 2>&1) || header_ec=$?
header_ec=${header_ec:-0}
if [ "$header_ec" -ne 0 ] && printf '%s\n' "$header_out" | grep -q 'INVALID' && ! printf '%s\n' "$header_out" | grep -q 'rows=0 open=0'; then
  ok "header-only audit is invalid"
else
  no "header-only audit is invalid ec=$header_ec out=$(printf '%s' "$header_out" | tr '\n' ' ')"
fi

printf 'This file is prose and has no requirement table.\n' > "$tmp/prose.md"
prose_out=$("$A" "$tmp/prose.md" 2>&1) || prose_ec=$?
prose_ec=${prose_ec:-0}
if [ "$prose_ec" -ne 0 ] && printf '%s\n' "$prose_out" | grep -q 'INVALID' && ! printf '%s\n' "$prose_out" | grep -q 'rows=0 open=0'; then
  ok "prose audit is invalid"
else
  no "prose audit is invalid ec=$prose_ec out=$(printf '%s' "$prose_out" | tr '\n' ' ')"
fi

: > "$tmp/empty.md"
empty_out=$("$A" "$tmp/empty.md" 2>&1) || empty_ec=$?
empty_ec=${empty_ec:-0}
if [ "$empty_ec" -ne 0 ] && printf '%s\n' "$empty_out" | grep -q 'INVALID'; then
  ok "empty audit is invalid"
else
  no "empty audit is invalid ec=$empty_ec out=$(printf '%s' "$empty_out" | tr '\n' ' ')"
fi

cat > "$tmp/narrow.md" <<'EOF'
| Topic | Status |
| --- | --- |
| isolation | done |
EOF
narrow_out=$("$A" "$tmp/narrow.md" 2>&1) || narrow_ec=$?
narrow_ec=${narrow_ec:-0}
if [ "$narrow_ec" -ne 0 ] && printf '%s\n' "$narrow_out" | grep -q 'INVALID'; then
  ok "narrow pipe table is invalid"
else
  no "narrow pipe table is invalid ec=$narrow_ec out=$(printf '%s' "$narrow_out" | tr '\n' ' ')"
fi

cat > "$tmp/short.md" <<'EOF'
| # | Requirement | Implemented | Verified | Evidence | Open issue |
|---|---|---|---|---|---|
| 1 | closed req | yes | yes | foo.sh:1 | - |
| 2 | short | yes |
EOF
short_out=$("$A" "$tmp/short.md" 2>&1) || short_ec=$?
short_ec=${short_ec:-0}
if [ "$short_ec" -ne 0 ] && printf '%s\n' "$short_out" | grep -q 'INVALID'; then
  ok "short audit row is invalid"
else
  no "short audit row is invalid ec=$short_ec out=$(printf '%s' "$short_out" | tr '\n' ' ')"
fi

cat > "$tmp/closed.md" <<'EOF'
| # | Requirement | Implemented | Verified | Evidence | Open issue |
|---|---|---|---|---|---|
| 1 | closed req | yes | yes | foo.sh:1 | - |
EOF
"$A" "$tmp/closed.md" >/dev/null 2>&1
closed_ec=$?
if [ "$closed_ec" -eq 0 ]; then
  ok "closed audit exits 0"
else
  no "closed audit exits 0 ec=$closed_ec"
fi

cat > "$tmp/case.md" <<'EOF'
| # | requirement | Implemented | verified | EVIDENCE | Notes |
|---|---|---|---|---|---|
| 1 | closed req | yes | yes | foo.sh:1 | - |
EOF
"$A" "$tmp/case.md" >/dev/null 2>&1
case_ec=$?
if [ "$case_ec" -eq 0 ]; then
  ok "header match is case-insensitive"
else
  no "header match is case-insensitive ec=$case_ec"
fi

cat > "$tmp/open.md" <<'EOF'
| # | Requirement | Implemented | Verified | Evidence | Open issue |
|---|---|---|---|---|---|
| 1 | closed req | yes | yes | foo.sh:1 | - |
| 2 | open req | no | no | - | - |
EOF
open_out=$("$A" "$tmp/open.md" 2>&1) || open_ec=$?
open_ec=${open_ec:-0}
if [ "$open_ec" -eq 1 ] && printf '%s\n' "$open_out" | grep -q 'OPEN #2' && ! printf '%s\n' "$open_out" | grep -q 'INVALID'; then
  ok "open audit row exits 1"
else
  no "open audit row exits 1 ec=$open_ec out=$(printf '%s' "$open_out" | tr '\n' ' ')"
fi

"$A" "$tmp/missing-audit.md" >/dev/null 2>&1
missing_ec=$?
if [ "$missing_ec" -eq 2 ]; then
  ok "missing audit exits 2"
else
  no "missing audit exits 2 ec=$missing_ec"
fi

cat > "$tmp/paren.md" <<'EOF'
| # | Requirement (from task book) | Implemented | Verified | Evidence (code/test/artifact) | Open issue |
|---|------------------------------|-------------|----------|-------------------------------|------------|
| 1 | closed req | yes | yes | foo.sh:1 | - |
EOF
"$A" "$tmp/paren.md" >/dev/null 2>&1
paren_ec=$?
if [ "$paren_ec" -eq 0 ]; then
  ok "parenthetical header still closes"
else
  no "parenthetical header still closes ec=$paren_ec"
fi

cat > "$tmp/paren-only.md" <<'EOF'
| # | Requirement (from task book) | Implemented | Verified | Evidence (code/test/artifact) | Open issue |
|---|------------------------------|-------------|----------|-------------------------------|------------|
EOF
paren_only_out=$("$A" "$tmp/paren-only.md" 2>&1) || paren_only_ec=$?
paren_only_ec=${paren_only_ec:-0}
if [ "$paren_only_ec" -ne 0 ] && printf '%s\n' "$paren_only_out" | grep -q 'INVALID'; then
  ok "parenthetical header with no rows is invalid"
else
  no "parenthetical header with no rows is invalid ec=$paren_only_ec out=$(printf '%s' "$paren_only_out" | tr '\n' ' ')"
fi

repo="$tmp/repo"
mkdir -p "$repo"
git -C "$repo" init -q -b main
git -C "$repo" config user.email test@example.com
git -C "$repo" config user.name test
printf 'seed\n' > "$repo/seed.txt"
git -C "$repo" add seed.txt
git -C "$repo" commit -q -m init
main_bytes='main-uncommitted-9f3a'
printf '%s' "$main_bytes" > "$repo/dirty.txt"
before_worktree=$(cksum "$repo/dirty.txt")
git -C "$repo" worktree add -q -b agent/iso-a "$tmp/wt-a" main
git -C "$repo" worktree add -q -b agent/iso-b "$tmp/wt-b" main
after_worktree=$(cksum "$repo/dirty.txt")
if [ "$before_worktree" = "$after_worktree" ] && [ ! -e "$tmp/wt-a/dirty.txt" ] && [ ! -e "$tmp/wt-b/dirty.txt" ]; then
  ok "main uncommitted bytes stay put and are not copied"
else
  no "main uncommitted bytes stay put and are not copied"
fi

bytes_a='bytes-A-only'
bytes_b='bytes-B-only'
printf '%s' "$bytes_a" > "$tmp/wt-a/only-a.bin"
printf '%s' "$bytes_b" > "$tmp/wt-b/only-b.bin"
if [ ! -e "$tmp/wt-b/only-a.bin" ] && [ ! -e "$tmp/wt-a/only-b.bin" ] \
  && [ "$(cat "$tmp/wt-a/only-a.bin")" = "$bytes_a" ] \
  && [ "$(cat "$tmp/wt-b/only-b.bin")" = "$bytes_b" ]; then
  ok "worktree files do not appear in the other tree"
else
  no "worktree files do not appear in the other tree"
fi

wt_a_real=$(realpath "$tmp/wt-a")
wt_b_real=$(realpath "$tmp/wt-b")
repo_real=$(realpath "$repo")
python3 - "$tmp/status-a.json" "$wt_a_real" agent/iso-a <<'PY'
import json, sys
path, wp, br = sys.argv[1:]
with open(path, "w") as f:
    json.dump({"attached": True, "worktreePath": wp, "branch": br}, f)
PY
python3 - "$tmp/status-b.json" "$wt_b_real" agent/iso-b <<'PY'
import json, sys
path, wp, br = sys.argv[1:]
with open(path, "w") as f:
    json.dump({"attached": True, "worktreePath": wp, "branch": br}, f)
PY
python3 - "$tmp/status-false.json" "$wt_a_real" agent/iso-a <<'PY'
import json, sys
path, wp, br = sys.argv[1:]
with open(path, "w") as f:
    json.dump({"attached": False, "worktreePath": wp, "branch": br}, f)
PY
cat > "$tmp/hooks-on.json" <<'EOF'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "/tmp/fixture-only/hooks/guard.sh" }
        ]
      }
    ]
  }
}
EOF
cat > "$tmp/hooks-off.json" <<'EOF'
{ "permissions": { "allow": [] } }
EOF
if [ "$tmp/hooks-on.json" = "$HOME/.claude/settings.json" ] || [ "$tmp/hooks-off.json" = "$HOME/.claude/settings.json" ]; then
  no "hook fixtures are not the user settings file"
else
  ok "hook fixtures are not the user settings file"
fi

run_v() {
  v_out=""
  v_ec=0
  v_err="$tmp/verify.err"
  : > "$v_err"
  v_out=$("$@" 2>"$v_err") || v_ec=$?
}

expect_pass() {
  name=$1
  shift
  run_v "$@"
  if [ "$v_ec" -eq 0 ] && line_is "$v_out" "result=pass" && line_is "$v_out" "t3_binding=match"; then
    ok "$name"
  else
    no "$name ec=$v_ec out=$(printf '%s' "$v_out" | tr '\n' ' ') err=$(tr '\n' ' ' < "$tmp/verify.err")"
  fi
}

expect_fail() {
  name=$1
  shift
  run_v "$@"
  if [ "$v_ec" -ne 0 ] && line_is "$v_out" "result=fail"; then
    ok "$name"
  else
    no "$name ec=$v_ec out=$(printf '%s' "$v_out" | tr '\n' ' ') err=$(tr '\n' ' ' < "$tmp/verify.err")"
  fi
}

if [ -x "$V" ]; then
  ok "verifier script is present"
else
  no "verifier script is present"
fi

expect_pass "verifier accepts worktree A from its cwd" \
  bash -c 'cd "$1" && shift && exec "$@"' _ "$tmp/wt-a" \
  "$V" --workspace "$tmp/wt-a" --branch agent/iso-a --base main \
  --require-cwd "$tmp/wt-a" --t3-status "$tmp/status-a.json" --settings "$tmp/hooks-off.json"

expect_pass "verifier accepts worktree B with its status" \
  bash -c 'cd "$1" && shift && exec "$@"' _ "$tmp/wt-b" \
  "$V" --workspace "$tmp/wt-b" --branch agent/iso-b --base main \
  --require-cwd "$tmp/wt-b" --t3-status "$tmp/status-b.json" --settings "$tmp/hooks-off.json"

expect_fail "status for B does not accept worktree A" \
  bash -c 'cd "$1" && shift && exec "$@"' _ "$tmp/wt-a" \
  "$V" --workspace "$tmp/wt-a" --branch agent/iso-a --base main \
  --require-cwd "$tmp/wt-a" --t3-status "$tmp/status-b.json" --settings "$tmp/hooks-off.json"
run_v bash -c 'cd "$1" && shift && exec "$@"' _ "$tmp/wt-a" \
  "$V" --workspace "$tmp/wt-a" --branch agent/iso-a --base main \
  --require-cwd "$tmp/wt-a" --t3-status "$tmp/status-b.json" --settings "$tmp/hooks-off.json"
if [ "$v_ec" -ne 0 ] && line_is "$v_out" "t3_binding=mismatch" && ! line_is "$v_out" "t3_binding=match"; then
  ok "cross-aimed status is t3_binding=mismatch"
else
  no "cross-aimed status is t3_binding=mismatch ec=$v_ec out=$(printf '%s' "$v_out" | tr '\n' ' ')"
fi

expect_fail "status for A does not accept worktree B" \
  bash -c 'cd "$1" && shift && exec "$@"' _ "$tmp/wt-b" \
  "$V" --workspace "$tmp/wt-b" --branch agent/iso-b --base main \
  --require-cwd "$tmp/wt-b" --t3-status "$tmp/status-a.json" --settings "$tmp/hooks-off.json"

if [ "$(cat "$tmp/wt-a/only-a.bin")" = "$bytes_a" ] && [ "$(cat "$tmp/wt-b/only-b.bin")" = "$bytes_b" ] \
  && [ ! -e "$tmp/wt-b/only-a.bin" ] && [ ! -e "$tmp/wt-a/only-b.bin" ]; then
  ok "verifier runs do not copy bytes across worktrees"
else
  no "verifier runs do not copy bytes across worktrees"
fi

resume_bytes='resume-stay-bytes'
printf '%s' "$resume_bytes" > "$tmp/wt-a/resume.bin"
expect_pass "resume accepts the existing worktree" \
  bash -c 'cd "$1" && shift && exec "$@"' _ "$tmp/wt-a" \
  "$V" --workspace "$tmp/wt-a" --branch agent/iso-a --base main \
  --require-cwd "$tmp/wt-a" --t3-status "$tmp/status-a.json" --settings "$tmp/hooks-off.json"
if git -C "$repo" worktree add -q -b agent/iso-a "$tmp/wt-a-dup" main 2>"$tmp/dup.err"; then
  no "second worktree add for the same branch fails"
  git -C "$repo" worktree remove --force "$tmp/wt-a-dup" 2>/dev/null || true
else
  ok "second worktree add for the same branch fails"
fi
if [ "$(cat "$tmp/wt-a/resume.bin")" = "$resume_bytes" ] && [ ! -d "$tmp/wt-a-dup" ]; then
  ok "resume leaves the first worktree bytes in place"
else
  no "resume leaves the first worktree bytes in place"
fi

expect_fail "wrong require-cwd fails" \
  bash -c 'cd "$1" && shift && exec "$@"' _ "$tmp/wt-a" \
  "$V" --workspace "$tmp/wt-a" --branch agent/iso-a --base main \
  --require-cwd "$tmp/wt-b" --t3-status "$tmp/status-a.json" --settings "$tmp/hooks-off.json"

expect_fail "require-cwd checks pwd, not the workspace flag" \
  bash -c 'cd "$1" && shift && exec "$@"' _ "$repo" \
  "$V" --workspace "$tmp/wt-a" --branch agent/iso-a --base main \
  --require-cwd "$tmp/wt-a" --t3-status "$tmp/status-a.json" --settings "$tmp/hooks-off.json"

expect_fail "wrong branch fails" \
  bash -c 'cd "$1" && shift && exec "$@"' _ "$tmp/wt-a" \
  "$V" --workspace "$tmp/wt-a" --branch agent/iso-b --base main \
  --require-cwd "$tmp/wt-a" --t3-status "$tmp/status-a.json" --settings "$tmp/hooks-off.json"

expect_fail "workspace that is not the worktree fails" \
  bash -c 'cd "$1" && shift && exec "$@"' _ "$repo" \
  "$V" --workspace "$repo" --branch agent/iso-a --base main \
  --require-cwd "$repo" --t3-status "$tmp/status-a.json" --settings "$tmp/hooks-off.json"

mkdir -p "$tmp/wt-a/nested/inner"
ln -s "$tmp/wt-a" "$tmp/link-a"
alias_path="$tmp/link-a/nested/../nested/./inner/../.."
alias_rp=$(realpath "$alias_path")
if [ "$alias_rp" = "$wt_a_real" ]; then
  ok "fixture alias realpath matches worktree A"
else
  no "fixture alias realpath matches worktree A alias=$alias_rp wt=$wt_a_real"
fi
expect_pass "symlink and dot segments pass with the worktree realpath" \
  bash -c 'cd "$1" && shift && exec "$@"' _ "$alias_path" \
  "$V" --workspace "$alias_path" --branch agent/iso-a --base main \
  --require-cwd "$alias_path" --t3-status "$tmp/status-a.json" --settings "$tmp/hooks-off.json"

ln -s "$repo" "$tmp/link-main"
expect_fail "symlink to the main checkout fails for the agent branch" \
  bash -c 'cd "$1" && shift && exec "$@"' _ "$tmp/wt-a" \
  "$V" --workspace "$tmp/link-main" --branch agent/iso-a --base main \
  --require-cwd "$tmp/wt-a" --t3-status "$tmp/status-a.json" --settings "$tmp/hooks-off.json"

expect_fail "omitted t3-status fails" \
  bash -c 'cd "$1" && shift && exec "$@"' _ "$tmp/wt-a" \
  "$V" --workspace "$tmp/wt-a" --branch agent/iso-a --base main \
  --require-cwd "$tmp/wt-a" --settings "$tmp/hooks-off.json"
run_v bash -c 'cd "$1" && shift && exec "$@"' _ "$tmp/wt-a" \
  "$V" --workspace "$tmp/wt-a" --branch agent/iso-a --base main \
  --require-cwd "$tmp/wt-a" --settings "$tmp/hooks-off.json"
if [ "$v_ec" -ne 0 ] && line_is "$v_out" "t3_binding=unverified" && ! line_is "$v_out" "t3_binding=match" && line_is "$v_out" "reason=t3-unverified" && line_is "$v_out" "base=ok"; then
  ok "omitted t3-status is unverified"
else
  no "omitted t3-status is unverified ec=$v_ec out=$(printf '%s' "$v_out" | tr '\n' ' ')"
fi

expect_fail "attached false fails" \
  bash -c 'cd "$1" && shift && exec "$@"' _ "$tmp/wt-a" \
  "$V" --workspace "$tmp/wt-a" --branch agent/iso-a --base main \
  --require-cwd "$tmp/wt-a" --t3-status "$tmp/status-false.json" --settings "$tmp/hooks-off.json"
run_v bash -c 'cd "$1" && shift && exec "$@"' _ "$tmp/wt-a" \
  "$V" --workspace "$tmp/wt-a" --branch agent/iso-a --base main \
  --require-cwd "$tmp/wt-a" --t3-status "$tmp/status-false.json" --settings "$tmp/hooks-off.json"
if [ "$v_ec" -ne 0 ] && line_is "$v_out" "t3_binding=unverified" && ! line_is "$v_out" "t3_binding=match"; then
  ok "attached false is unverified"
else
  no "attached false is unverified ec=$v_ec out=$(printf '%s' "$v_out" | tr '\n' ' ')"
fi

expect_pass "hook fixture with guard.sh is installed and still passes" \
  bash -c 'cd "$1" && shift && exec "$@"' _ "$tmp/wt-a" \
  "$V" --workspace "$tmp/wt-a" --branch agent/iso-a --base main \
  --require-cwd "$tmp/wt-a" --t3-status "$tmp/status-a.json" --settings "$tmp/hooks-on.json"
run_v bash -c 'cd "$1" && shift && exec "$@"' _ "$tmp/wt-a" \
  "$V" --workspace "$tmp/wt-a" --branch agent/iso-a --base main \
  --require-cwd "$tmp/wt-a" --t3-status "$tmp/status-a.json" --settings "$tmp/hooks-on.json"
if line_is "$v_out" "hook=installed"; then
  ok "settings command containing guard.sh prints hook=installed"
else
  no "settings command containing guard.sh prints hook=installed out=$(printf '%s' "$v_out" | tr '\n' ' ')"
fi

expect_pass "hook fixture without hooks still passes" \
  bash -c 'cd "$1" && shift && exec "$@"' _ "$tmp/wt-a" \
  "$V" --workspace "$tmp/wt-a" --branch agent/iso-a --base main \
  --require-cwd "$tmp/wt-a" --t3-status "$tmp/status-a.json" --settings "$tmp/hooks-off.json"
run_v bash -c 'cd "$1" && shift && exec "$@"' _ "$tmp/wt-a" \
  "$V" --workspace "$tmp/wt-a" --branch agent/iso-a --base main \
  --require-cwd "$tmp/wt-a" --t3-status "$tmp/status-a.json" --settings "$tmp/hooks-off.json"
if line_is "$v_out" "hook=not-installed"; then
  ok "settings without hooks prints hook=not-installed"
else
  no "settings without hooks prints hook=not-installed out=$(printf '%s' "$v_out" | tr '\n' ' ')"
fi

head_before=$(git -C "$tmp/wt-a" rev-parse HEAD)
status_before=$(git -C "$tmp/wt-a" status --porcelain)
run_v bash -c 'cd "$1" && shift && exec "$@"' _ "$tmp/wt-a" \
  "$V" --workspace "$tmp/wt-a" --branch agent/iso-a --base main \
  --require-cwd "$tmp/wt-a" --t3-status "$tmp/status-a.json" --settings "$tmp/hooks-off.json"
head_after=$(git -C "$tmp/wt-a" rev-parse HEAD)
status_after=$(git -C "$tmp/wt-a" status --porcelain)
if [ "$head_before" = "$head_after" ] && [ "$status_before" = "$status_after" ]; then
  ok "verifier does not change git state"
else
  no "verifier does not change git state"
fi

git -C "$repo" commit -q --allow-empty -m later
expect_fail "base that is not an ancestor fails" \
  bash -c 'cd "$1" && shift && exec "$@"' _ "$tmp/wt-a" \
  "$V" --workspace "$tmp/wt-a" --branch agent/iso-a --base main \
  --require-cwd "$tmp/wt-a" --t3-status "$tmp/status-a.json" --settings "$tmp/hooks-off.json"
run_v bash -c 'cd "$1" && shift && exec "$@"' _ "$tmp/wt-a" \
  "$V" --workspace "$tmp/wt-a" --branch agent/iso-a --base main \
  --require-cwd "$tmp/wt-a" --t3-status "$tmp/status-a.json" --settings "$tmp/hooks-off.json"
if [ "$v_ec" -ne 0 ] && line_is "$v_out" "base=mismatch"; then
  ok "moved main is base=mismatch"
else
  no "moved main is base=mismatch ec=$v_ec out=$(printf '%s' "$v_out" | tr '\n' ' ')"
fi

expect_fail "missing base fails" \
  bash -c 'cd "$1" && shift && exec "$@"' _ "$tmp/wt-a" \
  "$V" --workspace "$tmp/wt-a" --branch agent/iso-a --base no-such-ref \
  --require-cwd "$tmp/wt-a" --t3-status "$tmp/status-a.json" --settings "$tmp/hooks-off.json"
run_v bash -c 'cd "$1" && shift && exec "$@"' _ "$tmp/wt-a" \
  "$V" --workspace "$tmp/wt-a" --branch agent/iso-a --base no-such-ref \
  --require-cwd "$tmp/wt-a" --t3-status "$tmp/status-a.json" --settings "$tmp/hooks-off.json"
if [ "$v_ec" -ne 0 ] && line_is "$v_out" "base=missing"; then
  ok "unknown base is base=missing"
else
  no "unknown base is base=missing ec=$v_ec out=$(printf '%s' "$v_out" | tr '\n' ' ')"
fi

echo "----"
echo "PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ]
