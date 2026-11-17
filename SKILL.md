---
name: poteto-delivery
description: Explicit entry for personal T3 Code engineering habits using installed PStack poteto-mode, with Pi interface adaptation. Use only when the user explicitly invokes poteto-delivery.
disable-model-invocation: true
---

# poteto-delivery

This skill records personal engineering habits for T3 Code, its primary
working environment. Pi is an auxiliary environment whose compatibility depends
on installed extensions and agent definitions. Keep other host guidance limited
to available interfaces; it does not establish complete integration support.

Apply this entry only to the user's explicit invocation and its necessary T3
continuation. A task book, ordinary message, another skill, or a subagent does
not activate it. Pi uses `/skill:poteto-delivery`, Claude Code uses
`/poteto-delivery`, and Codex uses `$poteto-delivery`.

PStack owns classification, playbooks, workflow, agents, model selection,
implementation, verification, review, PR lifecycle, and resumption. T3 owns
threads and workspace binding. Magpie supplies skill distribution and existing
model routing. The host owns native tools and permissions. This adapter only
resolves interfaces, binds the workspace, and carries the necessary context.
Do not add a workflow, runtime, scripts, hooks, state, or global instructions.
Do not duplicate PStack or build a task state machine, agent scheduler, execution
engine, or general harness abstraction. Keep these personal conventions scoped
to this invocation and its necessary continuation.

## Resolve PStack and the host interface

Preserve the user's task, revisions, authorization, repository, and requested
base. Resolve `poteto-mode/SKILL.md` from this session's registered skill or
plugin resources, following registered paths rather than choosing an arbitrary
cached version. A plugin usually stores it at `skills/poteto-mode/SKILL.md`;
a flattened skill library may register it separately.

Read the installed entry in full and its applicable upstream harness rules.
Upstream composition rules take priority over the interface guidance below,
subject to the user's authorization, host constraints, and the GitHub route.
Do not copy, download a replacement for, or modify upstream skills or harness
files. Report missing, disabled, ambiguous, or incompatible dependencies.

### Pi

Discover PStack through the current session's registered Skill resources. Read
skills with Pi's actual file tools and compose or invoke them using its exposed
capabilities and upstream instructions. If upstream supports composition in the
current session, read and apply its entry there.

Pi's Agent capability comes from the actually loaded
`@tintinweb/pi-subagents` extension, not an assumed built-in Agent or Task tool.
Use the session's exposed Agent tool and current schema, including
`subagent_type`, `prompt`, `description`, `max_turns`, and `run_in_background`
when required by PStack. Do not transplant Claude Task, Skill, AskQuestion, or
EnterWorktree calls. Preserve PStack's ownership of playbooks, agent roles,
models, and execution; this adapter only resolves the interface.

Before required delegation, confirm that the extension can resolve and start the
exact agent type PStack requests, including `poteto-agent`. Reading a Skill or
finding an agent definition alone does not establish registration. Check runtime
registration or dispatch metadata for the resolved type and any fallback notice;
an agent's self-reported identity is not proof. Use read-only capability probes
when needed, without running playbooks, editing files, spawning nested agents,
or performing GitHub operations.

Unknown types must fail. Never accept `general-purpose` or another agent as a
replacement for the requested type. If the extension is missing, the type is
unavailable, fallback occurs, or the required interface cannot be used or
verified, report `BLOCKED` and name the gap. Do not bypass it with another agent,
main-agent execution of the delegated work, or a substitute local workflow.

Pi's user configuration lives under `~/.pi` by default. Agent definitions in
`~/.pi/agent/agents/` and the strict unknown-type fallback policy in
`~/.pi/agent/subagents.json` are user-managed prerequisites. Honor the actual
`PI_CODING_AGENT_DIR` when set. Inspect configuration read-only as needed; do not
modify definitions, links, their targets, or runtime settings, copy personal
configuration into this repository, or ask Magpie to manage it. Do not implement
agent discovery, registration, fallback, or scheduling here.

### Claude Code

First resolve the session's enabled `poteto-mode/SKILL.md` from its registered
Plugin or Skill resources, including Magpie's flattened Skill installations.
If necessary, inspect `plugins/installed_plugins.json` under the active
`CLAUDE_CONFIG_DIR` (default `~/.claude`), matching enabled status and
installation scope to this project. Do not select a cached version by sorting
version strings. If the installation includes `docs/harness/claude-code.md`,
read and follow it. Otherwise inspect the installed PStack skills for rules
applicable to Claude Code and use those when they provide the necessary
adaptation. A missing standalone harness document alone is not a blocker.
Report BLOCKED only when an actual required capability or dependency is
missing, or the correct adaptation cannot be determined; name the specific
gap. Do not download, copy, or maintain replacement upstream files.
Compose internal skills using those upstream rules; the Skill tool cannot be
assumed to invoke every internal skill. Use the current Agent/Task schema and
accepted model choices, without assuming arbitrary provider IDs are valid.
Workspace operations in T3 use the native T3 tools below.

### Codex

Discover PStack from registered Skill resources and follow Codex's supported
Agent Skills loading and composition. Prefer installed upstream Codex adapter
rules when available. Read the entry directly when that is the supported skill
loading method. Use exposed subagent tools and their real schemas only as
PStack requires; do not translate Claude Task arguments into unverified Codex
parameters or assume native subagents accept arbitrary third-party models.

Codex's explicit invocation policy is the minimal `agents/openai.yaml` shipped
with this skill: `policy.allow_implicit_invocation: false`. The frontmatter
`disable-model-invocation` is used by Pi and Claude Code; it does not establish
Codex support. If the running host version does not honor its corresponding
invocation control, disclose that limitation instead of claiming enforcement.

