---
name: docs-02-feature-new
description: This skill should be used when the user asks to "create a new feature doc folder", "scaffold feature docs", "init feature documentation", "start documenting a new feature", or wants to create the directory structure for a new feature under docs/features/<name>/ by copying the template files. Use this BEFORE writing any individual feature document.
compatibility: Requires docs/features/_template/ to exist with the 6 template files
metadata:
  scope: per-feature
  output_dir: docs/features/<feature-slug>/
  prerequisites: docs/_common/ should be populated (run docs-01-bootstrap first)
---

# Docs Feature New Skill

Scaffold a new feature documentation folder by copying `docs/features/_template/` to `docs/features/<feature-slug>/`. This is the first step before authoring any individual feature document.

## When to Use

Trigger this skill when:
- The user starts a new feature and needs documentation skeleton
- The user says "create docs for feature X", "new feature folder", "scaffold docs"
- A `features/` subdirectory for the feature does not yet exist

Do NOT use when:
- The feature folder already exists (use the appropriate authoring skill: `docs-03-prd`, `docs-05-technical-design`, etc.)
- The user wants to write content for an existing feature folder

## Input

```text
$ARGUMENTS
```

The `$ARGUMENTS` should describe the feature in 1-2 sentences. Example inputs:
- `"User authentication via OAuth2"`
- `"Background job for nightly invoice generation"`
- `"Mobile push notification preferences screen"`

If `$ARGUMENTS` is empty, ask the user for a 1-sentence feature description before proceeding.

## Pre-Execution Checks (MANDATORY)

> **Critical**: This skill delegates the entire scaffolding to a script. Do NOT manually copy files — the script is atomic and handles slug generation, numbering, and metadata.

### Check 1 — `_common/` is bootstrapped

```bash
.docs-scripts/check-bootstrap.sh --json
```

If `.status != "ok"`, warn the user that templates reference `_common/` files. Ask whether to proceed anyway or run `docs-01-bootstrap` first.

### Check 2 — Atomic feature folder creation

```bash
.docs-scripts/create-feature-folder.sh \
  --description "$ARGUMENTS" \
  --json
```

Optional flags:

- `--slug <custom-slug>` — override auto-generated slug
- `--timestamp` — use timestamp prefix (`YYYYMMDD-HHMMSS-slug`) instead of sequential numbering (`001-slug`)
- `--sequential` — explicit sequential numbering (this is the default)
- `--force` — overwrite if folder exists (rare; ask user first)

Parse JSON:

- `.status == "created"` → success. Use `.feature_dir`, `.feature_number`, `.feature_slug`, `.files_created` in your report.
- `.status == "exists"` → folder already exists. Stop and tell user to pick a different slug.
- Any other status → report the error verbatim.

The script handles atomically:

- Slug generation from description (max 4 words)
- Sequential numbering by default; `--timestamp` for `YYYYMMDD-HHMMSS` prefix
- Atomic copy of `_template/` (uses temp dir + rename — no half-states)
- Pre-fill of `[FEATURE_NAME]`, `[AUTHOR]` (from `git config`), `[DATE]` (today)

## Workflow

> **All scaffolding work happens inside `create-feature-folder.sh`** (called from Pre-Execution Checks above). The script handles slug generation, numbering, atomic copy, and metadata pre-fill in one transaction. Do NOT manually re-implement any of those steps here.

### Step 1: Use the script's output to compose the report

Take the JSON returned by `create-feature-folder.sh` and build the user-facing summary using:

- `.feature_dir` — full path to the new folder
- `.feature_number` — the assigned 3-digit number (or timestamp prefix)
- `.feature_slug` — generated/specified slug
- `.numbering_mode` — `"sequential"` or `"timestamp"` (matches the CLI flag passed)
- `.metadata.author`, `.metadata.date`, `.metadata.description` — pre-filled values
- `.files_created` — array of 6 file names copied from the template

Do NOT re-derive any of these values. The script is the source of truth.

### Step 2: Report

Output a summary in this format:

```text
✅ Feature folder created: docs/features/<feature-folder>/

Files scaffolded:
  📄 01_PRD.md                    — Author: <name>, Date: <date>
  📄 02_change-impact.md          — Author: <name>, Date: <date>
  📄 03_technical-design.md       — Author: <name>, Date: <date>
  📄 04_test-plan.md              — Author: <name>, Date: <date>
  📄 05_traceability-matrix.md    — Date: <date>
  📄 06_ADR-001_[title].md        — Author: <name>, Date: <date> (rename via docs-08-adr)

Next steps (in order):
  1. /docs-03-prd                   — Write the Product Requirements Document
  2. /docs-04-change-impact         — Assess impact on existing components
  3. /docs-05-technical-design      — Design the implementation
  4. /docs-06-test-plan             — Plan test cases
  5. /docs-07-traceability          — Build traceability matrix
  6. /docs-08-adr (as needed)       — Record key decisions
  7. /docs-gate G1        — Run PRD review gate when ready
```

## Post-Execution Validation (MANDATORY)

```bash
.docs-scripts/list-features.sh --json
```

Verify the new feature appears in the list with:

- The expected number prefix (matches `.feature_number` from creation)
- All 6 step files (`.steps[]` length should be 5 + ADR placeholder)
- All steps in `state: "draft"` (newly scaffolded, not yet authored)

Report the full feature folder path along with the next-step skills (`docs-03-prd`, etc.).

## Quality Standards

- **Atomic**: Either all 6 files copy successfully or none. If `cp` partially fails, clean up before reporting.
- **No content modification**: Only metadata header fields (`[FEATURE_NAME]`, `[AUTHOR]`, `[DATE]`) are pre-filled. Body content is untouched.
- **Predictable naming**: Slug must be deterministic from the description.
- **Conflict-safe**: Never overwrite an existing folder.

## Edge Cases

| Situation | Action |
| - | - |
| Feature description is in Vietnamese | Translate keywords to English for the slug, but use the original Vietnamese as `[FEATURE_NAME]` |
| Two features with similar names | Append a disambiguator (e.g., `user-auth-google`, `user-auth-github`) |
| Description is too vague (1 word) | Ask for a more descriptive 1-2 sentence feature description |
| `_template/` files have local modifications | Copy as-is — local modifications to template are intentional and should propagate |
| Git working tree dirty | Warn user but allow operation; folder creation is non-destructive to existing files |

## Output

The skill produces:
- A new directory at `docs/features/<feature-folder>/` with 6 template files
- Pre-filled metadata headers in each file
- A summary report with next-step guidance

Never write content outside the new folder. Never modify `_template/` itself.
