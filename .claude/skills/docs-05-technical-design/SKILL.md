---
name: docs-05-technical-design
description: This skill should be used when the user asks to "write technical design", "draft tech design", "fill 03_technical-design.md", "design the implementation", "create data model", "design API endpoints", or wants to author/update the Technical Design at docs/features/<feature>/03_technical-design.md. This is Step 3 of the feature documentation lifecycle and gates Gate 2 (Design Review). Captures HOW the feature is built.
compatibility: Requires 01_PRD.md and 02_change-impact.md to exist (preferably in-review or approved)
metadata:
  step: 3
  output_file: docs/features/<feature>/03_technical-design.md
  prerequisites: 01_PRD.md, 02_change-impact.md
  gate: G2
  next_skill: docs-06-test-plan
---

# Docs Technical Design Skill

Author or update the Technical Design document (`03_technical-design.md`) for a feature. This is the engineering blueprint that captures **HOW** the feature is built — data model, API contracts, business logic, sequence diagrams, observability. It gates Gate 2 (Design Review) and is the source of truth for implementation and test plan generation.

## When to Use

Trigger this skill when:
- The PRD and change impact are stable and the team is ready to design
- The user asks for data model, API endpoints, sequence diagrams, or business logic documentation
- An existing technical design has placeholders or open questions

Do NOT use when:
- PRD is not yet drafted (use `docs-03-prd` first)
- Change impact is not assessed (use `docs-04-change-impact` first)
- The user wants to write tests (use `docs-06-test-plan` after this skill)

## Input

```text
$ARGUMENTS
```

`$ARGUMENTS` may include the feature folder path or hints about which sections to focus on (e.g., `--api-only`, `--data-model-only`).

## Pre-Execution Checks (MANDATORY)

### Check 1 — Prerequisites

```bash
.docs-scripts/check-feature-prereqs.sh \
  --feature "$FEATURE" \
  --requires "01_PRD.md,02_change-impact.md,03_technical-design.md" \
  --min-status "In Review" \
  --json
```

If prereqs fail, run the corresponding skills first (`docs-03-prd`, `docs-04-change-impact`).

### Check 2 — FR list (drives endpoint design)

```bash
.docs-scripts/parse-prd-frs.sh "$FEATURE_DIR/01_PRD.md"
```

Use `.frs[]` to ensure every API-driven FR has a corresponding endpoint in the design. The G2 gate checks this match in post-validation.

### Check 3 — Existing design state

```bash
.docs-scripts/parse-design-endpoints.sh "$FEATURE_DIR/03_technical-design.md"
```

Use `.endpoints[]` to avoid duplicating endpoints. Use `.counts.entities` and `.counts.sequence_diagrams` to know which sections of the design are already started.

## Workflow

### Step 1: Load full context

Read in parallel — these are the inputs to the design:

| File | Why |
| - | - |
| `docs/features/<feature>/01_PRD.md` | FRs to satisfy, NFRs as constraints |
| `docs/features/<feature>/02_change-impact.md` | What components are touched, breaking changes to address |
| `docs/_common/architecture.md` | System layout, where this feature plugs in |
| `docs/_common/api-conventions.md` | URL/auth/error/pagination patterns to follow |
| `docs/_common/security-baseline.md` | Security checklist applicable to all features |
| `docs/_common/glossary.md` | Term consistency |
| `docs/features/<feature>/03_technical-design.md` | Target file (existing content to preserve) |
| Sibling features' `03_technical-design.md` | Style/format reference (read up to 2) |

### Step 2: Identify required sections

The technical design template has 9 sections. Determine which are required vs skippable:

| Section | Required when | Skip when |
| - | - | - |
| Overview | Always | Never |
| Data model | DB schema changes | No persistence change |
| API | Endpoints added/changed | No HTTP/RPC interface change |
| Business logic | Non-CRUD logic exists | Pure CRUD pass-through |
| Sequence diagrams | Multi-service / async / complex flows | Simple request-response |
| Frontend | UI changes | Backend-only |
| Observability | Feature-specific signals | Default project signals suffice |
| Open questions | Unresolved items remain | All resolved |

Mark skipped sections for removal — do not leave empty placeholders.

### Step 3: Author the Overview section

1-2 paragraphs. Cover:
- How the feature plugs into the existing system (cite layer/component from architecture.md)
- The headline approach (e.g., "synchronous REST endpoint backed by Postgres + Redis cache")
- Any approach trade-off worth flagging (link forward to ADR if applicable)