## Bind the workspace through T3

Outside T3, leave workspace handling to PStack and the host. In a known T3
session, inspect the currently exposed tool descriptions and schemas; prefixes
and parameters can vary by version. Missing tools are capability blockers,
not evidence that the session is outside T3. Historical examples are not the
runtime schema.

1. Call `t3_worktree_status`. Read `attached`, `worktreePath`, `branch`,
   `projectWorkspaceRoot`, and `defaultStartFromOrigin`. Compare them with the
   user's repository and task context. Native read-only git/CWD checks can
   corroborate the checkout; they do not prove thread binding or task identity.
2. Reuse a suitable current binding. When needed, use `t3_worktree_list` to
   locate an existing task workspace. Match repository, branch, and task
   context together; do not adopt another task's worktree. Reuse a matching
   workspace through an available native binding operation; if none exists,
   report that blocker instead of creating a duplicate.
3. For a new worktree, use `t3_worktree_handoff` only after confirming the
   current thread is unattached and suitable for migration. Set an explicit
   target `branch` and `baseRef`. Honor the requested base and remote-start
   choice; otherwise follow the current host's documented defaults and
   `defaultStartFromOrigin`. Pass `startFromOrigin` only as the live schema
   supports. Let T3 choose the path. Do not start PStack in the old checkout.
4. Supply a complete `continuationPrompt`: the task and revisions, authorization
   limits, repository, target branch/base and remote-start choice, the selected
   host's interface guidance, remaining entry steps, and the GitHub route block
   below. Include task text if its source file is unavailable at the destination.
   Say this continues the same explicit invocation and must recheck binding,
   resolve installed PStack, then hand control to it once. Call handoff last
   in the turn because it ends the active turn. Resume only after checking
   the destination binding against that context. In the resumed thread,
   call `t3_worktree_status` again and confirm the target repository, branch,
   and binding before allowing PStack to execute.
5. `t3_thread_launch` starts an independent thread; it does not migrate this
   thread or attach this thread to an existing worktree. Use it only when the
   user requests an independent thread, not as an automatic handoff fallback.
   Read its live schema and specify the appropriate `workspaceStrategy`,
   repository/project, branch/base, and existing-worktree identity when needed.
   Give it the same complete continuation and route block; do not assume it
   inherits skills or MCP context. The destination must check binding before
   PStack executes. After a successful launch, end this entry in the source
   thread without also executing the task or monitoring the destination.

Interpret the handoff result using the current return schema. Check returned
`worktreePath`, `branch`, `baseRef`, and `startedFromOrigin` against the intended
destination; creation of the worktree does not establish continuation success.
Judge `continuation.status` and `setupScript.status` separately:

- `continuation.status: scheduled` means continuation has been arranged;
  report its returned `delivery` without claiming the task is complete.
  `skipped` means no continuation was arranged; do not report task startup.
  `failed` means report its `detail` and do not claim handoff success.
- `setupScript.status: started` means only that the script started, not that
  it finished or succeeded; retain the returned `scriptName` and `terminalId`.
  `no-script` means no script is configured. `skipped` means it did not run.
  `failed` means retain and report its `detail`, independently of continuation.

Handoff ends the active turn. Interpret and report the returned result when
available; if the turn has already ended, inspect the available handoff result
on resumption and report any failure details there. Do not add polling,
monitors, scripts, or task state to wait for either status. Missing or unknown
result fields are an unresolved capability/version gap, not proof of success.

If a current binding belongs to another task, a native operation fails, a
required tool is unavailable, or the resulting binding does not match, report
the specific blocker before task edits. Do not guess paths, modify T3 config,
create workspace management scripts, use `git worktree add` or EnterWorktree
as a substitute, or move/clean another task's workspace.

## Hand control to PStack once

After binding, compose or invoke the installed entry using its upstream harness
rules and the current host's real interfaces. Writing a slash command in a
brief alone is not execution. Let PStack select its own dependencies and agents.
Carry the user's full task and revisions, authorization limits, confirmed
workspace context, and route block. A fresh child may not inherit a skill the
parent read: provide the necessary context using upstream's composition method.
Do not paste this entire adapter into unrelated briefs.

After handing control to PStack, perform no adapter phase checks, monitoring,
or cleanup. Do not re-enter on later messages without another explicit
invocation. If composition requires an unavailable capability, report it;
do not replace PStack with a local workflow.

## Route GitHub through Magpie

Include this block in the initial PStack brief, necessary T3 continuations,
and later briefs assigning a push or GitHub operation. It may be retained
through PStack's inherited original brief. Do not separately inject it into
unrelated work or install it as standing instructions.

```text
Use the current host's native file tools for local edits. Use git for local
branches, commits, fetches, and remote branch transport, including git push.
Do not replace git push with MCP push_files or recreate local commits via MCP.
Use this session's exposed Magpie GitHub MCP tools for pull requests, issues,
reviews, comments, labels, and reviewers. Do not use gh, origin, or any other
GitHub/Forge CLI, or fall back to the GitHub HTTP API. Do not build a client.
If a required MCP tool is missing or fails, mark that action BLOCKED and report
the missing capability or error. Local work and git push may continue. Create
a PR only after git push succeeds, and report a PR only when the MCP create
call returns it. Discover the actual tool names and schemas in this session.
```

This route overrides upstream forge tool selection only during this explicit
invocation and its necessary handoffs. PStack still determines PR timing,
contents, lifecycle, review, and resumption. Add no adapter-specific permission
system, draft policy, phase gate, checklist, or comment cadence.
