# Feature Documentation

## Structure

```structure
docs/
├── _common/                        ← Write once for the whole project
│   ├── api-conventions.md          # Error codes, auth, pagination, timestamps
│   ├── architecture.md             # System diagram, layers, observability, deploy
│   ├── test-strategy.md            # Test pyramid, environments, global DoD
│   ├── security-baseline.md        # OWASP checklist, input validation, auth, data protection
│   ├── glossary.md                 # Unified domain terminology
│   └── review-gates.md             # Review & approval process per gate
│
└── features/
    ├── _template/                  ← Copy this folder for each new feature
    │   ├── 01_PRD.md
    │   ├── 02_change-impact.md
    │   ├── 03_technical-design.md
    │   ├── 04_test-plan.md
    │   ├── 05_traceability-matrix.md
    │   └── 06_ADR-001_[title].md      # Add when needed
    │
    ├── user-auth/                  ← Example existing features
    ├── product-catalog/
    └── checkout-flow/
```

## Starting a new feature

```bash
cp -r docs/features/_template docs/features/[feature-slug]
```

Fill each file. **Do not copy content from `_common`** — link to it instead.

## Common vs per-feature

| Content | Common | Per-feature |
| - | - | - |
| Error codes & format | ✅ `api-conventions.md` | ❌ Do not duplicate |
| Auth scheme | ✅ `api-conventions.md` | ❌ Do not duplicate |
| Pagination format | ✅ `api-conventions.md` | ❌ Do not duplicate |
| Test pyramid & tooling | ✅ `test-strategy.md` | ❌ Do not duplicate |
| Test environments | ✅ `test-strategy.md` | ❌ Do not duplicate |
| Global DoD | ✅ `test-strategy.md` | ❌ Do not duplicate |
| System diagram | ✅ `architecture.md` | ❌ Do not duplicate |
| Layer responsibilities | ✅ `architecture.md` | ❌ Do not duplicate |
| Security checklist | ✅ `security-baseline.md` | ❌ Do not duplicate |
| Domain terminology | ✅ `glossary.md` | ❌ Do not duplicate |
| Review & approval gates | ✅ `review-gates.md` | ❌ Do not duplicate |
| **Feature requirements** | ❌ | ✅ `01_PRD.md` |
| **Feature data model** | ❌ | ✅ `03_technical-design.md` |
| **Feature business logic** | ❌ | ✅ `03_technical-design.md` |
| **Feature API endpoints** | ❌ | ✅ `03_technical-design.md` |
| **Feature test cases** | ❌ | ✅ `04_test-plan.md` |
| **Affected features** | ❌ | ✅ `02_change-impact.md` |
| **FR → Test linkage** | ❌ | ✅ `05_traceability-matrix.md` |

## Workflow

Step 1: Copy `_template` → `docs/features/[name]/`

Step 2: `01_PRD.md`
   └─ Problem, requirements, acceptance criteria, success metrics

Step 3: `02_change-impact.md`
   └─ Greenfield? → "No impact", done
   └─ Has impact? → Map fully before design

Step 4: `03_technical-design.md`
   └─ Only write feature-specific parts
   └─ Link to `_common` instead of copying
   └─ Add sequence diagrams for complex flows
   └─ Check security checklist from `security-baseline.md`

Step 5: `04_test-plan.md`
   └─ Only write test cases, do not repeat strategy

Step 6: `05_traceability-matrix.md`
   └─ Link FR → design section → test case IDs

Step 7: `06_ADR-xxx.md` (when architecture decisions need recording)

Step 8: Implement & test
   └─ Update `05_traceability-matrix.md` as tests pass

## Scope per file by complexity

| File | Simple CRUD | Complex business logic |
| - | - | - |
| `01_PRD.md` | ~20 lines | ~50 lines |
| `03_technical-design.md` | Data model + endpoints | + Business logic flows + Sequence diagrams |
| `02_change-impact.md` | "No impact" or 1 small table | Full analysis |
| `04_test-plan.md` | ~10 test cases | ~30+ test cases |
| `05_traceability-matrix.md` | 4–5 rows | 10–20 rows |
| `06_ADR-xxx.md` | Usually not needed | 1–3 ADRs |
