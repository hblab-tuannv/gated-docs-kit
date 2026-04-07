# Technical Design — [FEATURE_NAME]

**Author**: [AUTHOR]
**Status**: [Draft / In Review / Approved]
**References**: [PRD](./01_PRD.md), [API Conventions](../../_common/api-conventions.md), [Architecture](../../_common/architecture.md)
**Created**: [DATE]
**Updated**: [DATE]
**Version**: [VERSION]

## Overview

<!--
  ACTION REQUIRED: How does this feature fit into the existing system? One short paragraph.
-->

[FEATURE_OVERVIEW]

## Data model

### New / modified entities

<!--
  ACTION REQUIRED: List new or modified entities from the codebase.
  Example:
  - **`Task`** — new: id (uuid, PK), title (varchar 255, NOT NULL), status (enum), userId (uuid, FK)
  - **`User`** — modified: added `lastLoginAt` (timestamp, nullable)
-->

**`[ENTITY_NAME]`** — _new / modified_

| Field | Type | Constraints | Notes |
| - | - | - | - |
| `id` | [TYPE] | PK | |
| [FIELD_NAME] | [TYPE] | [CONSTRAINTS] | [NOTES] |

### Relationships

<!--
  ACTION REQUIRED: Define ER relationships between entities.
  Use Mermaid erDiagram syntax: ||--o{ (one-to-many), ||--|| (one-to-one), }o--o{ (many-to-many)
-->

```mermaid
erDiagram
    [EXISTING_ENTITY] ||--o{ [NEW_ENTITY] : "[VERB]"
```

### Migration

```sql
-- Up
[UP_MIGRATION_SQL]

-- Down
[DOWN_MIGRATION_SQL]
```

## API

> Conventions (auth, errors, pagination) → [`_common/api-conventions.md`](../../_common/api-conventions.md)
> Full contracts (request/response shapes) → defined in source: `[SOURCE_FILE_PATH]`
> Live spec (after running dev server) → `[API_DOCS_URL]`

### Endpoints

<!--
  ACTION REQUIRED: List all endpoints from route definitions in source code.
  Example:
  - GET /resources (List, Required auth)
  - POST /resources (Create, Required auth)
  - POST /resources/:id/approve (Custom action, Admin only)
-->

| Method | Path | Description | Auth |
| - | - | - | - |
| `[METHOD]` | `[PATH]` | [DESCRIPTION] | [AUTH_REQUIREMENT] |

### Request / Response notes

> Only document non-obvious shapes or constraints not expressible in code annotations.
> Standard CRUD shapes → skip this section.

### Authorization

<!--
  ACTION REQUIRED: Extract from guards / decorators / middleware.
  Example:
  - List: user, own resources only
  - Create: user, no extra check
  - Approve: admin, status must be pending
-->

| Action | Required role | Extra check |
| - | - | - |
| [ACTION] | `[ROLE]` | [EXTRA_CHECK] |

## Business logic

> Only document non-obvious rules. Skip if it's standard CRUD.

<!--
  ACTION REQUIRED: Document non-obvious business logic steps.
  Example:
  ### create(userId, input)
  1. Validate uniqueness of title within user scope
  2. Auto-assign to default category if none specified
  3. Send notification to admin if priority is P0
-->

### `[METHOD_SIGNATURE]`

```
1. [STEP_DESCRIPTION]
2. [STEP_DESCRIPTION]
```

## Frontend

> Skip sections that follow standard patterns.

### Screens

<!--
  ACTION REQUIRED: Extract from page/route definitions in frontend source.
  Example:
  - List /resources (SSR), Detail /resources/:id (SSR), Form /resources/new (CSR)
-->

| Screen | Route | Rendering |
| - | - | - |
| [SCREEN_NAME] | `[ROUTE]` | [RENDER_STRATEGY] |

### Non-standard data flow

> Only document if it deviates from the standard fetch → display → mutate pattern.

## Observability

> Only document feature-specific signals. Global signals → [`_common/architecture.md`](../../_common/architecture.md)

<!--
  ACTION REQUIRED: Extract from logging/metrics in feature source code.
  Example:
  - Log INFO: resource.created { id, userId } on create
  - Log WARN: resource.update_conflict { id } on conflict
  - Metric: resource_created_total on create
-->

| Signal | Event | When |
| - | - | - |
| [SIGNAL_TYPE] | `[EVENT_NAME] { [PAYLOAD] }` | [TRIGGER] |

## Open questions

| # | Question | Owner | Status |
| - | - | - | - |
| 1 | | | Open |
