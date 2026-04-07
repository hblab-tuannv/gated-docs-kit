---
name: docs-01-bootstrap
description: This skill should be used when the user asks to "bootstrap docs", "initialize docs", "init docs/_common", "set up project documentation", "populate _common files", or wants to one-time initialize the project-level documentation in docs/_common/ (architecture, api-conventions, test-strategy, security-baseline, glossary, review-gates) by analyzing the codebase. Run once per project before any feature documentation.
compatibility: Requires docs/_common/ directory with template placeholders to populate
metadata:
  scope: project-level
  output_dir: docs/_common/
  runs_once: true
---

# Docs Bootstrap Skill

Initialize project-level documentation in `docs/_common/` by analyzing the codebase. This is a one-time setup that populates six baseline documents that all per-feature docs reference.

## When to Use

Trigger this skill when:
- Starting documentation for a new or existing project for the first time
- The `docs/_common/*.md` files still contain placeholders like `[VERSION]`, `[CLIENT_TYPE]`, `[VALIDATION_LIBRARY]`, etc.
- The user asks to "bootstrap", "initialize", "set up", or "populate" project-level docs

Do NOT use when:
- `docs/_common/` files are already populated with real values (use targeted updates instead)
- The user is working on a single per-feature document (use `docs-03-prd`, `docs-05-technical-design`, etc.)

## Input

```text
$ARGUMENTS
```

Optional arguments may include: `--only architecture,api`, `--force`, `--dry-run`. If empty, populate ALL six files.

## Files to Populate

| Order | File | Source of truth in codebase |
| - | - | - |
| 1 | `docs/_common/architecture.md` | Project structure, framework config, docker-compose, infra files |
| 2 | `docs/_common/api-conventions.md` | Server config, middleware, error handlers, shared utilities |
| 3 | `docs/_common/security-baseline.md` | Auth config, validation libraries, security middleware, OWASP coverage |
| 4 | `docs/_common/test-strategy.md` | Test config files, CI pipeline, existing test suites |
| 5 | `docs/_common/glossary.md` | Domain terms from codebase, entity names, README, existing PRDs |
| 6 | `docs/_common/review-gates.md` | Team workflow (CODEOWNERS, PR templates, branch protection rules) |

## Pre-Execution Checks (MANDATORY)

> **Critical**: Run this script BEFORE generating any content. It is a deterministic check that gates the workflow. Do not skip even if you "think" you know the answer.

### Check 1 — Current state of `_common/` files

```bash
.docs-scripts/check-bootstrap.sh --json
```

Parse JSON output:

- `.status == "ok"` → all 6 files are already populated. Report to user and STOP unless `--force` was passed in `$ARGUMENTS`.
- `.status == "partial"` → some placeholders remain. Continue but only fill files where `.files[].placeholders > 0`.
- `.status == "missing"` → at least one file is absent. Continue and create from template.

Use `.files[]` to know exactly which files need work. Never re-write a file that already has `placeholders == 0`.

## Workflow

### Step 1: Detect project type and stack

Before generating content, gather facts about the codebase by running these in parallel:

- `Glob` for `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `pom.xml`, `Gemfile`, `composer.json`, `*.csproj`
- `Glob` for `docker-compose*.yml`, `Dockerfile`, `kubernetes/`, `terraform/`, `infra/`
- `Glob` for `.github/workflows/*.yml`, `.gitlab-ci.yml`, `Jenkinsfile`, `azure-pipelines.yml`
- `Glob` for `tsconfig.json`, `jest.config.*`, `vitest.config.*`, `playwright.config.*`, `pytest.ini`, `phpunit.xml`
- `Read` the top-level `README.md` if present

Record findings: language, framework, database, test runner, CI provider, container/infra strategy.

### Step 2: Delegate codebase analysis

For deep analysis, dispatch the `docs-codebase-analyzer` agent (if installed) with the request:

> Analyze this codebase and report: (1) system architecture diagram in mermaid, (2) layer responsibilities, (3) auth/RBAC model, (4) observability signals, (5) API base URLs per environment, (6) error response shape, (7) error codes, (8) pagination strategy, (9) input validation library, (10) password hashing algorithm, (11) test runner + coverage targets, (12) CI pipeline gates, (13) domain terms with definitions.

If the agent is unavailable, fall back to direct exploration via `Grep` and `Read`.

### Step 3: Populate each `_common/` file

For each target file, follow this pattern:

1. **Read template** — `Read docs/_common/<file>.md`
2. **Identify placeholders** — Locate every `[PLACEHOLDER]`, every `<!-- ACTION REQUIRED -->` block
3. **Map evidence** — For each placeholder, find the supporting code/config (cite paths and line numbers internally for verification, but output clean prose)
4. **Edit in place** — Use `Edit` (not `Write`) to replace placeholders one by one, preserving the existing structure, headings, and order
5. **Mark unknowns** — If no evidence exists for a placeholder, leave the placeholder and add a `> NEEDS EVIDENCE: <what to look for>` line above it. Do NOT invent values.
6. **Update metadata header** — Set `**Version**: 1.0.0` and `**Last Amended**: <today>` at the top

### Step 4: Cross-link verification

After all six files are written, verify cross-references are valid:

- `architecture.md` → references `api-conventions.md` (relative path)
- `technical-design.md` template → references `api-conventions.md`, `architecture.md`, `security-baseline.md`
- `test-plan.md` template → references `test-strategy.md`
- `review-gates.md` → references `security-baseline.md`, `test-strategy.md`

Run `Grep` for each link to ensure target files exist.

### Step 5: Report

Output a summary table:

```text
| File                      | Status      | Placeholders left | Notes                |
| ------------------------- | ----------- | ----------------- | -------------------- |
| architecture.md           | ✅ Populated | 0                 | -                    |
| api-conventions.md        | ⚠️ Partial  | 2                 | NEEDS EVIDENCE: ...  |
| security-baseline.md      | ✅ Populated | 0                 | -                    |
| test-strategy.md          | ✅ Populated | 0                 | -                    |
| glossary.md               | ⚠️ Partial  | 5                 | Add domain terms     |
| review-gates.md           | ✅ Populated | 0                 | -                    |
```

End the report with:
> **Next step**: Use `docs-02-feature-new` to scaffold your first feature folder.

## Post-Execution Validation (MANDATORY)

> **Critical**: After populating files, re-run the bootstrap check to verify your work.

```bash
.docs-scripts/check-bootstrap.sh --json
```

Compare before vs after:

- All files you populated should now show `placeholders == 0`
- `.summary.complete` should equal 6 (or 6 minus any files where `> NEEDS EVIDENCE` markers were intentionally left)
- If any file is still `partial`, list the remaining placeholders and explain why they could not be filled

Do **NOT** mark the skill as complete if `.summary.complete < 6` and no `> NEEDS EVIDENCE` rationale exists in the file.

## Quality Standards

- **Evidence-based**: Every populated value must trace to a real file in the codebase. Cite the source file path internally as proof to yourself.
- **No hallucination**: If unsure, mark `> NEEDS EVIDENCE` and leave the placeholder.
- **Preserve structure**: Never reorder sections, never remove headings, never change table column counts.
- **Idempotent**: Re-running this skill on partially-populated files should only fill remaining placeholders, not overwrite human edits.
- **Vietnamese friendly**: If the codebase uses Vietnamese identifiers/comments, preserve them in glossary.md verbatim.

## Edge Cases

| Situation | Action |
| - | - |
| `docs/_common/` missing | Stop. Tell user to restore from VCS (`git checkout docs/_common/`) or recreate from a sister project |
| Monorepo with multiple apps | Ask user which app to document, OR generate one section per app |
| Greenfield project (no code yet) | Populate from `README.md` + project spec, mark architecture/API as `> NEEDS EVIDENCE: not yet implemented` |
| Mixed-language project | Document each language's stack in its own table row, do not collapse |
| No CI configured | Mark CI gate fields with `> NEEDS EVIDENCE: no CI configured yet` |

## Output

The skill produces:
- Updated files in `docs/_common/` (in-place edits)
- A summary report in chat
- A pointer to `docs-02-feature-new` as the next step

Never create files outside `docs/_common/` from this skill.
