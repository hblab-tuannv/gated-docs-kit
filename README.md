# gated-docs-kit

> Gated documentation lifecycle for AI-assisted feature development.
> 9 skills · 4 agents · 13 scripts · 4 quality gates.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Bash 3.2+](https://img.shields.io/badge/bash-3.2%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Claude Code](https://img.shields.io/badge/Claude_Code-skills_%2B_agents-blue.svg)](https://claude.com/claude-code)

`gated-docs-kit` turns `docs/features/<slug>/` into a disciplined documentation lifecycle. Every feature passes through six authoring steps and four quality gates (G1-G4) before it can ship. Claude Code skills handle the *what* and *why*, deterministic bash scripts handle the *did you actually*.

**Core idea**: AI does content generation, scripts do checks. Each lifecycle skill **must** call a script before and after the work — so the workflow cannot be skipped, hallucinated, or vibes-checked.

---

## Why?

Most teams have ad-hoc documentation:

- PRDs drift from technical designs
- Test plans don't trace to requirements
- Code review catches things that should have been caught at design review
- Months later, nobody remembers *why* a decision was made
- AI assistants generate plausible-looking docs that nobody actually verifies

`gated-docs-kit` enforces a structured lifecycle where each step has both an AI skill and a deterministic script. The AI does the writing, the script does the gating.

```text
docs-01-bootstrap        →   _common/ initialized from codebase
       ↓
docs-02-feature-new      →   features/<slug>/ scaffolded atomically
       ↓
docs-03-prd              →   01_PRD.md   ──┐
       ↓                                    │
   ┌── G1: PRD Review ◄────────────────────┘
   ↓
docs-04-change-impact    →   02_change-impact.md
       ↓
docs-05-technical-design →   03_technical-design.md   ──┐
       ↓                              ↓                  │
docs-08-adr (optional)   →   06_ADR-NNN_*.md            │
       ↓                                                  │
   ┌── G2: Design Review ◄───────────────────────────────┘
   ↓
docs-06-test-plan        →   04_test-plan.md
       ↓
docs-07-traceability     →   05_traceability-matrix.md
       ↓
   [implement code + run tests]
       ↓
   ┌── G3: Code Review
   ↓
   ┌── G4: QA Sign-off
   ↓
   🚀 Ship
```

---

## What's inside

| Layer | Count | Where | Purpose |
| - | - | - | - |
| **Skills** | 9 | `.claude/skills/docs-NN-*/SKILL.md` | One per lifecycle step + 4 gates |
| **Agents** | 4 | `.claude/agents/docs-*.md` | Codebase analyzer, test generator, traceability auditor, gate validator |
| **Scripts** | 13 | `.docs-scripts/*.sh` | Deterministic bash + jq for checks/parsing/validation |
| **Templates** | 12 | `docs/_common/*.md` + `docs/features/_template/*.md` | 6 project-level + 6 per-feature |
| **User guide** | 1 | `docs/README.md` | 660-line Vietnamese walkthrough with Mermaid diagram |

### The 9 skills

| # | Skill | Output | Gate |
| - | - | - | - |
| 01 | `docs-01-bootstrap` | `docs/_common/*.md` (one-time init) | — |
| 02 | `docs-02-feature-new` | `features/<slug>/` from `_template/` | — |
| 03 | `docs-03-prd` | `01_PRD.md` | G1 |
| 04 | `docs-04-change-impact` | `02_change-impact.md` | — |
| 05 | `docs-05-technical-design` | `03_technical-design.md` | G2 |
| 06 | `docs-06-test-plan` | `04_test-plan.md` | — |
| 07 | `docs-07-traceability` | `05_traceability-matrix.md` | G4 |
| 08 | `docs-08-adr` | `06_ADR-NNN_*.md` (on demand) | — |
| 09 | `docs-09-review-gate` | Gate verdict report | G1-G4 |

### The 4 quality gates

| Gate | Trigger | Required artifacts | Blocks |
| - | - | - | - |
| **G1** PRD Review | PRD `In Review` | `01_PRD.md` | Cannot start technical design |
| **G2** Design Review | Tech design `In Review` | `02_change-impact.md`, `03_technical-design.md`, ADRs (if any) | Cannot start implementation |
| **G3** Code Review | PR/MR created | All G2 + source code + tests | Cannot merge |
| **G4** QA Sign-off | Code on staging | All G3 + `04_test-plan.md`, `05_traceability-matrix.md` | Cannot ship |

---

## Quick start

### Prerequisites

- macOS or Linux (bash 3.2+ — macOS default ships with this)
- [`jq`](https://jqlang.github.io/jq/) 1.6+ → `brew install jq` or `apt install jq`
- [Claude Code](https://claude.com/claude-code) (any recent version)

### Install

```bash
git clone https://github.com/<your-handle>/gated-docs-kit.git
cd gated-docs-kit
chmod +x .docs-scripts/*.sh
```

### One-time project setup

Open Claude Code in the project, then say (Vietnamese or English):

```text
Bootstrap docs cho project này
```

The `docs-01-bootstrap` skill runs `check-bootstrap.sh`, dispatches the `docs-codebase-analyzer` agent, and populates the 6 files in `docs/_common/` (architecture, api-conventions, security-baseline, test-strategy, glossary, review-gates) with evidence pulled from your real codebase.

### First feature

```text
Tạo feature mới: cho phép user đăng nhập bằng OAuth2
```

The `docs-02-feature-new` skill calls `create-feature-folder.sh`, which atomically scaffolds `docs/features/001-user-auth-oauth2/` with all 6 template files pre-filled with author/date/feature-name. Then continue:

```text
Viết PRD cho feature OAuth2 login
Run G1 cho user-auth-oauth2
Phân tích change impact
Viết technical design
Run G2
Tạo test plan
Build traceability matrix
```

Each command auto-triggers the corresponding skill, which runs its mandatory pre-execution script, generates content, then runs its mandatory post-execution validator.

### Numbering modes

Two modes for `docs/features/<prefix>-<slug>/`:

```bash
# Sequential (default): 001-, 002-, 003-, ...
.docs-scripts/create-feature-folder.sh --description "..."

# Timestamp: YYYYMMDD-HHMMSS-slug
.docs-scripts/create-feature-folder.sh --description "..." --timestamp
```

The two modes coexist — sequential numbering ignores timestamp folders and vice versa.

---

## Architecture

```text
gated-docs-kit/
├── .claude/
│   ├── skills/
│   │   ├── docs-01-bootstrap/SKILL.md       Init _common/
│   │   ├── docs-02-feature-new/SKILL.md     Scaffold feature
│   │   ├── docs-03-prd/SKILL.md             Write PRD
│   │   ├── docs-04-change-impact/SKILL.md   Assess impact
│   │   ├── docs-05-technical-design/SKILL.md Design
│   │   ├── docs-06-test-plan/SKILL.md       Test plan
│   │   ├── docs-07-traceability/SKILL.md    Build matrix
│   │   ├── docs-08-adr/SKILL.md             Record decision
│   │   └── docs-09-review-gate/SKILL.md     Run gate G1-G4
│   └── agents/
│       ├── docs-codebase-analyzer.md        Survey codebase
│       ├── docs-test-generator.md           Enumerate test cases
│       ├── docs-traceability-auditor.md     Audit FR coverage
│       └── docs-review-gate-validator.md    Validate gate evidence
│
├── .docs-scripts/                           Deterministic checks (bash 3.2 + jq)
│   ├── common.sh                            Shared functions
│   ├── check-bootstrap.sh                   Verify _common/ status
│   ├── check-feature-prereqs.sh             Verify prior steps done
│   ├── create-feature-folder.sh             Atomic scaffold
│   ├── validate-artifact.sh                 Section + placeholder check
│   ├── compute-gate-verdict.sh              Run G1-G4 structural checks
│   ├── set-status.sh                        Update **Status** field
│   ├── parse-prd-frs.sh                     Extract FRs → JSON
│   ├── parse-design-endpoints.sh            Extract endpoints → JSON
│   ├── parse-test-cases.sh                  Extract test IDs → JSON
│   ├── compute-traceability.sh              Coverage stats → JSON
│   ├── next-adr-number.sh                   Find next ADR number
│   └── list-features.sh                     Inventory features + progress
│
└── docs/
    ├── README.md                            ★ Full Vietnamese guide (660 lines)
    ├── _common/                             ◄── written once per project
    │   ├── architecture.md
    │   ├── api-conventions.md
    │   ├── security-baseline.md
    │   ├── test-strategy.md
    │   ├── glossary.md
    │   └── review-gates.md
    └── features/
        ├── _template/                       ◄── copy this for each feature
        │   ├── 01_PRD.md
        │   ├── 02_change-impact.md
        │   ├── 03_technical-design.md
        │   ├── 04_test-plan.md
        │   ├── 05_traceability-matrix.md
        │   └── 06_ADR-001_[title].md
        └── <feature-folders>/               ◄── created by docs-02-feature-new
```

---

## Pattern: AI vs Script

Every authoring skill follows the same shape:

```markdown
## Pre-Execution Checks (MANDATORY)
   1. Run script to verify prerequisites
   2. Run script to parse existing state
   → STOP if checks fail

## Workflow
   AI generates content using script outputs as ground truth

## Post-Execution Validation (MANDATORY)
   1. Run validator script
   2. Run gate verdict script (informational)
   → DO NOT mark complete if validation fails
```

This enforces a clean separation:

| Layer | Handles | Why |
| - | - | - |
| **Scripts** | File ops, parsing, validation, calculations, structural checks | Deterministic, fast, free, reproducible, CI-callable |
| **AI** | Content generation, semantic mapping, judgment, edge cases | Where humans/AIs add real value |

The AI cannot skip the scripts — they're embedded in the skill workflow. The scripts cannot do semantic reasoning — they delegate that back to the AI. Together they cover ~100% of the workflow with ~70% script / ~30% AI.

---

## Documentation

The full user guide is in **[`docs/README.md`](docs/README.md)** (Vietnamese, 660 lines, with Mermaid lifecycle diagram).

For non-Vietnamese readers, the structure section below is the original English documentation of the `docs/` folder layout.

---

## `docs/` folder structure

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

### Common vs per-feature

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

### Scope per file by complexity

| File | Simple CRUD | Complex business logic |
| - | - | - |
| `01_PRD.md` | ~20 lines | ~50 lines |
| `03_technical-design.md` | Data model + endpoints | + Business logic flows + Sequence diagrams |
| `02_change-impact.md` | "No impact" or 1 small table | Full analysis |
| `04_test-plan.md` | ~10 test cases | ~30+ test cases |
| `05_traceability-matrix.md` | 4–5 rows | 10–20 rows |
| `06_ADR-xxx.md` | Usually not needed | 1–3 ADRs |

---

## Use it on another project

```bash
# Copy the 3 active directories
cp -r .claude/skills/docs-* <other-project>/.claude/skills/
cp -r .claude/agents/docs-*.md <other-project>/.claude/agents/
cp -r .docs-scripts <other-project>/.docs-scripts
chmod +x <other-project>/.docs-scripts/*.sh

# Copy the templates
cp -r docs/_common docs/features/_template <other-project>/docs/
```

That's all. Open Claude Code in the new project and say *"Bootstrap docs"* to get started.

---

## Contributing

This is a personal project but PRs / issues / discussions are welcome:

- **Bug reports**: open an issue with a minimal repro and the failing script's `--json` output
- **New scripts**: keep them bash 3.2 compatible, return JSON with `--json`, exit 0/1/2
- **New skills**: follow the existing Pre-Execution / Workflow / Post-Execution structure
- **New gates**: edit `docs/_common/review-gates.md` and add a case to `compute-gate-verdict.sh`

All scripts must pass `bash -n` syntax check and the smoke-test sequence in [`docs/README.md` § Troubleshooting](docs/README.md).

---

## License

[MIT](LICENSE) © 2026 Foxdemon
