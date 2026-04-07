---
name: docs-09-review-gate
description: This skill should be used when the user asks to "run review gate", "check G1", "check G2", "check G3", "check G4", "validate PRD review", "validate design review", "code review check", "QA sign-off check", or wants to execute a review gate checklist from docs/_common/review-gates.md against a feature's documentation. Use at the boundary between lifecycle phases (before design, before code, before merge, before ship).
compatibility: Requires docs/_common/review-gates.md and the relevant feature artifacts depending on which gate
metadata:
  scope: per-feature
  gates: [G1, G2, G3, G4]
  output: gate execution report (no file written by default)
---

# Docs Review Gate Skill

Execute one of the four review gates (G1-G4) defined in `docs/_common/review-gates.md` against a feature's documentation. Each gate is a structured checklist that must pass before the team is allowed to advance to the next lifecycle phase.

## When to Use

Trigger this skill when:
- The user asks to "run gate", "check G1/G2/G3/G4", or "validate before review"
- A feature's PRD/design/code/QA artifacts are ready for review
- Preparing for a formal review meeting

Do NOT use when:
- The user is still drafting an artifact (use the corresponding authoring skill: `docs-03-prd`, `docs-05-technical-design`, etc.)
- The user wants to update the gate definitions themselves (edit `_common/review-gates.md` directly)

## Input

```text
$ARGUMENTS
```

`$ARGUMENTS` should contain:
- `G1`, `G2`, `G3`, or `G4` (the gate number)
- Optionally the feature folder path
- Optionally `--strict` to fail on warnings, `--report-only` to skip file output

Examples:
- `G1 docs/features/003-user-auth-oauth2`
- `G2 user-auth --strict`
- `G4`

If gate is unspecified, ask which gate to run.
If feature is unspecified, list features in `docs/features/*/` and ask which one.

## The Four Gates

| Gate | Phase | Trigger | Required artifacts |
| - | - | - | - |
| **G1 — PRD Review** | Before design | PRD marked "In Review" | `01_PRD.md` |
| **G2 — Design Review** | Before code | Tech design marked "In Review" | `02_change-impact.md`, `03_technical-design.md`, `06_ADR-*.md` (if any) |
| **G3 — Code Review** | Before merge | PR/MR created | Source code, tests, migrations (linked from PR) |
| **G4 — QA Sign-off** | Before ship | Code merged to staging | `04_test-plan.md`, `05_traceability-matrix.md`, test results |

## Pre-Execution Checks (MANDATORY)

### Check 1 — Required artifacts for the requested gate

Map the gate to its required files:

| Gate | Required files |
| - | - |
| G1 | `01_PRD.md` |
| G2 | `01_PRD.md,02_change-impact.md,03_technical-design.md` |
| G3 | All G2 + source code in `src/`/`app/`/`lib/` |
| G4 | All G3 + `04_test-plan.md,05_traceability-matrix.md` |

Then run:

```bash
.docs-scripts/check-feature-prereqs.sh \
  --feature "$FEATURE" \
  --requires "$REQUIRED_FILES_FOR_GATE" \
  --json
```

If `.status != "ok"`, stop and tell user which prereq skill to run first.

## Workflow

> **Primary action**: run `compute-gate-verdict.sh` (in Post-Execution below). The script handles ~70% of checklist items deterministically. Your job in this skill is the remaining ~30% of **semantic** items that require reading the artifacts.

### Step 1: Run the script (in Post-Execution)

The script returns JSON with `.items[]` covering deterministic checks:

- File presence + status field
- Placeholder count + NEEDS CLARIFICATION count
- FR-table presence + priority column completeness
- Migration Up/Down presence
- Authorization section presence (G2)
- Source/test directory presence (G3)
- Hardcoded secrets quick scan (G3)
- Matrix ✅/❌/⬜/🔄 row counts (G4)

Read the script's `.items[]` and use it as the **base report**. Do not duplicate these checks manually.

### Step 2: Add semantic items the script cannot check

For the remaining checklist items in `_common/review-gates.md` that require human/AI judgment, add to the report by reading the relevant artifacts:

- **G1 semantic items**: "Problem statement clear and scoped", "Acceptance criteria cover happy path + edge cases", "Success metrics measurable"
- **G2 semantic items**: "Data model is complete (all entities, fields, constraints)", "API endpoints match FRs", "Sequence diagrams cover non-trivial flows", "Security checklist addressed", "Risk register reviewed"
- **G3 semantic items**: "Code matches approved design", "Tests cover business logic", "Error handling matches conventions"
- **G4 semantic items**: "All test cases executed", "Feature exit criteria met", "No open Critical/High bugs"

For each semantic item:

