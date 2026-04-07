---
name: docs-04-change-impact
description: This skill should be used when the user asks to "write change impact", "assess impact", "fill 02_change-impact.md", "identify breaking changes", "list affected components", or wants to author/update the Change Impact assessment at docs/features/<feature>/02_change-impact.md. This is Step 2 of the feature documentation lifecycle and is required before locking the technical design.
compatibility: Requires docs/features/<feature>/01_PRD.md (approved or in-review) and docs/features/<feature>/02_change-impact.md scaffold
metadata:
  step: 2
  output_file: docs/features/<feature>/02_change-impact.md
  prerequisites: 01_PRD.md
  next_skill: docs-05-technical-design
---

# Docs Change Impact Skill

Author or update the Change Impact assessment (`02_change-impact.md`) for a feature. This document identifies which existing components, APIs, and tests are touched by the new feature so the team can plan migrations, regression coverage, and risk mitigation BEFORE locking the technical design.

## When to Use

Trigger this skill when:
- An `01_PRD.md` exists for a feature and the user is moving toward technical design
- The user wants to assess "what breaks" or "what's affected"
- A migration plan or risk register is needed

Do NOT use when:
- The PRD does not exist yet (run `docs-03-prd` first)
- The feature is purely greenfield with no existing system to impact (still create the file but mark "No impact")

## Input

```text
$ARGUMENTS
```

`$ARGUMENTS` may include the feature folder path. If not provided, scan `docs/features/*/01_PRD.md` for features missing or with placeholder `02_change-impact.md`, list them, and ask which feature to work on.

## Pre-Execution Checks (MANDATORY)

### Check 1 — PRD prerequisite

```bash
.docs-scripts/check-feature-prereqs.sh \
  --feature "$FEATURE" \
  --requires "01_PRD.md,02_change-impact.md" \
  --min-status "In Review" \
  --json
```

If PRD status is still `Draft`, warn user that change impact may shift after PRD is finalized. Offer to proceed anyway.

### Check 2 — FR list to drive impact analysis

```bash
.docs-scripts/parse-prd-frs.sh "$FEATURE_DIR/01_PRD.md"
```

Use `.frs[]` as the source of truth for what is changing. Every FR MUST be reflected in at least one row of the affected components table — this is checked in post-validation.

## Workflow

### Step 1: Locate context

Read in parallel:
- `docs/features/<feature>/01_PRD.md` (extract FRs to know what changes)
- `docs/features/<feature>/02_change-impact.md` (target file)
- `docs/_common/architecture.md` (component inventory)
- `docs/_common/api-conventions.md` (API patterns to check for breakage)
- Any prior feature folders for similar impact entries (read up to 2 examples)

If `01_PRD.md` is still in `Draft` and has unresolved `[NEEDS CLARIFICATION]` markers, warn the user that change impact may shift after clarifications. Offer to proceed anyway.

### Step 2: Discover affected components

For each FR in the PRD, identify which existing code is touched. Run these in parallel:

- `Grep` for entity names mentioned in FRs across `src/`, `app/`, `lib/`
- `Grep` for endpoint paths if the PRD hints at API changes
- `Glob` for files matching component names in the PRD
- `Read` `docs/_common/architecture.md` to map components to layers

For complex codebases, dispatch the `docs-codebase-analyzer` agent with:

> Find every file/module/endpoint impacted by these requirements: <list of FRs>. Report: (1) directly modified files, (2) shared interfaces/types, (3) downstream consumers of those interfaces, (4) tests covering those areas.

### Step 3: Classify each impact

For every affected component, classify on two axes:

**Impact type** (pick one):
- `Modified` — code/schema is changed
- `Extended` — new methods/fields added, existing untouched
- `Removed` — deprecated and deleted
- `New consumer` — existing component is now called by new code
- `Coupled` — tight integration introduces shared state/lifecycle

**Severity**:
- 🔴 **High** — breaking changes for consumers, requires migration, requires coordinated release
- 🟡 **Medium** — non-breaking but observable change (new fields, deprecated paths still work, perf/behavior change)
- 🟢 **Low** — internal-only change, no consumer impact, isolated

### Step 4: Detect breaking changes

A change is **breaking** if any of these are true:

| Trigger | Example |
| - | - |
| Public API signature changes | Renamed endpoint, removed field, changed type |
| Database column removed/renamed | `users.email` → `users.email_address` |
| Enum value removed | `OrderStatus.CANCELLED` → no longer returned |
| Required field added without default | New `userId` body param on existing POST |
| Behavior change for same input | 200 → 201, idempotent → non-idempotent |
| File format change | v1 JSON → v2 protobuf |
| Removed authorization (privilege escalation) | `admin` → `user` allowed |
| Tightened authorization (lockout) | `user` → `admin` required |