Do NOT restate the problem (that's in the PRD).

### Step 4: Author Data Model (if applicable)

#### 4.1 New / modified entities
For each entity:
- Bold name with `_new_` or `_modified_` annotation
- Field table: `Field`, `Type`, `Constraints`, `Notes`
- Mark PK, FKs, nullability, default values, indexes

Use real database types (e.g., `VARCHAR(255)`, `UUID`, `JSONB`, `TIMESTAMP WITH TIME ZONE`). Do NOT use generic `string`/`number`.

#### 4.2 Relationships
Render as Mermaid `erDiagram`. Use:
- `||--o{` for 1:N
- `||--||` for 1:1
- `}o--o{` for M:N

Include only the new and impacted entities — do not redraw the entire schema.

#### 4.3 Migration
Provide both `-- Up` and `-- Down` SQL. Cover:
- `CREATE TABLE` / `ALTER TABLE`
- Index creation
- Data backfill (if needed)
- Reverse operations in `Down`

Validate Down is idempotent and safe to run on partial state.

### Step 5: Author API (if applicable)

#### 5.1 Reference (do not duplicate)
Add a quote block referencing global conventions:
```
> Conventions (auth, errors, pagination) → _common/api-conventions.md
> Full contracts (request/response shapes) → defined in source: <source file path>
> Live spec → <swagger/openapi URL after dev server>
```

#### 5.2 Endpoints table
Columns: `Method`, `Path`, `Description`, `Auth`. List ALL endpoints added or modified for this feature. Use backticks for paths (e.g., `` `POST /api/v1/orders` ``).

#### 5.3 Request/Response notes
Only document **non-obvious** shapes or constraints not expressible in code annotations. Skip standard CRUD shapes. Examples worth documenting:
- Polymorphic response shapes
- Conditional fields (e.g., field present only when role=admin)
- Streaming/chunked responses
- Idempotency keys

#### 5.4 Authorization
Table: `Action`, `Required role`, `Extra check`. One row per non-trivial guard. Use code-formatted role names (e.g., `` `admin` ``). Cite the guard/decorator/middleware location in Notes if helpful.

### Step 6: Author Business logic (if non-CRUD)

For each non-trivial method, write:

```
### `methodSignature(args)`

1. <Step description with validation/side-effects>
2. <Step description>
3. <Conditional branches if any>
```

Use this section to document:
- Domain rules (uniqueness, cascading deletes, soft-delete behaviors)
- State machines
- Business validation order
- Side effects (events emitted, caches invalidated)
- Error conditions and HTTP status mapping

Skip standard CRUD that has no business rules.

### Step 7: Author Sequence Diagrams (selectively)

Create a Mermaid `sequenceDiagram` for each flow that meets ANY of these criteria:
- Multiple services or microservices involved
- Async operation (queue, webhook, scheduled job)
- Complex authentication (token exchange, multi-step OAuth)
- Conditional branching with user-visible difference
- Background job
- External system integration

Use `actor User` for end users. Use `participant <Name>` for services. Show happy path; add `alt`/`else` blocks for branches only when meaningful.

Skip for plain CRUD — they add noise.

### Step 8: Author Frontend (if UI changes)

#### 8.1 Screens table
Columns: `Screen`, `Route`, `Rendering` (SSR/CSR/Static). One row per page or major component.

#### 8.2 Non-standard data flow
Only document if it deviates from `fetch → display → mutate`. Examples worth documenting:
- Optimistic updates with rollback
- Real-time updates (WebSocket, SSE)
- Multi-step wizard with cross-step state
- Offline-first with sync

### Step 9: Author Observability (only feature-specific)

Cite global standards:
> Global signals → `_common/architecture.md`. This section only documents new feature-specific signals.

For each new signal:
- `Signal type`: LOG / METRIC / TRACE / EVENT
- `Event` with payload schema
- `When`: trigger condition

Examples:
- `LOG INFO order.created { orderId, userId, totalCents }` on successful creation
- `METRIC order_processing_seconds` (histogram) emitted around the order pipeline
- `EVENT order.shipped` published to `orders.events` topic

### Step 10: Address security checklist

Walk through the per-feature security checklist from `_common/security-baseline.md` and ensure each applicable item is covered somewhere in the design. If an item is N/A, note why in the technical design. If unaddressed, add a row to Open questions.

### Step 11: Write file

Use `Write` (or `Edit` for partial updates) to save the file.

- Preserve all template headings and order
- Remove any optional section that does not apply (do not leave empty)
- Set `**Status**: Draft` and today's date
- Verify all `**References**` links resolve

### Step 12: Self-validate against G2 checklist

Check against Gate 2 from `_common/review-gates.md`:

- [ ] Data model is complete — all entities, fields, constraints, relationships
- [ ] Migration is backward-compatible (up and down)
- [ ] API endpoints match FRs from PRD
- [ ] Authorization rules defined for every endpoint
- [ ] Sequence diagrams cover non-trivial flows
- [ ] Change impact assessed — breaking changes have migration plan
- [ ] Security checklist addressed
- [ ] ADR created for any significant technical decision

For each unchecked item, list it in the report.

### Step 13: Report

```text
✅ Technical Design drafted: docs/features/<feature>/03_technical-design.md

Sections included:
  ✅ Overview
  ✅ Data model (<N> entities, <M> migrations)
  ✅ API (<N> endpoints)
  ✅ Business logic (<N> non-CRUD methods)
  ✅ Sequence diagrams (<N> flows)
  ⊘ Frontend (skipped — backend only)
  ✅ Observability (<N> signals)

G2 Checklist preview:
  ✅ Data model complete
  ⚠️  ADR-001 needed for choice of <X over Y>
  ...

Open questions: <N>

Next steps:
  1. Resolve open questions
  2. Create ADR(s) if significant decisions exist → /docs-08-adr
  3. Generate test plan → /docs-06-test-plan
  4. Run /docs-09-review-gate G2 when ready for review
```

## Post-Execution Validation (MANDATORY)

### Validation 0 — Ensure status field is set

```bash
.docs-scripts/set-status.sh "$FEATURE_DIR/03_technical-design.md" "Draft" --only-if-unset --json
```

Guarantees `**Status**` is at least `Draft` even on brownfield files. Idempotent; never overwrites an existing valid value like `In Review` or `Approved`.

### Validation 1 — Structural check

```bash
.docs-scripts/validate-artifact.sh "$FEATURE_DIR/03_technical-design.md" --json
```

Fix any issues before reporting.

### Validation 2 — Gate G2 preview

```bash
.docs-scripts/compute-gate-verdict.sh --gate G2 --feature "$FEATURE" --json
```

Report `.verdict` and `.summary` so user sees G2 readiness. Common gaps the script catches:

- Migration missing `-- Up` or `-- Down`
- Endpoints without authorization
- PRD or design status still `Draft`
- Placeholders unfilled
- ADR not created when significant decision detected

Items flagged as `na` are semantic checks that require AI/human judgment — note them in your report.

## Quality Standards

- **HOW not WHAT**: This document describes implementation. The PRD already covered WHAT. Don't restate requirements.
- **Concrete types**: Use real database types, real HTTP status codes, real role names from the codebase.
- **Mermaid valid**: Every Mermaid block must be syntactically valid. Test mentally that brackets/quotes balance.
- **Match codebase style**: Copy the team's existing endpoint conventions (REST vs RPC, kebab-case vs camelCase).
- **No code dump**: Don't paste full implementation. Reference source files instead. The doc captures intent, not full source.
- **Trace to PRD**: Every FR must be implementable from this doc alone. If a reader cannot, add detail.
- **Defer to ADRs**: Significant decisions (e.g., "why Postgres over Mongo", "why cache invalidation by TTL not event") get a 1-line summary here + a full ADR via `docs-08-adr`.

## Edge Cases

| Situation | Action |
| - | - |
| Feature has no DB change | Remove Data model section entirely |
| Feature is internal lib (no API) | Remove API section, add a `### Public API` subsection under Overview describing the function/class signatures |
| Feature is a CLI tool | Replace API section with `### Commands` table: command, args, exit codes, examples |
| Feature is a job/worker | Add `### Trigger` (cron, queue) and `### Idempotency` subsections under Business logic |
| Multiple services/repos | Create one `### Service: <name>` block per service inside relevant sections |
| Significant architectural decision | Document the decision summary + create ADR via `docs-08-adr` |
| Postgres-specific feature in non-Postgres project | Stop and clarify the database from `_common/architecture.md` |

## Output

The skill produces:
- Updated `docs/features/<feature>/03_technical-design.md` with applicable sections only
- A G2 checklist preview report
- Pointers to `docs-08-adr` and `docs-06-test-plan` as next steps

Never write files outside the target feature folder. Never modify source code, only document it.
