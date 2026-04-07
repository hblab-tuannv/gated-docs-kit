# Test Plan — [Feature Name]

| | |
| - | - |
| **Author** | |
| **Status** | Draft · In Review · Approved |
| **Created** | YYYY-MM-DD |
| **References** | [Test Strategy](../../_common/test-strategy.md) · [Traceability Matrix](./traceability-matrix.md) |

> Strategy, pyramid, environments, global entry/exit criteria → [`_common/test-strategy.md`](../../_common/test-strategy.md)
> This document contains only feature-specific test cases and any deviations.

---

## Scope

**In scope:** FRs in `PRD.md` + regression from `change-impact.md`

**Out of scope:**
-

---

## Feature-specific entry criteria

> In addition to global criteria in `test-strategy.md`:
- [ ]
- [ ]

## Feature-specific exit criteria

> In addition to global DoD in `test-strategy.md`:
- [ ]

---

## Test cases

### Unit

| ID | Description | Input | Expected |
| - | - | - | - |
| <!-- AI:FILL --> | | | |

### API / Integration

<!-- AI:FILL — generate from endpoint list in technical-design -->

| ID | Method | Path | Auth | Input | Expected status |
| - | - | - | - | - | - |
| <!-- AI:FILL --> | | | | | |

> _Examples (adapt to actual endpoints):_
> | ID | Method | Path | Auth | Input | Expected status |
> | - | - | - | - | - | - |
> | TC-A-001 | GET | `/resources` | ✅ | | 200 |
> | TC-A-002 | GET | `/resources` | ❌ | | 401 |
> | TC-A-003 | POST | `/resources` | ✅ | Valid | 201 |
> | TC-A-004 | POST | `/resources` | ✅ | Invalid | 400 |
> | TC-A-005 | PATCH | `/resources/:id` | ✅ non-owner | | 403 |
> | TC-A-006 | PATCH | `/resources/:id` | ✅ | Unknown ID | 404 |
> | TC-A-007 | DELETE | `/resources/:id` | ✅ | Already deleted | 404 / 409 |

### E2E

| ID | Journey | Expected outcome |
| - | - | - |
| <!-- AI:FILL --> | | |

> _Examples:_
> | ID | Journey | Expected outcome |
> | - | - | - |
> | TC-E-001 | Create resource (happy path) | Resource visible in list |
> | TC-E-002 | Edit and save resource | Changes persisted |
> | TC-E-003 | Delete resource | Resource removed from list |

### Performance _(skip if no NFR)_

| ID | Scenario | Tool | Pass criteria |
| - | - | - | - |
| <!-- AI:FILL --> | | | |

### Regression

> From `change-impact.md`

| Feature | Suite | Required |
| - | - | - |
| | | 100% pass |
