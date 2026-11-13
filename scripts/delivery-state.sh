#!/usr/bin/env bash
# Read-only delivery state reporter for poteto-delivery. Emits JSON the agent
# reads to decide init vs resume and to dedupe PR stage comments. Never writes.
#
# Usage:
#   delivery-state.sh                 # JSON state for the current worktree
#   delivery-state.sh commented <pr> <sha>
#       exit 0 if a stage comment marked with <sha> already exists on <pr>,
#       exit 1 otherwise. Marker: <!-- poteto-delivery sha=<sha> -->
set -u

have() { command -v "$1" >/dev/null 2>&1; }

commented() {
	pr="$1"; sha="$2"
	have gh || { echo "gh absent; cannot dedupe" >&2; return 1; }
	repo=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null) || return 1
	gh api "repos/$repo/issues/$pr/comments" --paginate -q '.[].body' 2>/dev/null \
		| grep -qF "poteto-delivery sha=$sha"
}

if [ "${1:-}" = "commented" ]; then
	[ $# -ge 3 ] || { echo "usage: delivery-state.sh commented <pr> <sha>" >&2; exit 2; }
	commented "$2" "$3"; exit $?
fi

root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo '{"error":"not a git repo"}'; exit 1; }
cd "$root" || exit 1

branch=$(git branch --show-current 2>/dev/null || echo "")
head=$(git rev-parse HEAD 2>/dev/null || echo "")
default=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')
[ -z "$default" ] && for c in main master; do
	git rev-parse --verify --quiet "$c" >/dev/null && { default="$c"; break; }
done
dirty=$(git status --porcelain 2>/dev/null | grep -cv '^??' || true)

worktrees=$(git worktree list --porcelain | awk '
	/^worktree /{wt=$2}
	/^branch /{b=$2; sub(/^refs\/heads\//,"",b); if (b ~ /^agent\//) printf "%s\t%s\n", b, wt}')

pr_json="null"
if [ -n "$branch" ] && have gh; then
	pr_json=$(gh pr view "$branch" --json number,state,url,isDraft,headRefOid 2>/dev/null || echo "null")
	[ -z "$pr_json" ] && pr_json="null"
fi

if have jq; then
	jq -n --arg root "$root" --arg branch "$branch" --arg head "$head" \
		--arg default "$default" --argjson dirty "${dirty:-0}" \
		--arg worktrees "$worktrees" --argjson pr "$pr_json" \
		'{repo_root:$root, default_branch:$default, branch:$branch,
		  is_agent_branch:($branch|startswith("agent/")), head_sha:$head,
		  tracked_changes:$dirty, agent_worktrees:($worktrees|split("\n")|map(select(length>0)|split("\t")|{branch:.[0],path:.[1]})),
		  pr:$pr}'
else
	printf '{"repo_root":"%s","branch":"%s","head_sha":"%s","default_branch":"%s","tracked_changes":%s}\n' \
		"$root" "$branch" "$head" "$default" "${dirty:-0}"
fi