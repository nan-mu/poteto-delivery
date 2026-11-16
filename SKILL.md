---
name: poteto-delivery
description: Explicit entry point for handing a repository task to the installed PStack poteto-mode, with native T3 workspace binding when running in T3 Code. Run only when the user invokes /poteto-delivery.
disable-model-invocation: true
---

# poteto-delivery

Adapt the entry, then let PStack own the task. Apply these entry steps only to
this explicit invocation, including its native T3 continuation. Do not activate
for task books, ordinary messages, other skills, or subagents on your own.

## Resolve the installed upstream

1. Keep the user's task, revisions, repository, and authorization intact.
2. Resolve PStack from the current session's registered plugin location. If that
   location is unavailable, inspect `plugins/installed_plugins.json` under the
   active `CLAUDE_CONFIG_DIR`, or `~/.claude` only when that variable is unset.
   Match the enabled installation and its scope to the current project using
   the applicable Claude settings. Do not select an arbitrary cached copy or
   sort version strings to choose an installation. If the installation is
   missing, disabled, or ambiguous, report the dependency problem and stop.
3. Confirm that the resolved root contains `docs/harness/claude-code.md` and
   `skills/poteto-mode/SKILL.md`. Use the installed originals. Do not pin a
   version, download a substitute, copy upstream content, or change PStack.

## Bind the workspace through T3

Outside T3, skip this section and leave workspace handling to PStack and the
host. Inside T3, use the tools actually exposed by the current session. Read
their current descriptions and schemas; an MCP prefix can vary. Missing T3
tools in a known T3 session are a capability problem, not a non-T3 fallback.

1. Read `t3_worktree_status`. For repository changes, establish the intended
   task's workspace binding before delegating execution. Reuse an existing
   binding for this task. Check the reported repository, path, and branch
   against the requested task and the actual shell cwd and git checkout with
   native read-only tools. A path or branch alone does not prove task identity.
2. If a suitable task worktree already exists, use T3's exposed native binding
   or thread-launch capability to continue there. Do not create a duplicate.
   Use `t3_worktree_list` when needed to locate an existing checkout.
3. If a new worktree is needed and this thread is unattached, call
   `t3_worktree_handoff` with the intended branch and base, using the live
   schema. Use the user's target branch when specified; otherwise choose an
   unused task branch consistent with repository rules. Let T3 choose the path
   from its configuration. Preserve the user's
   intended base and remote-start choice rather than silently replacing them
   with a different default.
4. Supply `continuationPrompt` with the task and its revisions, authorization
   limits, repository and intended base, the GitHub route below, and the
   remaining entry steps. Include task text when its file will not be readable
   from the destination. State that this continues the same explicit
   invocation: recheck the T3 binding, resolve the installed PStack there,
   then delegate once. Call handoff last in the turn; it ends the live
   session. Do not start PStack in the old checkout.
5. If the current binding belongs to another task, or a native operation is
   unavailable, rejected, or leaves a mismatch, report the specific blocker
   before task edits. Do not emulate T3 with shell-created worktrees,
   `EnterWorktree`, configuration edits, or a custom verifier. Do not move or
   clean another task's workspace. A thread launch, when supported, must carry
   the same complete continuation and bind the intended workspace. After a
   successful launch, end the source invocation without executing the task
   there or monitoring the destination thread.

## Delegate once, then end the adapter's role

Read the resolved `docs/harness/claude-code.md` and
`skills/poteto-mode/SKILL.md` in full. Follow the installed harness's composition
method and let poteto-mode run the user's task in the bound workspace. Merely
writing a slash command in a prompt is not execution. Let PStack select and
load its own playbooks and dependencies.

PStack owns classification, orchestration, subagents, models, implementation,
verification, review, decision trails, PR delivery, and task resumption. Do not
restate or override those procedures. Preserve the user's actual authorization
and host rules. Apply the GitHub route below to this invocation. Do not add
any other tool preference.

After delegation, perform no adapter phase checks, monitoring, or cleanup, and
do not re-enter on later messages unless explicitly invoked again. Do not
propagate this skill as standing instructions to delegates or other workflows.
Do not install hooks, global rules, scripts, task state, or default injection.
If an interface gap prevents delegation, report it; do not replace PStack with
a local workflow.

## Route GitHub through Magpie

Apply this route only while this skill is explicitly invoked, including its
T3 continuation. A delegate that pushes, opens or updates a pull request,
comments, or edits issues for this task follows this route. Do not paste the
rest of this skill into that brief. Do not install the route as a hook, a
global rule, or a default for other tasks.

Use the GitHub MCP tools the current session exposes through Magpie. Use git
for branch transport. Do not use `gh`. Do not call the GitHub HTTP API. Do not
hardcode an MCP server implementation, and do not add a GitHub client here.

| Action | Tool |
| --- | --- |
| Edit files | The session's file tools |
| Local branches, `git add`, and `git commit` | git |
| Worktrees | git, or the host worktree tools this skill already names |
| Create or update the remote branch | `git push -u origin <branch>` |
| Create, read, or update a pull request | The session's Magpie GitHub MCP tools |
| Pull request comments | The session's Magpie GitHub MCP tools |
| Issues | The session's Magpie GitHub MCP tools |
| Labels and reviewers | The session's Magpie GitHub MCP tools |

PStack still owns the pull request workflow. Do not copy or rewrite that
playbook. This route only chooses the tool.

Do not use MCP `push_files` in place of `git push`. Do not recreate a local
commit through MCP. Keep the local commit SHA, author, and parents. Create
the pull request only after `git push` succeeds.

If the session does not expose the GitHub MCP tool the action needs, fail
closed. Do not fall back to `gh` or HTTP. Local edits, tests, commit, and
`git push` may continue, and a pushed branch stays. Mark that action
BLOCKED, and name the missing MCP server or tool. A missing
`create_pull_request` tool blocks pull request creation. Never say a pull
request exists unless that MCP call returned it.

Do not impose a checklist, phase gate, branch naming scheme, Draft PR
policy, comment cadence, or permission system.
