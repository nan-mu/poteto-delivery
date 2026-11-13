#!/usr/bin/env bash
# Minimal PreToolUse backstop for poteto-delivery's hard deny list. It blocks the
# clearest forbidden operations even if credentials would allow them. It is a
# backstop, not a complete policy engine; the skill's judgment still governs.
#
# Input: Claude Code PreToolUse JSON on stdin (.tool_name, .tool_input.command).
# Output: a deny decision JSON for a matched operation; otherwise exit 0 (allow).
# Fail-open on missing jq or unparseable input so it never wedges the session.
set -u

have() { command -v "$1" >/dev/null 2>&1; }
have jq || exit 0

input=$(cat 2>/dev/null) || exit 0
tool=$(printf '%s' "$input" | jq -r '.tool_name // ""' 2>/dev/null) || exit 0
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null) || exit 0

deny() {
	jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
	exit 0
}

# Forbidden GitHub MCP tools by name (merge / delete / admin).
case "$tool" in
	mcp__github__merge_pull_request|mcp__github__delete_repository|mcp__github__delete_branch)
		deny "poteto-delivery: $tool is forbidden. Merge/delete is performed by the user alone." ;;
esac

[ "$tool" = "Bash" ] || exit 0
[ -n "$cmd" ] || exit 0

# Merge a PR remotely.
if printf '%s' "$cmd" | grep -Eq '(^|[;&| ])(gh|origin)[[:space:]]+pr[[:space:]]+merge'; then
	deny "poteto-delivery: merging a PR is forbidden. The user merges on GitHub."
fi
if printf '%s' "$cmd" | grep -Eq 'gh[[:space:]]+api[^|]*-X[[:space:]]*PUT[^|]*/merge'; then
	deny "poteto-delivery: PR merge via API is forbidden."
fi

# Force push (any flavor).
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+push' && \
   printf '%s' "$cmd" | grep -Eq '(--force([[:space:]]|=|-with-lease)|[[:space:]]-f([[:space:]]|$))'; then
	deny "poteto-delivery: force push is forbidden."
fi

# Push directly to a protected base branch (main/master/trunk).
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+push' && \
   printf '%s' "$cmd" | grep -Eq '(^|[[:space:]:])(main|master|trunk)([[:space:]]|$|:)'; then
	deny "poteto-delivery: pushing to a protected base branch is forbidden. Push the agent/* task branch."
fi

# Delete a remote branch or repo.
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+push[^|]*--delete'; then
	deny "poteto-delivery: deleting a remote branch is forbidden."
fi
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+push[^|]*[[:space:]]:[^[:space:]]'; then
	deny "poteto-delivery: deleting a remote branch (refspec :branch) is forbidden."
fi
if printf '%s' "$cmd" | grep -Eq '(^|[;&| ])gh[[:space:]]+repo[[:space:]]+delete'; then
	deny "poteto-delivery: deleting a repository is forbidden."
fi

exit 0