# API Conventions

> Project-level. Applies to all features. Update here, not per-feature.

<!--
  ACTION REQUIRED: Read server config, middleware, error handlers, and shared
  utilities from codebase to populate all [PLACEHOLDER] sections below.
-->

## Base URL

| Environment | URL |
| - | - |
| Local | `[LOCAL_URL]` |
| Staging | `[STAGING_URL]` |
| Production | `[PRODUCTION_URL]` |

<!-- Example: http://localhost:3000, http://localhost:4000/graphql, http://localhost:8080/api/v1 -->

## Authentication

<!--
  ACTION REQUIRED: Identify auth scheme from auth middleware / guards / passport config.
  Multiple schemes are supported — list all that apply.
  Example schemes: Bearer JWT, Cookie session, API Key, OAuth2, Basic Auth
-->

All protected endpoints require one of:

| Scheme | Where | Value |
| - | - | - |
| [AUTH_SCHEME] | [HEADER_OR_COOKIE] | [TOKEN_DESCRIPTION] |

Unauthenticated requests → `[UNAUTHENTICATED_ERROR_CODE]`

## Standard error response

<!--
  ACTION REQUIRED: Document the actual error shape from global error handler / exception filter.
  Example shapes:
  - Flat: { "error": "CODE", "message": "...", "details": [{ "field": "...", "message": "..." }] }
  - Envelope: { "success": false, "error": { "code": "...", "message": "..." } }
  - RFC 7807: { "type": "/errors/...", "title": "...", "status": 404, "detail": "..." }
-->

```json
[ERROR_RESPONSE_SHAPE]
```

## Error codes

<!--
  ACTION REQUIRED: Extract from error constants / exception classes / enum definitions.
  Common codes: 400 INVALID_INPUT, 401 UNAUTHENTICATED, 403 FORBIDDEN,
  404 NOT_FOUND, 409 CONFLICT, 422 UNPROCESSABLE, 429 RATE_LIMITED, 500 INTERNAL_ERROR
-->

| HTTP | Code | When |
| - | - | - |
| [STATUS] | `[ERROR_CODE]` | [DESCRIPTION] |

## Pagination

<!--
  ACTION REQUIRED: Identify pagination strategy from list endpoints / shared utility.
  Common patterns:
  - Offset: ?page=1&limit=20 → { "data": [...], "meta": { "total", "page", "limit" } }
  - Cursor: ?cursor=abc&limit=20 → { "data": [...], "meta": { "nextCursor", "hasMore" } }
  - Simple: ?offset=0&limit=20 → { "items": [...], "total": 100 }
  - None (small collections, no pagination needed)
-->

[PAGINATION_DESCRIPTION]

## Soft delete

<!--
  ACTION REQUIRED: Check base entity / ORM config. Write "Not used" if hard delete only.
  Example: deletedAt timestamp, isDeleted boolean, status = 'archived', Not used (hard delete)
-->

[SOFT_DELETE_STRATEGY]

## Timestamps

<!--
  ACTION REQUIRED: Check entity definitions / serialization config.
  Example: ISO 8601 UTC "2024-01-15T10:30:00.000Z", Unix epoch ms, Custom format
-->

[TIMESTAMP_FORMAT]
