# Test evidence

Status legend: DONE = verified with real evidence; PENDING = needs a gate; N/A = not applicable here.

## Environment (investigated, read-only)

- PStack 0.15.36, official `cursor/plugins` @ `ec56937`, install path
  `/Volumes/SSD/.claude/plugins/cache/cursor-plugins/pstack/0.15.36` (resolved at runtime from `installed_plugins.json`).
- Composition mechanism: `docs/harness/claude-code.md` line 12 — Read `<pstack>/skills/<name>/SKILL.md` and follow it; the `Skill` tool refuses `disable-model-invocation` skills (`poteto-mode`, `bro`, `show-me-your-work`).
- `.audit/<slug>.tsv` decision-trail convention already exists in `show-me-your-work`; reused, not reinvented.
- `gh` authenticated as `nan-mu` (scopes `repo`, `read:org`, `gist`, `admin:public_key`).
- GitHub MCP `github` registered (user scope, `https://api.githubcopilot.com/mcp/`, toolsets `repos,issues,pull_requests`).

## Skill implementation — DONE

- Source committed `8bfd2d7` on `main` in `/Volumes/SSD/poteto-delivery`.
- Installed via symlink `/Volumes/SSD/.claude/skills/poteto-delivery`. Frontmatter valid, model-invocable.
- Catalog discovery in a fresh T3 session is the remaining confirm (this session created the skill mid-run).

## Local tests — DONE

- `tests/run-local.sh`: PASS=19 FAIL=0 (audit gate, guard deny/allow matrix, delivery-state worktree detection).
- `tests/test-c-deviation.sh`: PASS=4 FAIL=0. Partial impl suite is green (`6 passed`-style), yet `audit-check.sh` flags the missed requirement (exit 1) and closes only after the fix (exit 0). Proves green tests ≠ requirement closure.
- `tests/test-e-resume.sh`: PASS=5 FAIL=0. Resume detects the existing `agent/*` branch/worktree/audit; git refuses a duplicate branch, forcing reuse; original worktree intact.
- `tests/test-d-conflict.md`: protocol dry run. Mutually unsatisfiable requirements route to a `.audit` conflict record + a specific T3 question; no requirement relaxed, no fake completion.

## Test A (normal task) + Test F (PStack native) — DONE

A real `pstack:poteto-agent` delegate ran the clamp task in `/Volumes/SSD/pd-local-test-wt-clamp` (branch `agent/clamp`, no remote):
- Read the installed adapter + full `poteto-mode` SKILL.md + `feature.md` playbook; quoted the adapter's Read-and-follow rule verbatim. Native PStack execution, not a wrapper simulation.
- Implemented `clamp`, 6 tests, mutation checks; commit `bba0074`.
- `.audit/clamp.md` (committed) both rows closed with evidence; `.audit/clamp.tsv` local.
- Independently re-verified: `audit-check.sh` rows=2 open=0 (exit 0); `python -m pytest -q` → `6 passed`; tracked tree clean.
- Delegate honestly logged two gaps (no cross-model trail review and no transcript cross-check, both needing a nested spawn that was forbidden for this bounded test).

## GitHub MCP connection — NOT VERIFIED (honest)

- `claude mcp get github`: "Connected · tools fetch failed — Request timed out".
- No `mcp__github__*` tools loaded in this T3 session.
- Unauthenticated probe of `https://api.githubcopilot.com/mcp/` → HTTP 401 in 1.2s (endpoint reachable; not a network block). `api.github.com` and `gh` work.
- Conclusion: the registered connection's authenticated tools fetch times out. The wrapper falls back to authenticated `gh`. MCP config was NOT modified (out of scope per supplement).

## Test B (GitHub writes: Draft PR / push / comment / update) — DEFERRED by user (2026-11-13)

Requires a user-authorized NON-research test repo. The four authorized repos (`xpost`, `bs`, `libbpf-mcu`, `classifier`) are real research repos; the supplement forbids test PRs/commits there. The user chose to defer test B and accept the local closed loop. No GitHub write was performed or simulated. The real-task PR example (deliverable 5) is deferred with test B. Resume: designate a non-research test repo, then run the wrapper's Boundary 3 against it (gh fallback until the MCP connection is fixed).

## Permissions not yet configured / verified

- MCP tool whitelist and actual GitHub permissions not tightened/confirmed (separate from skill development, per supplement).
- Fine-grained PAT least-privilege scope not verified.
- Three boundaries kept distinct: PAT scope vs MCP exposed tools vs local git/gh credential. The guard hook backstops the deny list but is not a complete policy engine.