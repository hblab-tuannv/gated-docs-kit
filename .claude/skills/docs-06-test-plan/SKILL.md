---
name: docs-06-test-plan
description: This skill should be used when the user asks to "write test plan", "draft test plan", "fill 04_test-plan.md", "generate test cases", "write QA plan", or wants to author/update the Test Plan at docs/features/<feature>/04_test-plan.md. This is Step 4 of the feature documentation lifecycle and feeds the traceability matrix and Gate 4 (QA Sign-off).
compatibility: Requires 01_PRD.md (FRs) and 03_technical-design.md (endpoints, business logic) to exist
metadata:
  step: 4
  output_file: docs/features/<feature>/04_test-plan.md
  prerequisites: 01_PRD.md, 03_technical-design.md
  next_skill: docs-07-traceability
---

# Docs Test Plan Skill

Author or update the Test Plan (`04_test-plan.md`) for a feature. This document enumerates **feature-specific test cases** derived from the PRD's FRs and the technical design's endpoints/business logic. It does NOT restate global testing strategy (that lives in `_common/test-strategy.md`).

## When to Use

Trigger this skill when:
- PRD and technical design are in-review or approved
- The user asks to "plan tests", "list test cases", or "QA prep"
- An existing test plan is missing test cases

Do NOT use when:
- The user wants to write actual test code (this skill plans, doesn't implement)
- PRD or technical design are missing (use `docs-03-prd` / `docs-05-technical-design` first)

## Input

```text
$ARGUMENTS
```

`$ARGUMENTS` may include the feature folder path, optional test layer filters (e.g., `--unit-only`, `--no-perf`), or `--regenerate` to overwrite existing cases.

## Pre-Execution Checks (MANDATORY)

### Check 1 — Prerequisites

```bash
.docs-scripts/check-feature-prereqs.sh \
  --feature "$FEATURE" \
  --requires "01_PRD.md,03_technical-design.md,04_test-plan.md" \
  --json
```

PRD and technical design must exist (preferably ≥ In Review). If not, run prior skills first.

### Check 2 — FRs to cover

```bash
.docs-scripts/parse-prd-frs.sh "$FEATURE_DIR/01_PRD.md"
```

Each FR in `.frs[]` MUST have at least one test case in your output. Coverage is checked in post-validation.

### Check 3 — Endpoints to test

```bash
.docs-scripts/parse-design-endpoints.sh "$FEATURE_DIR/03_technical-design.md"
```

For each endpoint in `.endpoints[]`, generate test cases for ALL applicable status codes (200, 400, 401, 403, 404, 409, 422 as appropriate).

### Check 4 — Existing test cases (avoid duplicates)

```bash
.docs-scripts/parse-test-cases.sh "$FEATURE_DIR/04_test-plan.md"
```

Use `.count.unit`, `.count.api`, etc. to know where to start numbering. New test IDs MUST start at `max(existing) + 1` per layer.

## Workflow

### Step 1: Load context

Read in parallel:

| File | Use |
| - | - |
| `docs/features/<feature>/01_PRD.md` | Extract FRs, NFRs, acceptance criteria |
| `docs/features/<feature>/02_change-impact.md` | Extract regression test list |
| `docs/features/<feature>/03_technical-design.md` | Extract endpoints, business logic methods, sequence flows |
| `docs/features/<feature>/04_test-plan.md` | Target file (existing content to preserve) |
| `docs/_common/test-strategy.md` | Test pyramid, tooling, ID format conventions |

### Step 2: Determine ID prefixes

Read `docs/_common/test-strategy.md` for the project's ID format. Default convention:

| Prefix | Layer |
| - | - |
| `TC-U-XXX` | Unit |
| `TC-A-XXX` | API / Integration |
| `TC-E-XXX` | E2E |
| `TC-P-XXX` | Performance |
| `TC-R-XXX` | Regression |

If the project uses different prefixes, use those. Number cases sequentially within each layer starting from 001.

### Step 3: Decide which test layers apply

| Layer | Required when | Skip when |
| - | - | - |
| Unit | Always (every feature has business logic somewhere) | Pure config change |
| API / Integration | API endpoints exist | Pure internal lib |
| E2E | User-facing UI changes OR critical user journey | Backend-only OR experimental features |
| Performance | NFR with performance metric | No perf NFR |
| Regression | Change impact lists affected components | Greenfield with no impact |

Mark skipped layers for removal.

### Step 4: Generate Unit test cases

For each non-trivial method documented in the technical design's "Business logic" section, plus each business rule embedded in FRs, create a unit test case.

For each test case, output a row:
- `ID` — `TC-U-001`, etc.
- `Description` — what's being verified (1 sentence, action-focused)
- `Input` — the specific input scenario
- `Expected` — the expected outcome (return value, exception, side effect)

**Coverage targets per method:**
- Happy path (1+ case)
- Each branch / conditional (1 case each)
- Each validation rule (1 case each)
- Each error condition (1 case each)
- Boundary conditions (empty list, max length string, zero, negative, null)

If unsure about coverage, dispatch `docs-test-generator` agent with the technical design and PRD as input.

### Step 5: Generate API / Integration test cases

For EVERY endpoint listed in the technical design's API section, create test cases covering ALL applicable status codes.

For each endpoint, generate at minimum:

| Status code | When | Always required? |
| - | - | - |
| 200 / 201 | Success | Yes |
| 400 | Validation error | If has request body or params |
| 401 | Missing auth | If endpoint requires auth |
| 403 | Wrong role / forbidden resource | If has authorization |
| 404 | Resource not found | If has path param |
| 409 | Conflict (e.g., duplicate) | If has uniqueness constraint |
| 422 | Semantic error | If business rule rejects valid syntax |

Each row:
- `ID` — `TC-A-001`, etc.
- `Method` — `GET` / `POST` / etc.
- `Path` — backticked endpoint
- `Auth` — `none` / `user` / `admin` / `service`
- `Input` — request body / query summary
- `Expected status` — HTTP code

If endpoints differ in auth, generate auth-failure cases for each.

### Step 6: Generate E2E test cases (if applicable)

For each user story / acceptance criterion in the PRD, write one E2E case capturing the user journey end-to-end.

| ID | Journey | Expected outcome |
| - | - | - |
| TC-E-001 | User signs up → verifies email → logs in → sees dashboard | Dashboard visible with correct user info |

Limit to **critical paths** (3-7 typically). Don't enumerate every variation — that's API/Unit territory.

### Step 7: Generate Performance test cases (only if NFR exists)

For each Performance NFR in the PRD, write one performance test case.

| ID | Scenario | Tool | Pass criteria |
| - | - | - | - |
| TC-P-001 | 1000 concurrent users posting orders | k6 / Locust / JMeter | p95 < 500ms, error rate < 0.1% |

Use the tool from `_common/test-strategy.md` if specified.

### Step 8: Generate Regression checklist

Pull the list of affected features from `docs/features/<feature>/02_change-impact.md` regression checklist. Copy each row into the test plan's regression table:

| Feature | Suite | Required |
| - | - | - |
| User authentication | `tests/api/auth.spec.ts` | 100% pass |

If the change impact says "No impact", remove this section.

### Step 9: Define Scope and Criteria

#### 9.1 In scope
Default: `FRs in 01_PRD.md + regression from 02_change-impact.md`. Customize only if some FRs are explicitly out of scope.

#### 9.2 Out of scope
List FRs being deferred or test types not included (e.g., "Performance testing deferred to follow-up sprint").

#### 9.3 Feature-specific entry criteria (optional)
Only if THIS feature needs additional entry criteria beyond global test-strategy.md. Examples:
- Test database seeded with specific fixture
- Feature flag enabled
- Mock external service running

#### 9.4 Feature-specific exit criteria (optional)
Only if THIS feature needs additional exit criteria beyond global DoD. Examples:
- Specific test coverage target (e.g., "≥90% line coverage on payment module")
- Performance benchmark met
- Manual UAT sign-off received

### Step 10: Write file

Use `Write` to save the file. Preserve template structure exactly:
1. Header
2. Scope (in / out)
3. Entry criteria (optional)
4. Exit criteria (optional)
5. Test cases (Unit → API → E2E → Performance → Regression — skip layers that don't apply)

Set `**Status**: Draft`, today's date.

### Step 11: Self-validate

Check before reporting:

- [ ] Every FR in PRD has at least one corresponding test case (will be cross-checked by traceability matrix)
- [ ] Every endpoint in technical design has at least one Unit + one API test case
- [ ] Every business rule has a unit test
- [ ] Every NFR has a measurable test (perf, security, etc.)
- [ ] Every regression item from change impact appears
- [ ] Test IDs are unique and follow project format
- [ ] No empty sections (skipped sections removed)

### Step 12: Report

```text
✅ Test Plan drafted: docs/features/<feature>/04_test-plan.md

Test cases generated:
  Unit:        <N> cases (TC-U-001 to TC-U-XXX)
  API:         <N> cases (TC-A-001 to TC-A-XXX)
  E2E:         <N> cases
  Performance: <N> cases
  Regression:  <N> existing suites

Coverage check:
  ✅ All <N> FRs have ≥1 test case
  ⚠️  Endpoint POST /orders has no 409 conflict test
  ...

Next step:
  Run /docs-07-traceability to build the FR → test mapping matrix.
```

## Post-Execution Validation (MANDATORY)

### Validation 1 — Structural check

```bash
.docs-scripts/validate-artifact.sh "$FEATURE_DIR/04_test-plan.md" --json
```

### Validation 2 — Verify test count increased

```bash
.docs-scripts/parse-test-cases.sh "$FEATURE_DIR/04_test-plan.md"
```

Compare new `.count.total` against the pre-check value — should be strictly greater.

### Validation 3 — FR coverage cross-check

For each FR in the PRD, verify at least one test case in your output references it (by FR-ID in description, or by targeting the FR's endpoint/business logic). Report any FR without test coverage as a remaining gap.

## Quality Standards

- **Don't restate strategy**: Do not redefine the test pyramid, tooling, or coverage targets — those live in `_common/test-strategy.md`. Only document deviations.
- **Specific inputs**: "valid input" is not a test case. Use "title='Hello', userId=42, status=PENDING".
- **Specific expectations**: "should work" is not an expectation. Use "returns 201 with created object having id field" or "throws ValidationError with code TITLE_TOO_LONG".
- **One concept per test**: Don't bundle "creates user AND sends email AND logs event" — split into 3 cases.
- **Numbered consistently**: TC-U-001, TC-U-002, ... no gaps, no duplicates.
- **Trace back to source**: Every test case derives from an FR or a design element. If you can't justify it, drop it.
- **Realistic**: Don't generate 200 unit tests for a 5-FR feature. Aim for ~3-5x FR count typically.

## Edge Cases

| Situation | Action |
| - | - |
| Feature is purely UI | Skip Unit (or have 1-2 component tests), heavy E2E |
| Feature is purely DB migration | Heavy Unit on migration scripts, single Integration on rollback |
| Feature is a job | Unit on logic, Integration on trigger + idempotency, no E2E |
| Feature has external API integration | Add `### Contract` test cases with mocked responses for 2xx, 4xx, 5xx, timeout |
| FR mentions "should not crash on invalid input" | Generate negative test cases for each input boundary |
| Performance NFR but no tooling specified | Mark TC-P-XXX with `tool=NEEDS CLARIFICATION` and add to open questions |
| Regression checklist is huge (>30 items) | Group by domain, list one row per domain pointing to the suite |

## Output

The skill produces:
- Updated `docs/features/<feature>/04_test-plan.md` with all applicable test cases
- A coverage check report
- A pointer to `docs-07-traceability` as the next step

Never write actual test code from this skill (it's a planner). Never modify files outside the target feature folder.
