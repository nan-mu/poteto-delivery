# poteto-delivery

A thin Claude Code skill that wraps the installed PStack `poteto-mode` for task-book delivery. PStack decides how the work is done; this skill adds only:

- an isolated `agent/<task-slug>` worktree, initialized and verified, reused on resume;
- a continuously rechecked `.audit` requirements checklist (committed Markdown) plus PStack's local `show-me-your-work` decision trail;
- one Draft PR as the live delivery channel: early creation, per-phase push + short comment, final delivery and Ready for Review.

It does not reimplement PStack's roles, playbooks, TDD, review, or retry rules, and it does not modify PStack. Engineering execution loads the original installed PStack files at runtime (the adapter-documented Read-and-follow composition, since the `Skill` tool refuses `disable-model-invocation` skills).

## Install

User-level skill under the active Claude config dir:

```bash
ln -sfn /path/to/poteto-delivery "$CLAUDE_CONFIG_DIR/skills/poteto-delivery"
chmod +x scripts/*.sh hooks/*.sh
```

`scripts/verify-workspace.sh` is the pre-edit gate. Run it after the worktree is bound. A non-zero exit means stop.

The guard hook is optional and stays inactive until a `settings.json` PreToolUse command loads it. The install snippet is below.

```json
{ "hooks": { "PreToolUse": [ { "matcher": "Bash",
  "hooks": [ { "type": "command", "command": "/path/to/poteto-delivery/hooks/guard.sh" } ] } ] } }
```

## Use

Hand the agent a Markdown task book and invoke `/poteto-delivery` (or let the skill trigger on a task-book delivery request). The agent loads PStack, sets up the worktree and `.audit`, runs the matching PStack playbook, and delivers through one Draft PR.

## GitHub channel and permissions

Prefers the registered official GitHub MCP (`https://api.githubcopilot.com/mcp/`); falls back to authenticated `gh` when MCP tools are unavailable. Authorized: read repos/branches/commits/files, create `agent/*` branches, commit/push the task branch, create/read/update PRs, create/read Issues, comment in ordinary discussion, read reviews/checks. Forbidden even if credentials allow: merge, push to protected base, force push, delete remote branch/repo, admin/Secrets/Rulesets changes, auto-clean worktree. **Merge is performed by the user alone.** See `references/github.md`.

## Layout

- `SKILL.md` is the wrapper boundary behavior.
- `references/worktree.md`, `references/audit.md`, and `references/github.md` hold the detail.
- `scripts/delivery-state.sh` is the read-only worktree, branch, and PR report, including comment dedupe.
- `scripts/audit-check.sh` is the checklist gap gate.
- `scripts/verify-workspace.sh` is the read-only pre-edit gate.
- `hooks/guard.sh` is the deny-list backstop. It does nothing until settings load it.

## Status / limitations

See the delivery report for what is verified vs pending. Notably: the remote GitHub MCP endpoint is reachable but the registered connection's tools fetch currently times out, so this environment uses the `gh` fallback until the MCP connection is fixed (config changes are out of scope here).