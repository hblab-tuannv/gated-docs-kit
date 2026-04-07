# Security Baseline

**Version**: [VERSION] | **Last Amended**: [DATE]

> Project-level. Applies to all features. Per-feature security concerns reference this.
> Based on OWASP Top 10, ASVS 5.0, and secure coding best practices.

<!--
  ACTION REQUIRED: Populate from auth config, middleware, validation libraries,
  and security-related packages. Mark N/A if not applicable.
-->

## Input Validation & Sanitization

<!-- ACTION REQUIRED: From validation library config. -->

| Rule | Implementation | Status |
| - | - | - |
| Validate all input at API boundary | [VALIDATION_LIBRARY] | [IMPLEMENTED / TODO] |
| Whitelist allowed fields (no mass assignment) | [STRATEGY] | [IMPLEMENTED / TODO] |
| Sanitize HTML output to prevent XSS | [SANITIZER_LIBRARY] | [IMPLEMENTED / TODO] |
| Parameterized queries (no raw SQL concatenation) | [ORM_OR_QUERY_BUILDER] | [IMPLEMENTED / TODO] |
| File upload: validate type, size, content | [IMPLEMENTATION] | [IMPLEMENTED / TODO / N/A] |

## Authentication & Session

<!-- ACTION REQUIRED: From auth module, token config, session middleware. -->

| Rule | Implementation | Status |
| - | - | - |
| Passwords hashed with strong algorithm | [ALGORITHM: bcrypt / argon2 / scrypt] | [IMPLEMENTED / TODO] |
| Token expiration enforced | [ACCESS_TOKEN_TTL] / [REFRESH_TOKEN_TTL] | [IMPLEMENTED / TODO] |
| Refresh token rotation on use | [STRATEGY] | [IMPLEMENTED / TODO / N/A] |
| Session invalidation on logout | [MECHANISM] | [IMPLEMENTED / TODO] |
| Brute-force protection (rate limit on login) | [RATE_LIMITER] | [IMPLEMENTED / TODO] |

## Authorization

<!-- ACTION REQUIRED: From guards, middleware, RBAC/ABAC config. -->

| Rule | Implementation | Status |
| - | - | - |
| Principle of least privilege enforced | [ROLE_SYSTEM] | [IMPLEMENTED / TODO] |
| Resource ownership verified before mutation | [OWNERSHIP_CHECK_LOCATION] | [IMPLEMENTED / TODO] |
| Admin actions separated and audited | [ADMIN_GUARD] | [IMPLEMENTED / TODO] |
| No client-side-only auth checks | [SERVER_GUARD_MECHANISM] | [IMPLEMENTED / TODO] |

## Data Protection

<!-- ACTION REQUIRED: From entity definitions, encryption config, env management. -->

| Rule | Implementation | Status |
| - | - | - |
| Sensitive data encrypted at rest | [ENCRYPTION_METHOD] | [IMPLEMENTED / TODO / N/A] |
| Secrets not hardcoded (env vars / vault) | [SECRETS_MANAGEMENT] | [IMPLEMENTED / TODO] |
| PII excluded from logs | [LOG_FILTER_MECHANISM] | [IMPLEMENTED / TODO] |
| Database connections use TLS | [DB_SSL_CONFIG] | [IMPLEMENTED / TODO] |
| Sensitive fields excluded from API responses | [SERIALIZATION_STRATEGY] | [IMPLEMENTED / TODO] |

## API Security

<!-- ACTION REQUIRED: From middleware, CORS config, rate limiter, security headers. -->

| Rule | Implementation | Status |
| - | - | - |
| CORS configured with explicit origins | [CORS_CONFIG_LOCATION] | [IMPLEMENTED / TODO] |
| Rate limiting on public endpoints | [RATE_LIMITER] | [IMPLEMENTED / TODO] |
| Security headers (CSP, HSTS, X-Frame) | [SECURITY_HEADERS_MIDDLEWARE] | [IMPLEMENTED / TODO] |
| Request size limits enforced | [BODY_PARSER_LIMIT] | [IMPLEMENTED / TODO] |
| API versioning strategy | [VERSIONING_STRATEGY] | [IMPLEMENTED / TODO / N/A] |

## Dependency Management

<!-- ACTION REQUIRED: From CI pipeline, package manager config, lock files. -->

| Rule | Implementation | Status |
| - | - | - |
| Lock file committed | [LOCK_FILE_TYPE] | [IMPLEMENTED / TODO] |
| Dependency audit in CI | [AUDIT_TOOL] | [IMPLEMENTED / TODO] |
| Auto-update for security patches | [DEPENDABOT / RENOVATE / MANUAL] | [IMPLEMENTED / TODO] |
| No known critical vulnerabilities | [SCAN_TOOL] | [IMPLEMENTED / TODO] |

## Per-Feature Security Checklist

> Copy this checklist into each feature's technical design or review process.

- [ ] All user input validated and sanitized at API boundary
- [ ] Authorization checks on every mutating endpoint
- [ ] Resource ownership verified before update/delete
- [ ] No sensitive data leaked in API responses or logs
- [ ] SQL injection prevented (parameterized queries)
- [ ] XSS prevented (output encoding / sanitization)
- [ ] CSRF protection if using cookie-based auth
- [ ] File uploads validated (type, size, content) if applicable
- [ ] Rate limiting on sensitive endpoints (login, password reset)
- [ ] Error messages do not expose internal details
