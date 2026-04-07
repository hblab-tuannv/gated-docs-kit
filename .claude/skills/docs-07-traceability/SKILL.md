---
name: docs-07-traceability
description: This skill should be used when the user asks to "build traceability matrix", "update traceability", "fill 05_traceability-matrix.md", "map FRs to tests", "check FR coverage", or wants to author/update the Traceability Matrix at docs/features/<feature>/05_traceability-matrix.md. This is Step 5 of the feature documentation lifecycle and gates Gate 4 (QA Sign-off).
compatibility: Requires 01_PRD.md, 03_technical-design.md, and 04_test-plan.md to exist
metadata:
  step: 5
  output_file: docs/features/<feature>/05_traceability-matrix.md
  prerequisites: 01_PRD.md, 03_technical-design.md, 04_test-plan.md
  gate: G4
  next_skill: docs-08-adr or docs-09-review-gate
---

# Docs Traceability Skill

Build or update the Traceability Matrix (`05_traceability-matrix.md`) — a living document that maps every Functional Requirement to its design section, implementation endpoint, and test cases. **Gate 4 requires every FR to reach ✅ before merge.**

## When to Use

Trigger this skill when:
- PRD, technical design, and test plan are all drafted (or any one is updated)
- The user asks for FR coverage, test traceability, or matrix
- Gate 4 (QA Sign-off) is being prepared

Do NOT use when:
- Source artifacts are missing (use the corresponding authoring skills first)
- The user wants to update test results — that happens during test execution, not via this skill

## Input

```text
$ARGUMENTS
```

`$ARGUMENTS` may include the feature folder path or `--update-status` to refresh test pass/fail status from a CI report (if available).

## Pre-Execution Checks (MANDATORY)

### Check 1 — All source artifacts present

```bash
.docs-scripts/check-feature-prereqs.sh \
  --feature "$FEATURE" \
  --requires "01_PRD.md,03_technical-design.md,04_test-plan.md,05_traceability-matrix.md" \
  --json
```

All 4 source artifacts must exist. If any is missing, run the corresponding skill first.

### Check 2 — Parse all sources to feed the matrix

Run these in parallel:

```bash
.docs-scripts/parse-prd-frs.sh "$FEATURE_DIR/01_PRD.md"
.docs-scripts/parse-design-endpoints.sh "$FEATURE_DIR/03_technical-design.md"
.docs-scripts/parse-test-cases.sh "$FEATURE_DIR/04_test-plan.md"
```

Use the JSON outputs as **deterministic source of truth**:

- `.frs[]` from PRD → row IDs in matrix
- `.endpoints[]` from design → endpoint column values
- `.tests.unit[]`, `.tests.api[]`, etc. → test ID candidates for mapping

The skill body shows how to combine these into matrix rows. Do NOT re-parse the markdown manually — trust the script output.

## Workflow

### Step 1: Load all source artifacts

Read in parallel:

| File | Extracts |
| - | - |
| `docs/features/<feature>/01_PRD.md` | Functional Requirements (FR-001, FR-002, ...) |
| `docs/features/<feature>/03_technical-design.md` | Section names, endpoint table |
| `docs/features/<feature>/04_test-plan.md` | Test case IDs (TC-U-XXX, TC-A-XXX, TC-E-XXX, ...) |
| `docs/features/<feature>/05_traceability-matrix.md` | Existing rows to preserve status |

### Step 2: Parse FRs from PRD

Extract every FR from the PRD's Functional Requirements table. For each:
- `FR ID` (e.g., FR-001)
- `Requirement` (the short description, max 60 chars; truncate with ... if longer)
- `Priority` (P0/P1/P2)

Build an internal list. Verify there are no gaps in numbering (FR-001, FR-003 with no FR-002 = error).

### Step 3: Map each FR to design section

For each FR, scan the technical design and identify which section(s) implement it. Look for:
- Direct mention of FR-XXX in section headers or paragraphs
- Implicit mapping (e.g., FR-005 "users can update profile" → §API §Authorization rows)
- Business logic methods that satisfy the FR

Result format: `§Business logic`, `§API`, `§Data model: User`, etc. Use the closest matching section heading.

If an FR has no matching design section, that's a coverage gap — flag it.

### Step 4: Map each FR to endpoint(s)

If the design has an API section, identify which endpoint(s) serve each FR.

Examples:
- FR-001 "Create task" → `POST /tasks`
- FR-002 "List tasks" → `GET /tasks`
- FR-003 "Update task" → `PATCH /tasks/:id`
- FR-004 "Process payment offline" → (no endpoint, internal worker) → write `(worker)`
- FR-005 "Display task in UI" → (frontend, no endpoint) → write `(frontend)`

If an FR is API-driven but has no matching endpoint, flag as gap.

### Step 5: Map each FR to test cases

For each FR, find all test cases (across all layers) that verify it. A test case is associated with an FR if:
- The test case description mentions the FR-ID
- The test case targets the endpoint that serves the FR
- The test case targets the business logic method that satisfies the FR

Result is a comma-separated list of test IDs: `TC-U-001, TC-A-003, TC-E-001`.

If an FR has zero tests, that's a critical gap — the gate will fail.

### Step 6: Determine status per FR

For each FR row, set status based on test execution state:

| Status | Meaning |
| - | - |
| ⬜ | No test exists yet |
| 🔄 | Tests exist but not all run / partial pass |
| ✅ | All tests pass |
| ❌ | At least one test fails |

