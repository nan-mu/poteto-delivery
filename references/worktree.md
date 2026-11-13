# Worktree and task branch

Every task runs in its own worktree on `agent/<task-slug>` before any business code changes. `<task-slug>` is a short kebab-case slug of the task (e.g. `agent/interval-bindings`).

## Init / resume (idempotent)

Run `scripts/delivery-state.sh` first. It reports the repo root, default branch, current branch, dirty state, existing `agent/*` worktrees, and any PR for the branch. Decide from real state, never assume.

1. Inspect: `git rev-parse --show-toplevel`, default branch (`git symbolic-ref refs/remotes/origin/HEAD` or `main`/`master`), `git status --porcelain`, `git worktree list`.
2. **Resume first.** If a worktree already exists for `agent/<task-slug>` (or the T3 thread is bound to one), reuse it and its branch and PR. Do not create a second set. For continuing an existing PR, keep its workspace and branch.
3. Otherwise create the worktree. Prefer the host's native mechanism:
   - T3 thread-bound worktree: when launching a dedicated task thread, set its workspace strategy to a worktree; T3 binds it. Within the current session, Claude Code's `EnterWorktree` binds the session to a worktree.
   - To get the exact `agent/<task-slug>` branch name, create it with git, then bind: `git worktree add -b agent/<task-slug> <path> <base>` (base = the default branch, fetched fresh). Then `EnterWorktree` with `path` to enter that existing worktree. `EnterWorktree` with `name` alone picks its own branch name, so use the git-created path when the `agent/` name is required.
4. **Verify cwd.** After binding, confirm `pwd` / `git rev-parse --show-toplevel` is the target worktree and `git branch --show-current` is `agent/<task-slug>`. All edits, tests, and commits happen there. Subagents inherit it.
5. Never overwrite another task's uncommitted changes. If the base branch is dirty with unrelated work, leave it; branch from the committed base, not the dirty tree.

## Do not clean up

Do not delete the worktree or branch when a single agent run ends, and do not auto-clean on completion. Cleanup is a human-gated step (PStack's `worktree-cleanup` playbook). PStack's read-only `PSTACK/skills/poteto-mode/scripts/worktree-audit.sh` can inspect worktree state; reuse it instead of writing a new auditor.

## Resume sources

Recover the resume point from, in order: the T3 thread/worktree binding, PStack's `session-pickup` playbook, the current worktree and branch, `.audit`, `git log`/`git diff` against the base, and the existing PR. Read them, diff done vs pending, name the resume point, and continue. Do not re-run completed work or re-derive the trail.