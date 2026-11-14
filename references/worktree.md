# Worktree and task branch

Every task runs in its own worktree on `agent/<task-slug>` before any business edit. `<task-slug>` is a short kebab-case slug of the task, as in `agent/interval-bindings`.

The shell cwd, the git worktree, and the T3 thread binding are the same directory. `scripts/verify-workspace.sh` checks that. Inside T3, do not edit until it exits 0. Outside T3, `reason=t3-unverified` with `base=ok` and the expected branch is the expected result. Say the workspace is Claude-native, not T3-managed. Any other `reason` means stop.

## Bind

In T3, before any business edit, read `t3_worktree_status`.

If the thread is already attached to this task's `agent/<task-slug>` worktree, reuse that worktree. Do not create another.

If it is not attached, call `t3_worktree_handoff` with branch `agent/<task-slug>` and `baseRef` set to the default branch. Set `startFromOrigin` false when the remote base is not the base you need. A repo with no remote is that case. T3 picks the path under the Worktree location setting. Do not pass a `/Volumes/SSD/bs/<repo>-<slug>` path.

If this thread cannot rebind, create the git worktree only under the T3 worktrees directory as `<worktreesDirectory>/<repoBasename>/<name>`. That path has exactly two segments, so T3 treats it as managed. Cannot rebind means already attached elsewhere, `already_in_worktree`, or `capability_denied`. Launch a new thread with `workspaceStrategy` type `existing_worktree` and that `worktreePath`. If you cannot do that, stop before business edits and say what the user must run.

## Check

After binding, run the verifier from the worktree. Pass the status JSON you just received.

```bash
scripts/verify-workspace.sh \
  --workspace "$PWD" \
  --branch agent/<task-slug> \
  --base <default-branch> \
  --require-cwd "$PWD" \
  --t3-status <status.json>
```

Inside T3, a non-zero exit means stop. Outside T3, stop unless `reason=t3-unverified` and `base=ok` with the expected branch. Do not continue in the main checkout.

`EnterWorktree` is only for a Claude session that is not running inside T3. It is Claude-native and not a T3-managed workspace. Its success does not verify T3 binding.

## Subagents and resume

Subagents inherit this verified cwd. A subagent started with its own worktree must pass the same verifier. On mismatch, stop. Do not fall back to the main checkout.

Resume reuses the existing worktree, branch, and PR. Recover that point from the T3 binding, the worktree, `.audit`, and the existing PR. Do not create a second worktree for the same branch.

Do not migrate, delete, or clean other tasks' worktrees.

## Hook

`hooks/guard.sh` is enforced only when a `settings.json` PreToolUse command points at it. Check. If it does not, say the hook is not installed. Do not claim it blocks anything.