If `--update-status` is passed, attempt to read CI test results from common locations:
- `coverage/coverage-summary.json`
- `test-results/junit.xml`
- `playwright-report/`
- `.test-results.json`

If no CI data is found, preserve the previous status from the existing file. If no previous file, default to ⬜.

### Step 7: Build the matrix

Construct the matrix table with these columns:

| FR ID | Requirement | Design (section) | Endpoint | Test IDs | Status |
| - | - | - | - | - | - |
| FR-001 | Create task | §Business logic | `POST /tasks` | TC-U-001, TC-A-003 | ⬜ |
| FR-002 | ... | ... | ... | ... | ... |

Sort by FR ID ascending. Do not omit any FR.

### Step 8: Calculate coverage stats

Compute:
- `Total FRs` = count of FR rows
- `Have test` = count where Test IDs is non-empty
- `Passing` = count where Status is ✅

Update the Coverage section:

```markdown
## Coverage

| Total FRs | Have test | Passing |
| - | - | - |
| 12 | 12 | 8 |
```

### Step 9: Identify gaps

Generate a list of issues to flag:

1. **Coverage gaps** — FRs with no test cases (Status ⬜ AND Test IDs empty)
2. **Design gaps** — FRs with no design section reference
3. **Endpoint gaps** — API-driven FRs with no endpoint mapping
4. **Failing tests** — FRs with Status ❌
5. **Stale tests** — FRs in 🔄 (not all tests ran)

### Step 10: Write file

Use `Write` to save the matrix. Preserve template structure:
- Header (Status: `Living document`, today's date)
- Reference links to source artifacts
- Gate notice ("Gate: all FRs must reach ✅ before merge to main")
- Matrix table
- Status legend (⬜/🔄/✅/❌)
- Coverage table

### Step 11: Optionally delegate audit

For complex features (>15 FRs or >50 test cases), dispatch the `docs-traceability-auditor` agent to verify the mappings are correct, especially:
- That test descriptions actually verify the FR they're mapped to
- That endpoints actually serve the FR (not just match by name)
- That no test case is mapped to multiple FRs incorrectly

### Step 12: Report

```text
✅ Traceability Matrix updated: docs/features/<feature>/05_traceability-matrix.md

Coverage:
  Total FRs:    12
  Have test:    12 (100%)
  Passing:       8 (67%)

Gaps detected:
  ⚠️  4 FRs in 🔄 (tests not yet run): FR-005, FR-007, FR-009, FR-011
  ❌ 0 failing
  ⚠️  FR-006 has no test cases — coverage gap
  ⚠️  FR-008 missing design section reference

Gate 4 status: ❌ NOT READY
  Required: All 12 FRs at ✅ status
  Current:  8 of 12

Next steps:
  1. Add test cases for FR-006 → /docs-06-test-plan
  2. Run failing tests to update statuses
  3. Run /docs-09-review-gate G4 once all FRs are ✅
```

## Post-Execution Validation (MANDATORY)

```bash
.docs-scripts/compute-traceability.sh --feature "$FEATURE"
```

Verify the matrix is consistent with source artifacts:

- `.coverage.total_frs` should match the FR count from PRD
- `.coverage.with_test` should equal the number of FRs that have mapped tests in the matrix
- `.gaps[]` lists FRs missing test mappings — report these to user as remaining work
- `.g4_ready == true` only if all FRs are at ✅ status with no failing tests

If `.g4_ready == false`, report what is needed before Gate 4 can be approved.

## Quality Standards

- **Complete**: Every FR from the PRD must appear as a row. No silent omissions.
- **Honest**: Don't mark ✅ for tests that haven't actually been run. Use 🔄 if uncertain.
- **Bidirectional**: Every test case in the test plan should be reachable from at least one FR. Orphan tests indicate either a missing FR or a useless test.
- **No invented IDs**: Only reference test IDs that actually exist in the test plan. Cross-check before writing.
- **Living document**: Re-running this skill should refresh the matrix without losing existing status if `--update-status` is not used.
- **Sorted**: FRs in ascending ID order; test IDs within a row in ascending order grouped by layer.

## Edge Cases

| Situation | Action |
| - | - |
| FR has no test case | Add row with empty Test IDs and Status ⬜. Flag as gap in report. |
| FR maps to multiple endpoints | List all endpoints comma-separated in the Endpoint column |
| Test case maps to multiple FRs | Repeat the test ID in each FR's row (correct duplication) |
| Test plan has tests with no FR (e.g., infrastructure tests) | Add a `## Out-of-band tests` section listing them with rationale |
| FR is renamed or removed from PRD | Remove the row, do not preserve stale FR-XXX |
| FR ID gap detected (FR-001, FR-003, no FR-002) | Stop and tell user to fix PRD numbering before continuing |
| Status flag `--update-status` but no CI artifacts found | Warn user; preserve existing statuses |
| Greenfield feature, no tests written yet | All rows ⬜; report shows 0% passing; do not block (matrix is allowed to be ⬜ during early development) |

## Output

The skill produces:
- Updated `docs/features/<feature>/05_traceability-matrix.md` with FR → test mapping
- Coverage statistics
- A gap report identifying missing tests or design mappings
- A G4 readiness signal

Never modify other artifacts (PRD, design, test plan) from this skill — it only reads them. To fix gaps, the user must run the corresponding authoring skill.