1. Read the relevant section of the artifact
2. Evaluate as ✅ / ⚠️ / ❌ / ⊘
3. Cite the file:line evidence
4. Suggest a concrete fix for ⚠️ and ❌

Append these items to the script's `.items[]` array in your report.

### Step 3: Reference for semantic evaluation patterns by gate

#### G1 — PRD Review checklist

| Item | How to verify |
| - | - |
| Problem clear and scoped | Check Problem section is non-empty, has actor + pain |
| All FRs have priority | Check Requirements table — every row has P0/P1/P2 |
| NFRs have measurable metrics | Check NFR table — Metric column has numbers/units |
| Acceptance criteria cover happy + edge | Count Acceptance criteria rows per FR ≥ 1, look for at least one edge case |
| No NEEDS CLARIFICATION remain | `Grep` for `NEEDS CLARIFICATION` in PRD |
| Success metrics measurable | Check Success metrics section (or confirmed removed) |
| Non-goals stated | Check Non-goals bullet list under Solution |

For G1, also dispatch optional `docs-review-gate-validator` agent for cross-checking.

#### G2 — Design Review checklist

| Item | How to verify |
| - | - |
| Data model complete | Check Data model section has entities, fields, constraints, relationships diagram |
| Migration backward-compatible | Check Migration has both `-- Up` AND `-- Down`; Down should be safe |
| API endpoints match FRs | Cross-check API endpoint table vs PRD FR list — every API-driven FR has an endpoint |
| Authorization defined for every endpoint | Cross-check Authorization table has a row for every endpoint that needs auth |
| Sequence diagrams cover non-trivial flows | Check Sequence diagrams section exists if business logic has multi-service or async |
| Change impact assessed | Verify `02_change-impact.md` is referenced and breaking changes have migration plans |
| Security checklist addressed | Walk through `_common/security-baseline.md` per-feature checklist; flag unaddressed items |
| ADR for significant decisions | If technical design has phrases like "we chose X over Y", verify a 06_ADR-*.md exists |
| Risk register reviewed | Check `02_change-impact.md` Risk register — no unmitigated High risks |

#### G3 — Code Review checklist

This is the most code-centric gate. Use `Bash`, `Grep`, `Read` on source code:

| Item | How to verify |
| - | - |
| Code matches approved technical design | `Grep` for endpoint paths from design in `src/` — confirm they exist |
| Unit tests cover business logic | `Glob` for test files in `tests/unit/`; check coverage report if available |
| API tests cover all status codes | For each endpoint, find tests with 200, 4xx, 401, 403, etc. |
| No hardcoded secrets | `Grep` for `password.*=`, `api_key.*=`, `token.*=` patterns |
| Input validation at API boundary | `Grep` for validation library usage on endpoint handlers |
| Authorization checks on mutating endpoints | `Grep` for authz decorators/middleware on POST/PATCH/DELETE handlers |
| Error handling follows api-conventions | Compare error responses to `_common/api-conventions.md` shape |
| Logging follows architecture standards | Check log statements match `_common/architecture.md` format |
| No console.log / debug code | `Grep` for `console.log`, `debugger`, `print(`, `dump(` |
| Migration tested | Verify migration files exist and have both up + down |

#### G4 — QA Sign-off checklist

| Item | How to verify |
| - | - |
| All test cases executed | Check test plan vs CI test result count — should match |
| Traceability matrix all FRs ✅ | Read `05_traceability-matrix.md` — every FR row has Status ✅ |
| No open Critical/High bugs | Check issue tracker if available; otherwise rely on user confirmation |
| Regression suite 100% pass | Check regression checklist in test plan — all marked ✅ Pass |
| Feature-specific exit criteria met | Walk through `04_test-plan.md` exit criteria section |
| Global DoD met | Walk through `_common/test-strategy.md` exit criteria |

### Step 4: Compute combined verdict

Take the script's `.verdict` and re-aggregate after adding your semantic items:

