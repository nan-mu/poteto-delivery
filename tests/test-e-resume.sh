#!/usr/bin/env bash
# Test E: resuming a task reuses the existing worktree/branch/audit instead of
# recreating resources. delivery-state.sh detects the existing agent/* worktree;
# git refuses to recreate the same branch, proving resume must reuse. Local only.
set -u
HERE=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
ok(){ echo "PASS: $1"; pass=$((pass+1)); }
no(){ echo "FAIL: $1"; fail=$((fail+1)); }

repo="$tmp/repo"; mkdir -p "$repo"; git -C "$repo" init -q -b main
git -C "$repo" commit -q --allow-empty -m init
git -C "$repo" worktree add -q -b agent/resume "$tmp/wt" main
( cd "$tmp/wt" && echo x > f.txt && git add f.txt && git commit -q -m "wip" )
mkdir -p "$tmp/wt/.audit"; echo "# Audit: resume" > "$tmp/wt/.audit/resume.md"

# A resume run inspects state and finds the existing branch + worktree + audit.
( cd "$tmp/wt" && "$HERE/scripts/delivery-state.sh" > "$tmp/state.json" 2>/dev/null )
if command -v jq >/dev/null 2>&1; then
	jq -e '.branch=="agent/resume" and .is_agent_branch==true' "$tmp/state.json" >/dev/null && ok "E: resume detects existing agent branch" || no "E: resume detects existing agent branch"
	jq -e '[.agent_worktrees[].branch]|index("agent/resume")!=null' "$tmp/state.json" >/dev/null && ok "E: resume detects existing worktree" || no "E: resume detects existing worktree"
else
	grep -q 'agent/resume' "$tmp/state.json" && ok "E: resume detects existing branch (no jq)" || no "E: resume detects existing branch"
fi
[ -f "$tmp/wt/.audit/resume.md" ] && ok "E: existing audit preserved on resume" || no "E: existing audit preserved"

# Recreating the same branch is refused -> the wrapper must reuse, not duplicate.
if git -C "$repo" worktree add -q -b agent/resume "$tmp/wt2" main 2>/dev/null; then
	no "E: git allowed duplicate branch (unexpected)"; git -C "$repo" worktree remove --force "$tmp/wt2" 2>/dev/null
else
	ok "E: git refuses duplicate branch, forcing reuse"
fi
# The original worktree and its commit are untouched.
[ "$(git -C "$tmp/wt" rev-parse --abbrev-ref HEAD)" = "agent/resume" ] && ok "E: original worktree intact" || no "E: original worktree intact"

echo "----"; echo "PASS=$pass FAIL=$fail"; [ "$fail" -eq 0 ]