# API Conventions

> Project-level. Applies to all features. Update here, not per-feature.
> **AI:** Read server config, middleware, error handlers, and shared utilities to populate.

---

## Base URL

<!-- AI:FILL — from server/environment config files -->

| Environment | URL |
| - | - |
| Local | `<!-- AI:FILL -->` |
| Staging | `<!-- AI:FILL -->` |
| Production | `<!-- AI:FILL -->` |

> _Examples: `http://localhost:3000` · `http://localhost:4000/graphql` · `http://localhost:8080/api/v1`_

---

## Authentication

<!-- AI:FILL — from auth middleware / guards / passport config -->

All protected endpoints require one of:

| Scheme | Where | Value |
| - | - | - |
| <!-- AI:FILL --> | | |

Unauthenticated requests → `<!-- AI:FILL -->`

> _Examples:_
> - Bearer JWT → `Authorization: Bearer <token>`
> - Cookie session → `Cookie: session_id=<token>` (httpOnly)
> - API Key → `X-API-Key: <key>`
> - OAuth2 → `Authorization: Bearer <oauth_token>`
> - Basic Auth → `Authorization: Basic <base64>`

---

## Standard error response

<!-- AI:FILL — from global error handler / exception filter -->

```json
{
  // AI:FILL — document actual error shape used in project
}
```

> _Example shapes:_
> - Flat: `{ "error": "CODE", "message": "...", "details": [{ "field": "...", "message": "..." }] }`
> - Envelope: `{ "success": false, "error": { "code": "...", "message": "..." } }`
> - RFC 7807: `{ "type": "/errors/...", "title": "...", "status": 404, "detail": "..." }`

---

## Error codes

<!-- AI:FILL — from error constants / exception classes / enum definitions -->

| HTTP | Code | When |
| - | - | - |
| <!-- AI:FILL --> | | |

> _Common codes (select applicable):_
> `400 INVALID_INPUT` · `401 UNAUTHENTICATED` · `403 FORBIDDEN` · `404 NOT_FOUND` · `409 CONFLICT` · `422 UNPROCESSABLE` · `429 RATE_LIMITED` · `500 INTERNAL_ERROR`

---

## Pagination

<!-- AI:FILL — from list endpoints / shared pagination utility -->

> _Common patterns:_
> - Offset: `?page=1&limit=20` → `{ "data": [...], "meta": { "total": 100, "page": 1, "limit": 20 } }`
> - Cursor: `?cursor=abc&limit=20` → `{ "data": [...], "meta": { "nextCursor": "def", "hasMore": true } }`
> - Simple: `?offset=0&limit=20` → `{ "items": [...], "total": 100 }`
> - None (small collections, no pagination)

---

## Soft delete

<!-- AI:FILL — from base entity / ORM config. Write "Not used" if hard delete only. -->

> _Examples: `deletedAt` timestamp · `isDeleted` boolean · `status = 'archived'` · Not used (hard delete)_

---

## Timestamps

<!-- AI:FILL — from entity definitions / serialization config -->

> _Examples: ISO 8601 UTC `2024-01-15T10:30:00.000Z` · Unix epoch ms `1705312200000` · Custom format_