For each breaking change, populate the breaking changes table with:
- `Change` — one-line description
- `Location` — file/module/endpoint path
- `Breaking?` — Yes
- `Migration plan` — concrete steps for consumers (deprecation warning, version bump, dual-write, etc.)

If no breaking changes exist, write `> No breaking changes` and remove the table.

### Step 5: Build regression checklist

For every existing feature potentially affected, identify the test suite:

1. `Glob` for tests in `tests/`, `__tests__/`, `spec/` matching component names
2. Map each affected component to its test suite path
3. List as a table with columns: `Feature`, `Test suite`, `Status` (start as ⬜ Pending)

Aim for completeness over brevity — better to over-test than under-test.

### Step 6: Build risk register (optional)

Only include this section if at least one Medium or High severity item exists. For each risk:

- `Risk` — what could go wrong (data loss, downtime, perf regression, security hole)
- `Severity` — 🔴 / 🟡 / 🟢
- `Mitigation` — what we'll do to prevent or detect (canary, rollback plan, feature flag, monitoring alert)

Drop the section entirely if no notable risks. Do NOT pad with imaginary risks.

### Step 7: Write file

Use `Write` (or `Edit`) to save the file. Preserve template structure exactly:
1. Header with metadata
2. Affected components table
3. Breaking changes section (or "No breaking changes")
4. Regression checklist
5. Risk register (or omitted)

Update header: `**Status**: Draft`, today's date.

### Step 8: Cross-link

Verify the document references `01_PRD.md` correctly via the `**References**` line. If new common files were touched (rare), also reference them.

### Step 9: Self-validate

Check the document against these criteria before reporting:

- [ ] Every FR from PRD is reflected in at least one row of the affected components table
- [ ] Every breaking change has a migration plan
- [ ] Every High/Medium risk has a mitigation
- [ ] Regression checklist covers each affected component's test suite
- [ ] Status header is set to `Draft`

### Step 10: Report

Output:

```text
✅ Change Impact assessed: docs/features/<feature>/02_change-impact.md

Affected components: <N> total
  🔴 High: <N>     🟡 Medium: <N>     🟢 Low: <N>

Breaking changes: <N>
Regression suites: <N>
Risks identified: <N> (with mitigations: <N>)

⚠️ Top concerns to flag in design review:
  - <highlight High severity items>
  - <highlight breaking changes>

Next step:
  Run /docs-05-technical-design to author the technical design,
  which must address each Medium/High item from this assessment.
```

## Post-Execution Validation (MANDATORY)

```bash
.docs-scripts/validate-artifact.sh "$FEATURE_DIR/02_change-impact.md" --json
```

If `.valid == false`, fix the listed issues. Specifically ensure:

- Affected components table has ≥1 row, OR the file says "No impact" for a true greenfield case
- Status field is set (`Draft` minimum)
- No leftover `[PLACEHOLDER]` tokens

## Quality Standards

- **Trace every FR**: Each FR in the PRD must result in at least one row in the affected components table (or be explicitly noted as greenfield with "no impact").
- **Conservative classification**: When in doubt between severities, pick the higher one. Easier to relax later.
- **Concrete migration plans**: "TBD" or "TODO" is not a migration plan. Either write it now or mark `[NEEDS CLARIFICATION: migration owner]`.
- **No phantom impact**: Do not list components that are only tangentially related. If a row has no breaking change AND no new test needed, remove it.
- **Greenfield safe**: Greenfield features get a 1-line "No impact" with the table removed.

## Edge Cases

| Situation | Action |
| - | - |
| Feature is greenfield (new microservice, isolated package) | Replace tables with single line: `> No impact — greenfield feature with no shared data or APIs.` |
| Cross-team API changes | Add a `## Cross-team coordination` section listing stakeholders and required sign-offs |
| Database migration is destructive | Mark severity High, require explicit migration plan with up + down scripts (defer SQL to technical design) |
| Many small impacts (>20 components) | Group by module in the table (one row per module, list affected files in Notes) |
| Existing tests don't cover affected component | Mark in regression checklist with `Status: ❌ Coverage gap — add new tests` |
| Affected component is a third-party dependency | Note in component name `(external: <library>)` and document upgrade plan in risks |

## Output

The skill produces:
- Updated `docs/features/<feature>/02_change-impact.md` with complete impact assessment
- A summary report counting components, breaking changes, risks
- A pointer to `docs-05-technical-design` as the next step

Never modify files outside the target feature folder. Never modify the source code being analyzed.
