# API Conventions

**Version**: [VERSION] | **Last Amended**: [DATE]

> Project-level. Applies to all features. Update here, not per-feature.

<!-- ACTION REQUIRED: Populate from server config, middleware, error handlers, shared utilities. -->

## Base URL

| Environment | URL |
| - | - |
| Local | `[LOCAL_URL]` |
| Staging | `[STAGING_URL]` |
| Production | `[PRODUCTION_URL]` |

## Authentication

<!-- ACTION REQUIRED: From auth middleware / guards. e.g. Bearer JWT in Authorization header, HttpOnly cookie -->

All protected endpoints require one of:

| Scheme | Where | Value |
| - | - | - |
| [AUTH_SCHEME] | [HEADER_OR_COOKIE] | [TOKEN_DESCRIPTION] |

Unauthenticated requests → `[UNAUTHENTICATED_ERROR_CODE]`

## Standard error response

<!-- ACTION REQUIRED: From global error handler. Shapes: Flat / Envelope / RFC 7807 -->

```json
[ERROR_RESPONSE_SHAPE]
```

## Error codes

<!-- ACTION REQUIRED: From error constants / exception classes. e.g. 400 VALIDATION_ERROR — Invalid input; 409 CONFLICT — Duplicate resource -->

| HTTP | Code | When |
| - | - | - |
| [STATUS] | `[ERROR_CODE]` | [DESCRIPTION] |

## Pagination

<!-- ACTION REQUIRED: From list endpoints. Patterns: Offset / Cursor / Simple / None -->

[PAGINATION_DESCRIPTION]

## Soft delete

<!-- ACTION REQUIRED: From base entity / ORM. Write "Not used" if hard delete only. -->

[SOFT_DELETE_STRATEGY]

## Timestamps

<!-- ACTION REQUIRED: From entity definitions / serialization config. -->

[TIMESTAMP_FORMAT]
