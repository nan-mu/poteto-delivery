---
name: poteto-delivery
description: Thin delivery wrapper around the installed PStack poteto-mode. Use when the user hands over a Markdown task book (任务书) to build, fix, or change a repo and wants it run in an isolated agent/* worktree with a continuously rechecked .audit requirements checklist and a single Draft PR as the live delivery channel. Adds only worktree/branch init, .audit consistency checks, and GitHub PR stage sync/final delivery. All engineering execution stays in native PStack.
---

# poteto-delivery

A thin wrapper. PStack decides **how** the work is done. This skill decides **where** it runs, **how requirements stay checked**, and **where results are delivered**. Do not build a second orchestration system, task queue, state machine, leader service, or reviewer. Do not copy or modify any PStack skill.

Read [references/github.md](references/github.md) for the GitHub channel and the hard permission boundaries before any remote write.

## Load PStack (required, verifiable)

This skill does not restate PStack's workflow. It loads and runs the installed original.

1. Resolve the install path at runtime, never hardcode a version:
   `jq -r '.plugins["pstack@cursor-plugins"] | sort_by(.version) | last | .installPath' "$CLAUDE_CONFIG_DIR/plugins/installed_plugins.json"` (fall back to `~/.claude/plugins/installed_plugins.json`). Call it `PSTACK`. If absent, stop and tell the user PStack is not installed.
2. Read `PSTACK/docs/harness/claude-code.md` once. It is the official adapter that maps Cursor names to Claude Code and defines how to run another PStack skill: **Read `PSTACK/skills/<name>/SKILL.md` and follow it.** The `Skill` tool refuses `poteto-mode`, `bro`, and most PStack skills (`disable-model-invocation: true`), so Read-and-follow is the supported composition, not a workaround.
3. Read `PSTACK/skills/poteto-mode/SKILL.md` in full, including its Principles index. Follow it for the whole task.
4. Match the task to a playbook and Read `PSTACK/skills/poteto-mode/playbooks/<title>.md`. Copy its steps verbatim into the working list before any task-specific step. Route engineering rules (TDD, review, retry, delegation, models) to PStack, not to this skill.
5. Spawn delegates as `pstack:poteto-agent` per poteto-mode's Subagents section, passing the absolute `PSTACK/skills/poteto-mode/SKILL.md` path in every brief.

Record in `.audit` the resolved `PSTACK` path, version, and playbook used. That record is the evidence PStack ran natively (see [references/audit.md](references/audit.md)). Writing `/pstack:poteto-mode` in a prompt is **not** invocation; the Read of the installed file plus a real `pstack:poteto-agent` spawn is.

## Boundary 1 — before execution

Detail in [references/worktree.md](references/worktree.md) and [references/audit.md](references/audit.md).

1. Inspect the repo, default branch, uncommitted changes, and existing worktrees. Never overwrite another task's uncommitted work.
2. Ensure an isolated worktree on branch `agent/<task-slug>`. Reuse the task's existing worktree/branch/PR on resume; do not recreate. Verify the shell's actual working directory is that worktree before editing.
3. Read the original task book, any later revisions, an existing `.audit`, and project acceptance criteria. Initialize the `.audit` checklist from the user's explicit requirements. Follow an existing `.audit` convention if the repo has one.
4. After the first meaningful real commit, create one Draft PR early (see Boundary 3 and github.md). No empty or fake commits to force a diff.

## Boundary 2 — during execution

1. Recheck the `.audit` checklist at least: before implementation starts, when PStack confirms a substantive phase done, before each commit/push, and before claiming completion. The question is **does the implementation satisfy the original task book**, not merely "does it compile / do tests pass".
2. On a gap, deviation, or weak verification, keep going through PStack. Do not escalate routine technical problems.
3. When a phase with real artifacts and completed verification ends: recheck `.audit`, commit per PStack, push the `agent/*` branch, post one short stage comment on the existing PR (see Boundary 3). Dedupe by head SHA.
4. Escalate to the user in the current T3 thread **only** for the genuine conflicts in [references/audit.md](references/audit.md): mutually unsatisfiable requirements, an established `.audit` constraint that materially conflicts with the task with no revision to resolve it, a goal change beyond authorization, a permission/irreversible-risk block, or evidence exhausted after reasonable investigation. Save work and evidence, log the conflict and candidate resolutions in `.audit`, ask a specific question. Never relax a requirement or fake completion.

## Boundary 3 — GitHub PR delivery

Detail and the permission boundary in [references/github.md](references/github.md). One Draft PR per task, updated in place.

- **Stage comment.** Draft a fact-accurate summary from the real diff, commits, test output, and `.audit`. Then Read `PSTACK/skills/bro/SKILL.md` and apply it to compress the wording. Keep every test conclusion, failure, and evidence link; brevity never removes verifiability. Post one comment per phase; never repeat the same phase at the same head SHA.
- **Final delivery.** After PStack's own verification and review, recheck every task-book item in `.audit`. Confirm requirements met (or explicitly recorded as unmet), real test/demo evidence, independent review not bypassed, clean git state, all deliverables committed. Then push, update the PR description to a full delivery summary (PStack `opening-a-pr` body structure), post a final evidence comment, and mark Ready for Review **only if all required acceptance passes**. Otherwise keep Draft and show why.
- **Ready for Review is not Merge. Merge is performed by the user alone on GitHub.** Never merge, never auto-clean the worktree.

This draft-first lifecycle is a deliberate, recorded override of `opening-a-pr`'s "open every PR ready" line, because the task book assigns the PR lifecycle to this wrapper. Every other `opening-a-pr` rule (Conventional Commits title, `## Why/What changed/Scope/Tradeoffs/Blast Radius/Verification` body, forge resolution) still applies.

## Resume

Do not build a state database. Recover from real artifacts: the T3 thread/worktree binding, PStack's session-pickup playbook, the current worktree and `agent/*` branch, `.audit`, existing commits, and the existing PR. Read them first, diff done vs pending, name the resume point, continue in the same PR. A single model response ending is not task completion. See [references/worktree.md](references/worktree.md).

## Prose

All PR text and user-facing replies follow PStack: Read `PSTACK/skills/bro/SKILL.md` for plain compression and follow poteto-mode's "Writing the reply" and `technical-writing`/`unslop`. Do not invent a separate style system.