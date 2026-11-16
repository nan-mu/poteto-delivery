# poteto-delivery

An explicitly invoked entry adapter for the installed PStack `poteto-mode`.
It resolves the upstream installation, handles necessary native T3 workspace
binding, and hands the user's task to PStack. The repository contains only
`SKILL.md` and this README.

## Ownership

| Responsibility | Owner |
| --- | --- |
| Explicit entry and the minimum context needed for handoff | poteto-delivery |
| Task classification, playbooks, orchestration, agents, and models | PStack |
| Implementation, testing, review, decision trails, PR flow, and task resumption | PStack |
| T3 thread binding, worktree location, handoff, and thread launch | T3 Code |
| File access, command execution, Agent/Skill tools, and tool permissions | Claude Code |
| Remote branch transport | git, including `git push` |
| GitHub pull requests, issues, reviews, and labels | Magpie GitHub MCP while `/poteto-delivery` is invoked. No `gh`, and no HTTP fallback. The route is in `SKILL.md`. |

PStack's current installed files define the workflow. This adapter neither
vendors them nor restates their steps. Updates therefore use the installed
version without maintaining a second copy of its workflow.

Any proposed addition must identify a concrete interface gap, check whether
PStack, T3, or Claude already owns it, and receive explicit user authorization
before expanding this adapter. An upstream feature gap alone is insufficient.
Adaptation must remain local to the explicit entry, without adding a workflow,
state owner, or instructions for unrelated tasks.

## Install

Install and enable PStack in the Claude Code configuration used by your T3
session. This repository is a standalone Claude Code skill, not a bundled copy
of PStack or a T3 MCP server.

Link it into that configuration's `skills` directory. On macOS with fish,
replace the source path below. Set `CLAUDE_CONFIG_DIR` to the configuration
actually used by T3 before running this if you use a custom directory.

```fish
set -l pd_config_dir ~/.claude
if set -q CLAUDE_CONFIG_DIR
    set pd_config_dir "$CLAUDE_CONFIG_DIR"
end
mkdir -p "$pd_config_dir/skills"
if test -e "$pd_config_dir/skills/poteto-delivery"; or test -L "$pd_config_dir/skills/poteto-delivery"
    printf '%s\n' 'Destination exists; inspect it before replacing it.'
else
    ln -s /absolute/path/to/poteto-delivery "$pd_config_dir/skills/poteto-delivery"
end
```

If the destination already exists, inspect it before replacing it. No executable
permission changes, hooks, or global rule edits are needed.

## Use

Start a message with `/poteto-delivery` and provide the task text or a readable
task-book path, repository, and any required base or authorization limits.

The entry resolves the enabled PStack installation for the current scope.
Inside T3 it checks the native thread binding and uses the exposed native
workspace tools when a change task needs a bound worktree. A handoff ends the
current session, so its continuation carries the task into the destination and
checks the binding there before loading PStack. Existing task worktrees are
reused. The adapter does not invent a worktree path or create one through shell
commands. Outside T3 it leaves workspace handling to PStack and the host.

After binding, it reads PStack's installed Claude harness and poteto-mode entry
and follows their composition method. PStack then owns the task. Missing or
ambiguous upstream installations and unavailable required T3 capabilities are
reported before execution; they do not trigger a replacement workflow.

`disable-model-invocation: true` makes the skill user-invoked in Claude Code.
A task book alone does not activate it. Do not add it to `CLAUDE.md`, `AGENTS.md`,
global rules, hooks, or subagent briefs as a standing instruction.

Claude retains invoked skill content in the conversation. Ending the adapter's
role is an instruction boundary, not a claim that its text is unloaded. The
adapter has no later stage checks or persistent task lifecycle. Host overrides
can affect invocation behavior; other hosts need their own invocation controls.

## Upgrading from the previous wrapper

This revision removes all custom scripts, the guard hook, requirements audit
tables, workspace verifier, delivery state, workflow references, and their
tests. Draft-first PRs, per-phase pushes/comments, wrapper-selected agents and
models, and wrapper-specific permission rules are no longer prescribed.

If you manually installed a `PreToolUse` entry pointing to this repository's
old `hooks/guard.sh`, remove only that obsolete hook entry from the active
Claude configuration before updating. Likewise, remove any manually added
global instruction that automatically activates poteto-delivery. The old
symlink installation can stay. Updating this repository does not change your
configuration or delete task artifacts in other repositories.

## Source references and validation

- [PStack Claude Code harness](https://github.com/cursor/plugins/blob/main/pstack/docs/harness/claude-code.md).
- [PStack poteto-mode](https://github.com/cursor/plugins/blob/main/pstack/skills/poteto-mode/SKILL.md).
- [T3 native worktree tools](https://github.com/pingdotgg/t3code/blob/main/apps/server/src/mcp/toolkits/worktree/tools.ts).
- [T3 handoff contract](https://github.com/pingdotgg/t3code/blob/main/packages/contracts/src/worktreeMcp.ts).
- [Claude Code skill invocation and lifecycle](https://code.claude.com/docs/en/skills).

This is an instruction-only adapter. There is no packaged test runner or
runtime enforcement layer. Validate the frontmatter and source references, then
check explicit invocation, dependency failures, existing bindings, and handoff
continuation in the target Claude/T3 session. Source review does not establish
that those live integrations have been exercised.
