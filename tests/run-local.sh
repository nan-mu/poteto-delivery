#!/usr/bin/env bash
# Local, no-network tests for poteto-delivery's deterministic helpers and the
# worktree/audit mechanics. Reproducible test evidence; no GitHub writes.
set -u
HERE=$(cd "$(dirname "$0")/.." && pwd)
pass=0; fail=0
ok(){ echo "PASS: $1"; pass=$((pass+1)); }
no(){ echo "FAIL: $1"; fail=$((fail+1)); }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

# --- audit-check.sh ---
cat > "$tmp/open.md" <<'EOF'
# Audit: t
| # | Requirement | Implemented | Verified | Evidence | Open issue |
|---|---|---|---|---|---|
| 1 | closed req | yes | yes | foo.sh:1 | — |
| 2 | open req | no | no | — | — |
EOF
"$HERE/scripts/audit-check.sh" "$tmp/open.md" 2>/dev/null | grep -q 'OPEN #2' && ok "audit flags the open row" || no "audit flags the open row"
"$HERE/scripts/audit-check.sh" "$tmp/open.md" >/dev/null 2>&1; [ $? -eq 1 ] && ok "audit exits 1 on a gap" || no "audit exits 1 on a gap"
cat > "$tmp/closed.md" <<'EOF'
| # | Requirement | Implemented | Verified | Evidence | Open issue |
|---|---|---|---|---|---|
| 1 | closed req | yes | yes | foo.sh:1 | — |
EOF
"$HERE/scripts/audit-check.sh" "$tmp/closed.md" >/dev/null 2>&1; [ $? -eq 0 ] && ok "audit exits 0 when all closed" || no "audit exits 0 when all closed"
# A row with tests passing but no evidence must stay open (test C mechanic).
cat > "$tmp/noev.md" <<'EOF'
| # | Requirement | Implemented | Verified | Evidence | Open issue |
|---|---|---|---|---|---|
| 1 | req with green tests but no pointer | yes | yes | — | — |
EOF
"$HERE/scripts/audit-check.sh" "$tmp/noev.md" >/dev/null 2>&1; [ $? -eq 1 ] && ok "audit keeps evidence-less row open" || no "audit keeps evidence-less row open"

# --- guard.sh deny/allow matrix ---
denied(){ printf '%s' "$1" | "$HERE/hooks/guard.sh" 2>/dev/null | grep -q '"deny"'; }
allowed(){ out=$(printf '%s' "$1" | "$HERE/hooks/guard.sh" 2>/dev/null); [ -z "$out" ]; }
denied '{"tool_name":"Bash","tool_input":{"command":"gh pr merge 5"}}' && ok "guard denies gh pr merge" || no "guard denies gh pr merge"
denied '{"tool_name":"Bash","tool_input":{"command":"git push --force origin agent/x"}}' && ok "guard denies force push" || no "guard denies force push"
denied '{"tool_name":"Bash","tool_input":{"command":"git push -f origin agent/x"}}' && ok "guard denies -f push" || no "guard denies -f push"
denied '{"tool_name":"Bash","tool_input":{"command":"git push origin main"}}' && ok "guard denies push to main" || no "guard denies push to main"
denied '{"tool_name":"Bash","tool_input":{"command":"git push origin HEAD:master"}}' && ok "guard denies push to master" || no "guard denies push to master"
denied '{"tool_name":"Bash","tool_input":{"command":"git push origin --delete agent/x"}}' && ok "guard denies remote branch delete" || no "guard denies remote branch delete"
denied '{"tool_name":"Bash","tool_input":{"command":"gh repo delete foo"}}' && ok "guard denies repo delete" || no "guard denies repo delete"
denied '{"tool_name":"mcp__github__merge_pull_request","tool_input":{}}' && ok "guard denies MCP merge tool" || no "guard denies MCP merge tool"
allowed '{"tool_name":"Bash","tool_input":{"command":"git push origin agent/x"}}' && ok "guard allows agent branch push" || no "guard allows agent branch push"
allowed '{"tool_name":"Bash","tool_input":{"command":"git commit -m wip"}}' && ok "guard allows commit" || no "guard allows commit"
allowed '{"tool_name":"Bash","tool_input":{"command":"gh pr create --draft"}}' && ok "guard allows draft PR create" || no "guard allows draft PR create"
allowed '{"tool_name":"Bash","tool_input":{"command":"git push origin agent/main-fix"}}' && ok "guard allows agent branch containing 'main'" || no "guard allows agent branch containing 'main'"

# --- delivery-state.sh in a temp repo with an agent worktree ---
repo="$tmp/repo"; mkdir -p "$repo"; git -C "$repo" init -q -b main
git -C "$repo" commit -q --allow-empty -m init
git -C "$repo" worktree add -q -b agent/demo "$tmp/wt-demo" main
( cd "$tmp/wt-demo" && "$HERE/scripts/delivery-state.sh" > "$tmp/state.json" 2>/dev/null )
if command -v jq >/dev/null 2>&1; then
	jq -e '.is_agent_branch==true and .branch=="agent/demo"' "$tmp/state.json" >/dev/null && ok "state detects agent branch in worktree" || no "state detects agent branch in worktree"
	jq -e '.agent_worktrees|length>=1' "$tmp/state.json" >/dev/null && ok "state lists agent worktrees" || no "state lists agent worktrees"
	jq -e '.pr==null' "$tmp/state.json" >/dev/null && ok "state reports null PR without remote" || no "state reports null PR without remote"
else
	grep -q 'agent/demo' "$tmp/state.json" && ok "state detects agent branch (no jq)" || no "state detects agent branch (no jq)"
fi

echo "----"
echo "PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ]