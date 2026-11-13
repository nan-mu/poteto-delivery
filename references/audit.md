# .audit — requirement consistency

The wrapper's most important addition. It checks the implementation against the **original task book**, continuously, not just whether code compiles or tests pass.

## Two artifacts, two homes

- **Checklist (committed):** `.audit/<task-slug>.md`. Markdown, version-controlled, the durable requirement record. If the repo already has an `.audit` convention, follow its structure; do not replace it.
- **Decision trail (local):** `.audit/<task-slug>.tsv`. This is PStack's `show-me-your-work` format, reused verbatim. Read `PSTACK/skills/show-me-your-work/SKILL.md` and use its `scripts/log.sh` helper and columns. Keep it out of git by default (add `.audit/*.tsv` to `.gitignore`); commit it only when a reviewer needs the trail to trust the result. Do not restate its columns or invent a second log.

Never write secrets, tokens, or sensitive logs into `.audit` or a PR.

## Checklist format

One line per explicit user requirement. Markdown is enough; no JSON schema or task database.

```markdown
# Audit: <task-slug>
Task book: <path or link to the original task book and any revisions>
PStack: <resolved installPath> v<version>, playbook <title>
Base: <base branch>  Branch: agent/<task-slug>  PR: #<n or "pending">

| # | Requirement (from task book) | Implemented | Verified | Evidence (code/test/artifact) | Open issue |
|---|------------------------------|-------------|----------|-------------------------------|------------|
| 1 | <verbatim or faithful restatement> | no | no | — | — |
```

- **Implemented** and **Verified** are `no` until real evidence exists. Never pre-fill `yes`. Never mark verified from model judgment alone; it needs a real run, test output, or inspected artifact.
- **Evidence** is a pointer: `file:line`, test name + result, commit SHA, artifact path. Not prose.
- Add a row for each acceptance criterion. Record unmet items explicitly; do not drop them.

## Recheck timing

Recheck at least: (1) after investigation, before implementation; (2) when PStack confirms a substantive phase done; (3) before each commit/push; (4) before claiming completion. At each recheck, walk every row against the real artifact and update Implemented/Verified/Evidence. `scripts/audit-check.sh` parses the table and lists rows still `no` or missing evidence, so a gap is mechanical to spot, not a judgment call.

A passing test suite does not close a requirement row unless the test actually exercises that requirement. Test C in the test plan exists to prove this distinction.

## Gaps vs genuine conflicts

- **Gap / deviation / weak verification:** keep working through PStack. Reproduce, read the repo and docs, research high-quality external sources (official docs, papers, source, issues), pick an evidence-backed fix, let PStack implement/verify/review. Record important external evidence URLs and their relevance in `.audit`. Do not escalate routine technical problems or fork a choice into a user question when an experiment can settle it.
- **Genuine conflict — pause and ask in the current T3 thread, only these:**
  1. Task-book requirements cannot all be satisfied at once.
  2. An established `.audit` constraint materially conflicts with the current task and no revision resolves it.
  3. The goal must change beyond the user's authorization.
  4. A required operation needs a permission you cannot obtain, or carries irreversible risk.
  5. Evidence is insufficient to continue after reasonable investigation and verification.

  On a genuine conflict: save current work and evidence, log the conflict + cause + candidate resolutions in `.audit`, ask a specific question in T3. Do not relax a requirement, do not disguise a block as completion. Ordinary failures get as many autonomous fix rounds as needed; no arbitrary fixed retry count.