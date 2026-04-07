# Test Plan — [FEATURE_NAME]

**Author**: [AUTHOR]
**Status**: [Draft / In Review / Approved]
**References**: [PRD](./01_PRD.md), [Technical Design](./03_technical-design.md), [Test Strategy](../../_common/test-strategy.md), [Traceability Matrix](./05_traceability-matrix.md)
**Created**: [DATE]

> Strategy, pyramid, environments, global entry/exit criteria → [`_common/test-strategy.md`](../../_common/test-strategy.md)
> This document contains only feature-specific test cases and any deviations.

## Scope

**In scope:** FRs in `01_PRD.md` + regression from `02_change-impact.md`

**Out of scope:**
- [OUT_OF_SCOPE_ITEM]

## Feature-specific entry criteria (OPTIONAL - if beyond global criteria) ⚠️

> In addition to global criteria in `test-strategy.md`:
- [ ] [ENTRY_CRITERION]

## Feature-specific exit criteria (OPTIONAL - if beyond global DoD) ⚠️

> In addition to global DoD in `test-strategy.md`:
- [ ] [EXIT_CRITERION]

## Test cases

<!--
  IMPORTANT: Replace sample items below with actual test cases from:
  FRs (01_PRD.md), Endpoints (03_technical-design.md), Business logic, Edge cases.
-->

### Unit

<!-- ACTION REQUIRED: Generate from business logic in 03_technical-design.md. e.g. TC-U-001: Validate title uniqueness | duplicate title | throws CONFLICT -->

| ID | Description | Input | Expected |
| - | - | - | - |
| TC-U-001 | [TEST_DESCRIPTION] | [INPUT] | [EXPECTED] |

### API / Integration

<!-- ACTION REQUIRED: Generate from endpoint list. Cover all status codes (200, 201, 400, 401, 403, 404). e.g. TC-A-001: GET /tasks + auth → 200; TC-A-002: GET /tasks no auth → 401 -->

| ID | Method | Path | Auth | Input | Expected status |
| - | - | - | - | - | - |
| TC-A-001 | `[METHOD]` | `[PATH]` | [AUTH] | [INPUT] | [STATUS] |

### E2E (OPTIONAL - for significant user-facing changes) ⚠️

<!-- ACTION REQUIRED: Generate from acceptance criteria in 01_PRD.md. e.g. TC-E-001: User creates task → task visible in list -->

| ID | Journey | Expected outcome |
| - | - | - |
| TC-E-001 | [JOURNEY_DESCRIPTION] | [EXPECTED_OUTCOME] |

### Performance (OPTIONAL - only if NFR exists) ⚠️

| ID | Scenario | Tool | Pass criteria |
| - | - | - | - |
| TC-P-001 | [SCENARIO] | [TOOL] | [CRITERIA] |

### Regression (OPTIONAL - only if existing features affected) ⚠️

> From `02_change-impact.md`

| Feature | Suite | Required |
| - | - | - |
| [EXISTING_FEATURE] | [SUITE_PATH] | 100% pass |
