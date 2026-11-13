# GitHub channel and permission boundaries

GitHub is the live delivery channel. T3 is where the user discusses, revises the task book, and resolves genuine conflicts. Local git handles worktree/commit/push; the GitHub channel handles remote PR/issue/comment/metadata.

## Channel: MCP first, gh fallback

1. Prefer the registered official GitHub MCP server (`github`, remote `https://api.githubcopilot.com/mcp/`, upstream `https://github.com/github/github-mcp-server`). Do not install `github-ops-mcp` or any third-party substitute. Do not re-add, overwrite, or delete the user's existing MCP config.
2. Detect availability in the actual running session: look for `mcp__github__*` tools (e.g. `create_pull_request`, `update_pull_request`, `add_issue_comment`, `get_pull_request`, `list_pull_requests`). If present and authenticated, use them for remote PR/comment/metadata operations.
3. If the MCP tools are absent or the connection fails (e.g. "tools fetch failed"), fall back to the authenticated `gh` CLI for the same operations and say so. `gh` is PStack `opening-a-pr`'s default forge anyway. Do not write a duplicate API client.
4. Report MCP connection status honestly. A registered server whose tools fetch times out is **not** a verified connection. Never claim a remote write succeeded from a simulated or local response.

Local git operations (worktree, commit, push of the task branch) use git directly regardless of channel.

## Authorized (allow)

- Read target repos, branches, commits, files.
- Create `agent/*` branches in an isolated worktree.
- Commit and push the task branch.
- Create, read, update PRs (including Draft → Ready for Review).
- Create and read Issues.
- Comment in the ordinary discussion area of Issues and PRs.
- Read PR review comments and check results.

Writes are confined to repos the user explicitly authorized for the task. Test PRs/commits must not go into real research repos.

## Forbidden (deny) — even if credentials allow

- Merge a PR. **Merge is performed by the user alone on GitHub.**
- Push directly to `main`, `master`, or any protected base branch.
- Force push.
- Delete remote branches or repos.
- Change repo permissions, Secrets, Rulesets, or other admin settings.
- Auto-clean the task worktree.

These are hard boundaries. A tool whitelist is not a repo rule and does not guarantee the underlying git credential cannot merge; the wrapper must refuse the operation regardless of capability. `hooks/guard.sh` is a minimal PreToolUse backstop for the clearest cases (merge, force-push, push to a protected base, remote delete); it does not replace judgment.

## Three distinct permission boundaries

Keep these separate; do not conflate them:
1. **GitHub PAT scope** — what the token can do server-side.
2. **MCP exposed tools** — which operations the server surfaces (toolsets/header).
3. **Local git/gh credential** — what local push/merge can do.

Least privilege: prefer a fine-grained PAT limited to the authorized repos (Contents RW, Pull requests RW, Issues RW, Metadata RO), no Administration/Workflow/delete/merge. Tokens never enter the conversation, task book, commits, `.audit`, or logs. Permission tightening can proceed separately from skill development; do not block local work on it and do not ask the user for a token.

## PR lifecycle

One Draft PR per task, updated in place. Create it after the first meaningful real commit (no empty/fake diff). Stage comment per verified phase, deduped by head SHA (`scripts/delivery-state.sh` reports the head SHA and the last comment marker). Final delivery updates the description, posts an evidence comment, and marks Ready only when all required acceptance passes. Ready ≠ Merge.