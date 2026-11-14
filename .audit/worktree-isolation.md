# Audit: worktree-isolation

Task book: user message 2026-11-14, poteto-delivery worktree isolation and T3 binding fix
PStack: /Volumes/SSD/.claude/plugins/cache/cursor-plugins/pstack/0.15.36 v0.15.36, playbook bug-fix
Base: main 4182cce3e678f7721df1a26ec79fde7a81368929  Branch: agent/worktree-isolation  PR: pending (no git remote)

Session binding observed before edits (not a row closure): pwd, git toplevel, and realpath are this worktree. `git worktree list --porcelain` lists it on `refs/heads/agent/worktree-isolation`. `t3_worktree_status` returned attached=true, the same worktreePath, branch `agent/worktree-isolation`, projectWorkspaceRoot `/Volumes/SSD/poteto-delivery`. T3 0.1.9. `hooks/guard.sh` is not referenced from `/Volumes/SSD/.claude/settings.json`.

Local tests after the gate change, separate from the live T3 check. `tests/test-isolation.sh` PASS=44 FAIL=0. `tests/run-local.sh` PASS=19 FAIL=0. `tests/test-e-resume.sh` PASS=5 FAIL=0. `tests/test-c-deviation.sh` PASS=3 FAIL=0, with its pytest-green check skipped because this interpreter has no pytest.

Live T3 check, separate from the temp-repo tests. `scripts/verify-workspace.sh --workspace "$PWD" --branch agent/worktree-isolation --base main --require-cwd "$PWD"` with the `t3_worktree_status` JSON exited 0: `t3_binding=match`, `hook=not-installed`, `base=ok`. A child agent printed the same pwd, toplevel, and branch. `git worktree list` still shows one worktree for this branch. The main checkout stayed clean on `main`.

| # | Requirement (from task book) | Implemented | Verified | Evidence (code/test/artifact) | Open issue |
|---|------------------------------|-------------|----------|-------------------------------|------------|
| 1 | New work starts in an isolated workspace before business edits, on `agent/<task-slug>` | yes | yes | references/worktree.md:3; PASS: verifier accepts worktree A from its cwd | - |
| 2 | T3 creates that workspace with the configured Worktree location, not a hand-picked `/Volumes/SSD/bs/<repo>-<slug>` path | yes | yes | handoff path /Volumes/SSD/.t3/worktrees/poteto-delivery/agent-worktree-isolatio-49f00117637060da; settings worktreesDirectory /Volumes/SSD/.t3/worktrees | - |
| 3 | Exact branch and base may be pre-created, then bound with `existing_worktree` | yes | no | SKILL.md:33 | NOT VERIFIED: existing_worktree launch was not run |
| 4 | Instructions match this machine's T3 0.1.9, not an unverified newer API | yes | yes | SKILL.md:32; handoff branch agent/worktree-isolation, startedFromOrigin false, path under worktreesDirectory | - |
| 5 | Before edits, git toplevel, branch, porcelain worktree list, and cwd are checked | yes | yes | scripts/verify-workspace.sh:78; PASS: wrong require-cwd fails; PASS: wrong branch fails | - |
| 6 | T3 thread binding is checked when the host exposes it. `EnterWorktree` does not count | yes | yes | SKILL.md:35; PASS: omitted t3-status is unverified | - |
| 7 | If this thread cannot rebind, open a new bound thread. If that is impossible, stop before edits | yes | no | SKILL.md:33 | NOT VERIFIED: this thread could rebind, so the stop path was not run |
| 8 | Resume reuses the same worktree, branch, and PR. No second worktree for the same task | yes | no | porcelain lists one agent/worktree-isolation worktree; PASS: second worktree add for the same branch fails | PR reuse NOT VERIFIED: no PR |
| 9 | Subagents inherit the verified cwd. A separately isolated subagent is verified on its own | yes | no | child pwd and branch matched this worktree | isolated subagent NOT VERIFIED |
| 10 | A workspace mismatch does not fall back to the main checkout | yes | yes | SKILL.md:34; PASS: workspace that is not the worktree fails | - |
| 11 | Other repos' worktrees are not migrated, deleted, or cleaned | yes | no | SKILL.md:38; main checkout still clean | the three research worktrees were not located, so their state is NOT VERIFIED |
| 12 | A non-T3 Claude session uses Claude's own worktree and is not described as T3-managed | yes | no | SKILL.md:35; references/worktree.md:32 | EnterWorktree NOT VERIFIED |
| 13 | A read-only verifier takes workspace, expected branch, and base. Failure exits non-zero | yes | yes | scripts/verify-workspace.sh:1; PASS: verifier does not change git state; PASS: wrong branch fails | - |
| 14 | Missing T3 binding is the status `unverified` and is not a successful result | yes | yes | PASS: omitted t3-status is unverified; PASS: attached false is unverified | - |
| 15 | Zero requirement rows do not pass `audit-check.sh` | yes | yes | scripts/audit-check.sh:50; PASS: header-only audit is invalid | - |
| 16 | An obviously invalid checklist fails `audit-check.sh` | yes | yes | PASS: prose audit is invalid; PASS: short audit row is invalid | - |
| 17 | Hook text matches real enablement. An uninstalled `guard.sh` is not described as enforced | yes | yes | live verifier hook=not-installed; PASS: settings without hooks prints hook=not-installed | - |
| 18 | Two parallel tasks use different worktrees and do not clobber each other | yes | yes | PASS: worktree files do not appear in the other tree; PASS: status for B does not accept worktree A | - |
| 19 | A pre-existing uncommitted file in the original repo is unchanged | yes | yes | PASS: main uncommitted bytes stay put and are not copied | - |
| 20 | Wrong cwd, wrong branch, and wrong path are rejected | yes | yes | PASS: wrong require-cwd fails; PASS: wrong branch fails; PASS: workspace that is not the worktree fails | - |
| 21 | Symlinks and path aliases do not flip the isolation judgment | yes | yes | PASS: symlink and dot segments pass with the worktree realpath; PASS: symlink to the main checkout fails for the agent branch | - |
| 22 | Live T3 binding, cwd, and git worktree agree, including resume and a subagent | yes | yes | live verifier result=pass t3_binding=match; child agent cwd and branch matched; one worktree for this branch | - |
| 23 | Simulated tests and the live T3 check are reported separately. Unrun checks stay `NOT VERIFIED` | yes | yes | this file separates the temp-repo runs from the live T3 check; rows 3, 7, 8, 9, 11, 12, 24, 25 stay open | - |
| 24 | PStack load, TDD, review, delegation, and PR delivery still behave as before | yes | no | SKILL.md load steps and Boundary 3 unchanged; this session read poteto-mode and spawned pstack:poteto-agent | PR delivery NOT VERIFIED: no remote |
| 25 | Skill source is pushed to the user-supplied remote and the remote SHA is confirmed | no | no | — | no remote URL yet |
