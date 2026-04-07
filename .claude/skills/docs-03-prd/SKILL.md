---
name: docs-03-prd
description: This skill should be used when the user asks to "write PRD", "update PRD", "draft requirements", "create product requirements doc", "fill 01_PRD.md", or wants to author/update the Product Requirements Document at docs/features/<feature>/01_PRD.md. This is Step 1 of the feature documentation lifecycle and gates Gate 1 (PRD Review).
compatibility: Requires docs/features/<feature>/01_PRD.md (created by docs-02-feature-new) and optionally docs/_common/glossary.md
metadata:
  step: 1
  output_file: docs/features/<feature>/01_PRD.md
  gate: G1
  next_skill: docs-04-change-impact
---

# Docs PRD Skill

Author or update the Product Requirements Document (`01_PRD.md`) for a feature. This is the first artifact in the feature documentation lifecycle and gates Gate 1 (PRD Review). The PRD captures **WHAT** and **WHY**, never HOW.

## When to Use

Trigger this skill when:
- The user wants to write or update a PRD for a specific feature
- The user provides a feature description and expects requirements captured
- An existing `01_PRD.md` has placeholders or `[NEEDS CLARIFICATION]` markers

Do NOT use when:
- The PRD is already approved (status = `Approved`) — direct the user to amend with a changelog entry instead
- The user is asking about technical implementation (use `docs-05-technical-design`)

## Input

```text
$ARGUMENTS
```

`$ARGUMENTS` may contain:
- Feature description (free text)
- Feature folder path (e.g., `docs/features/003-user-auth-oauth2/`)
- Both

If the feature folder is unspecified, scan `docs/features/*/01_PRD.md` for ones with placeholders, list them, and ask which feature to work on.

## Pre-Execution Checks (MANDATORY)

> **Critical**: Run these scripts BEFORE generating any content. Do not skip.

### Check 1 — Feature folder exists with PRD scaffold

```bash
.docs-scripts/check-feature-prereqs.sh \
  --feature "$FEATURE" \
  --requires "01_PRD.md" \
  --json
```

If `.status != "ok"`, tell user to run `docs-02-feature-new` first and stop.

### Check 2 — Existing PRD state

```bash
.docs-scripts/parse-prd-frs.sh "$FEATURE_DIR/01_PRD.md"
```

Use the JSON output:

- `.frs[]` → existing FR IDs. New FRs MUST start at `max(existing) + 1` to avoid duplicates.
- `.count` → current FR/priority counts.
- `.needs_clarification[]` → unresolved items the user has flagged.
- `.status` → current PRD status. If `Approved`, warn the user that PRD is locked and suggest a changelog entry instead of overwriting.

## Workflow

### Step 1: Locate or scaffold the feature

Run in parallel:
- `Glob` for `docs/features/*/01_PRD.md`
- If `$ARGUMENTS` references a folder, verify it exists with `Read`

If no feature folder exists for this work, suggest running `docs-02-feature-new` first and stop.

### Step 2: Read context

Read these files in parallel (only if they exist):
- `docs/features/<feature>/01_PRD.md` (the target)
- `docs/_common/glossary.md` (for unified terminology)
- `.specify/memory/constitution.md` (for project principles, if present)
- Any existing PRDs in sibling features under `docs/features/*/01_PRD.md` to learn the team's writing style (read up to 2)

### Step 3: Extract feature concept

From `$ARGUMENTS` and any prior conversation context, extract:

| Element | Example |
| - | - |
| **Actors** | Who uses or is affected (e.g., "buyer", "admin", "scheduler service") |
| **Pain** | The problem this solves (e.g., "manual reconciliation takes 4h/day") |
| **Trigger** | Why now (e.g., "compliance deadline Q2", "user complaints up 30%") |
| **Outcome** | What success looks like (e.g., "reduce reconciliation to <30min") |
| **Boundaries** | What's explicitly out-of-scope |

If the user input is too vague to extract these, ask for clarification before drafting. Maximum 3 questions.

### Step 4: Draft each PRD section

The `01_PRD.md` template has these sections (in order):

#### 4.1 Header
- `**Author**`: from `git config user.name` or current user
- `**Status**`: always `Draft` for new PRDs
- `**Created**`: today's date `YYYY-MM-DD`

#### 4.2 Problem
1-2 paragraphs. Use the **Pain + Actors + Why now** triple. Cite real-world evidence if available. Avoid jargon — write so a product owner can understand.

#### 4.3 Solution
1-2 paragraphs describing what is being built (still WHAT, not HOW). Then list **Non-goals** as bullets — features that are explicitly NOT in scope.

#### 4.4 Requirements

**Functional Requirements (FR table)**: Each row has:
- `ID` (FR-001, FR-002, ...)
- `Requirement` — written as "System MUST [verb]" or "Users MUST be able to [verb]"
- `Priority` — `P0` (must-have for launch), `P1` (should-have), `P2` (nice-to-have)

Generate 5-15 FRs typically. Each FR must be:
- **Testable** — a tester can verify pass/fail
- **Atomic** — one capability per FR, not bundled
- **Unambiguous** — no "fast", "secure", "easy" without metric
- **Free of implementation** — no DB names, frameworks, libraries

**Non-Functional Requirements (NFR table)**: Each row has:
- `Category` — Performance / Security / Usability / Reliability / Compliance
- `NFR` — describe the constraint
- `Metric` — measurable target (e.g., "p95 < 200ms", "100% TLS", "WCAG AA")

Skip categories that don't apply.