- **All ✅** → Gate **PASSED**
- **Any ❌** → Gate **FAILED** (must be fixed before advancing)
- **Any ⚠️** without ❌ → Gate **PASSED WITH WARNINGS** (proceed at reviewer discretion; `--strict` makes this fail)
- All ⊘ + ✅ → Gate **PASSED** (N/A items don't block)

If your semantic items added ❌ that the script missed, the verdict downgrades from script's PASS to FAIL.

### Step 5: Generate report

Output a structured report:

```text
═══════════════════════════════════════════════════════════
  Gate G2 — Design Review
  Feature: docs/features/003-user-auth-oauth2
  Run at: 2026-04-07 14:30
═══════════════════════════════════════════════════════════

Required artifacts:
  ✅ 01_PRD.md (Status: Approved)
  ✅ 02_change-impact.md (Status: In Review)
  ✅ 03_technical-design.md (Status: In Review)
  ⊘ 06_ADR-*.md (no ADRs in this feature)

Checklist results: 7 ✅ / 1 ⚠️ / 1 ❌ / 0 ⊘

  ✅ Data model complete
  ✅ Migration backward-compatible (up + down provided)
  ❌ API endpoints match FRs
     Source: 03_technical-design.md §API
     Issue: FR-005 "Refresh token" has no corresponding endpoint
     Fix: Add POST /auth/refresh to API table

  ✅ Authorization defined for every endpoint
  ✅ Sequence diagrams cover non-trivial flows
  ✅ Change impact assessed
  ⚠️  Security checklist addressed
     Source: security-baseline.md §Authentication
     Issue: "Refresh token rotation" not explicitly addressed in tech design
     Fix: Add note to §API §Authorization or create ADR

  ✅ ADR for significant decisions (none required)
  ✅ Risk register reviewed (no High risks)

VERDICT: ❌ FAILED (1 critical issue, 1 warning)

Required actions before advancing to G3:
  1. Add POST /auth/refresh endpoint to 03_technical-design.md §API
  2. (Recommended) Document refresh token rotation strategy
```

If `--report-only` flag is absent, optionally append the report to a `docs/features/<feature>/.gate-history.md` file (create if missing) for audit trail.

### Step 6: Suggest next action

Based on verdict:

| Verdict | Next action |
| - | - |
| ✅ Passed | Update artifact status to `Approved`. Suggest the next gate (G1→design phase, G2→implementation, G3→QA, G4→ship) |
| ⚠️ Passed with warnings | Show warnings, suggest reviewer discussion, allow manual override |
| ❌ Failed | List required fixes; suggest the authoring skill to fix each (e.g., `/docs-03-prd` to add missing FR) |

## Post-Execution Validation (MANDATORY)

The script below IS the gate evaluation. Run it as the **primary action** of this skill — it returns a structured verdict that you then reformat into a human-readable report.

```bash
.docs-scripts/compute-gate-verdict.sh \
  --gate "$GATE" \
  --feature "$FEATURE" \
  [--strict] \
  --json
```

Parse the JSON:

- `.verdict == "PASS"` → report success, suggest the next gate or ship
- `.verdict == "PASS_WITH_WARNINGS"` → report warnings, allow user to proceed at their discretion
- `.verdict == "FAIL"` → list all `.items[]` where `result == "fail"`, include the `fix` field for each as actionable remediation steps

The script handles **structural** checks deterministically:

- File exists / status field set / placeholders filled
- FRs prioritized / sections present / migration up+down
- Test pass/fail counts in matrix
- Hardcoded secrets quick scan (G3)

For **semantic** checks (does the design actually address the FR? does the test verify the requirement?), the script marks them `na` — you must add AI judgment on top by reading the artifacts and including findings in your final report.

Optionally append the report to `$FEATURE_DIR/.gate-history.md` for an audit trail.

## Quality Standards

- **Evidence-based**: Every checklist verdict must cite a specific line/section from an artifact. No vibes.
- **Actionable failures**: Each ❌ must include a concrete fix, not just "missing".
- **Consistent severity**: Don't downgrade ❌ to ⚠️ to be nice. Honest gate is more useful.
- **Atomic**: Each item is evaluated independently. Don't skip due to "obvious from context".
- **Reproducible**: Re-running on the same artifacts should produce the same verdict (no randomness).

## Edge Cases

| Situation | Action |
| - | - |
| Gate not specified | Ask user which of G1-G4 to run |
| Feature has only some artifacts | Run the gates that apply (e.g., G1 only if PRD exists), report others as "Not yet ready" |
| Reviewer roles in `_common/review-gates.md` are still placeholders | Warn but proceed; the checklist is what matters for automated evaluation |
| Item in checklist mentions external system (issue tracker, CI) | Mark ⊘ with note "requires manual verification" if no API access |
| Gate definition file `_common/review-gates.md` is missing | Stop and tell user to run `docs-01-bootstrap` first |
| Gate definition was customized by team | Use the customized version verbatim, do not assume defaults |
| Same gate run twice (re-validation) | Append to `.gate-history.md` with timestamp; do not overwrite |
| `--strict` flag passed | Treat any ⚠️ as ❌ for verdict purposes |

## Output

The skill produces:
- A console report with checklist verdict per item
- (Optional) An audit entry in `docs/features/<feature>/.gate-history.md`
- A clear PASS / FAIL / PASS-WITH-WARNINGS verdict
- Actionable next steps

Never modify the artifacts being reviewed. Never modify `_common/review-gates.md` (that requires the user). The skill is read-only on artifacts, write-only on the optional gate history file.
