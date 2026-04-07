# Test Plan — [FEATURE_NAME]

**Author**: [AUTHOR]
**Status**: [Draft / In Review / Approved]
**References**: [Test Strategy](../../_common/test-strategy.md) · [Traceability Matrix](./05_traceability-matrix.md) |
**Created**: [DATE]
**Updated**: [DATE]
**Version**: [VERSION]

> Strategy, pyramid, environments, global entry/exit criteria → [`_common/test-strategy.md`](../../_common/test-strategy.md)
> This document contains only feature-specific test cases and any deviations.

## Scope

**In scope:** FRs in `01_PRD.md` + regression from `02_change-impact.md`

**Out of scope:**
- [OUT_OF_SCOPE_ITEM]

## Feature-specific entry criteria

> In addition to global criteria in `test-strategy.md`:
- [ ] [ENTRY_CRITERION]

## Feature-specific exit criteria

> In addition to global DoD in `test-strategy.md`:
- [ ] [EXIT_CRITERION]

## Test cases

<!--
  ============================================================================
  IMPORTANT: The test cases below are SAMPLE ITEMS for illustration only.

  Replace with actual test cases based on:
  - FRs from `01_PRD.md`
  - Endpoints from `03_technical-design.md`
  - Business logic rules
  - Edge cases specific to this feature

  DO NOT keep these sample items in the generated test-plan file.
  ============================================================================
-->

### Unit

<!--
  ACTION REQUIRED: Generate from business logic in `03_technical-design.md`.
  Example:
  - TC-U-001: Validate title uniqueness, duplicate title input → throws CONFLICT
  - TC-U-002: Auto-assign category, no category input → default category applied
-->

| ID | Description | Input | Expected |
| - | - | - | - |
| TC-U-001 | [TEST_DESCRIPTION] | [INPUT] | [EXPECTED] |

### API / Integration

<!--
  ACTION REQUIRED: Generate from endpoint list in `03_technical-design.md`.
  Cover all status codes per endpoint: 200, 201, 400, 401, 403, 404, 409.
  Example:
  - TC-A-001: GET /resources with auth → 200
  - TC-A-002: GET /resources without auth → 401
  - TC-A-003: POST /resources valid input → 201
  - TC-A-004: PATCH /resources/:id non-owner → 403
-->

| ID | Method | Path | Auth | Input | Expected status |
| - | - | - | - | - | - |
| TC-A-001 | `[METHOD]` | `[PATH]` | [AUTH] | [INPUT] | [STATUS] |

### E2E

<!--
  ACTION REQUIRED: Generate from user journeys / acceptance criteria in `01_PRD.md`.
  Example:
  - TC-E-001: Create resource (happy path) → Resource visible in list
  - TC-E-002: Edit and save resource → Changes persisted
  - TC-E-003: Delete resource → Resource removed from list
-->

| ID | Journey | Expected outcome |
| - | - | - |
| TC-E-001 | [JOURNEY_DESCRIPTION] | [EXPECTED_OUTCOME] |

### Performance _(skip if no NFR)_

| ID | Scenario | Tool | Pass criteria |
| - | - | - | - |
| TC-P-001 | [SCENARIO] | [TOOL] | [CRITERIA] |

### Regression

> From `02_change-impact.md`

| Feature | Suite | Required |
| - | - | - |
| [EXISTING_FEATURE] | [SUITE_PATH] | 100% pass |