#### 4.5 Acceptance criteria

For each FR, write 1-3 Given/When/Then scenarios. Cover the happy path AND at least one edge case. Use the table format from the template.

#### 4.6 Success metrics (optional)
Include only if measurable KPIs are known (e.g., "reduce ticket volume by 30% in Q3"). If unknown, remove the section entirely — don't leave placeholders.

#### 4.7 Open questions (optional)
List any unresolved items as a numbered table with owner and status. Only include if there are real open items. Do NOT use this section to dump every minor uncertainty — only blockers for design.

### Step 5: Mark unclear items conservatively

For requirements that genuinely cannot be determined without product input:
- Inline marker: `[NEEDS CLARIFICATION: <specific question>]`
- **Maximum 3 markers** in the entire PRD
- Prioritize by impact: scope > security/privacy > UX > technical detail
- Use reasonable defaults for everything else (and document them in the Solution paragraph)

### Step 6: Write file

Use `Write` (or `Edit` for partial updates) to save `docs/features/<feature>/01_PRD.md`. Preserve the template's section order and headings exactly.

Remove any optional section that does not apply — do NOT leave empty placeholders or `N/A` rows.

### Step 7: Self-validate against G1 checklist

Before reporting completion, check the PRD against the Gate 1 checklist from `docs/_common/review-gates.md`:

- [ ] Problem statement is clear and scoped
- [ ] All FRs have priority assigned (P0/P1/P2)
- [ ] NFRs have measurable metrics
- [ ] Acceptance criteria cover happy path + key edge cases
- [ ] No `NEEDS CLARIFICATION` items remain unresolved (or ≤3 with owner)
- [ ] Success metrics are measurable and realistic (or section removed)
- [ ] Non-goals are explicitly stated

For each unchecked item, list it in the report.

### Step 8: Report

Output:

```text
✅ PRD drafted: docs/features/<feature>/01_PRD.md

Status: Draft
Counts: <N> FRs (<N0> P0, <N1> P1, <N2> P2), <M> NFRs, <K> open questions
Clarifications needed: <K> [NEEDS CLARIFICATION] markers

G1 Checklist preview:
  ✅ Problem clear and scoped
  ✅ FRs prioritized
  ⚠️  NFR "Performance" missing measurable metric
  ...

Next steps:
  1. Resolve open questions / clarifications
  2. Mark Status as "In Review" when ready
  3. Run /docs-04-change-impact to assess impact on existing components
  4. Run /docs-09-review-gate G1 when PRD is ready for review
```

## Post-Execution Validation (MANDATORY)

### Validation 1 — Structural check

```bash
.docs-scripts/validate-artifact.sh "$FEATURE_DIR/01_PRD.md" --json
```

If `.valid == false`, list `.issues[]` and FIX before reporting completion. Common issues:

- `placeholders` count > 0 → fill remaining template tokens
- `too_many_clarifications` → reduce to ≤3 critical clarifications
- `missing_sections` → add the listed sections back
- `status_missing` → set `**Status**: Draft` (or higher) in header

### Validation 2 — Gate G1 preview

```bash
.docs-scripts/compute-gate-verdict.sh --gate G1 --feature "$FEATURE" --json
```

This previews G1 readiness — informational, not blocking. The user runs `docs-09-review-gate G1` for the official verdict. Include `.verdict` and `.summary` in your report so the user knows what is still needed before review.

## Quality Standards

- **WHAT not HOW**: Never mention frameworks, libraries, databases, language, or APIs in the PRD body.
- **Testable FRs**: A QA engineer must be able to write a test case from each FR.
- **Glossary aligned**: Use terms from `docs/_common/glossary.md` consistently. If a new term is needed, suggest adding it to the glossary.
- **No implementation leakage**: Strip "via Postgres", "using React", "JWT-based", "REST endpoint" from FR descriptions.
- **Bounded clarifications**: Maximum 3 `[NEEDS CLARIFICATION]` markers. Use defaults for the rest.
- **Vietnamese friendly**: If the project uses Vietnamese, write the PRD body in Vietnamese. Keep IDs (FR-001, P0) and table headers in English.

## Examples of Good vs Bad FRs

| ❌ Bad | ✅ Good |
| - | - |
| FR-001: Use JWT for auth | FR-001: System MUST authenticate users before accessing protected resources |
| FR-002: Make it fast | FR-002: System MUST return search results within 1 second for 95% of queries |
| FR-003: Save to database | FR-003: System MUST persist user preferences across sessions |
| FR-004: Good UX | FR-004: Users MUST be able to complete checkout in 3 steps or fewer |

## Edge Cases

| Situation | Action |
| - | - |
| PRD already in `Approved` status | Stop. Suggest creating a changelog entry or a new feature folder for the change. |
| Feature is a bug fix, not a feature | Skip Solution + Non-goals. Use Problem + single FR (the fix) + Acceptance criteria. |
| Feature is purely refactor | PRD may be 1 paragraph: motivation + non-functional impact. Recommend ADR instead via `docs-08-adr`. |
| Multiple personas with different needs | Create one User Story / FR per persona, group with `### Persona: <name>` subheadings. |
| Conflicting requirements detected | Flag as `[NEEDS CLARIFICATION: FR-X conflicts with FR-Y on <topic>]` |

## Output

The skill produces:
- Updated `docs/features/<feature>/01_PRD.md` with all sections filled or removed (no empty placeholders)
- A G1 checklist preview report
- A pointer to `docs-04-change-impact` as the next step

Never write files outside the target feature folder.
