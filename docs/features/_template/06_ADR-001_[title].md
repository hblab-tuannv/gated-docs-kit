# ADR-001 — [DECISION_TITLE]

**Created**: [DATE]
**Status**: [Proposed / Accepted / Deprecated]
**Deciders**: [DECIDERS]
**Updated**: [DATE]
**Version**: [VERSION]

## Context

<!--
  ACTION REQUIRED: Describe the problem that requires this decision.
  Example: "We need to choose a database for storing user sessions.
  Current in-memory storage doesn't survive restarts."
-->

[CONTEXT_DESCRIPTION]

## Options considered

<!--
  ACTION REQUIRED: List options with pros and cons.
  Example:
  | Option | Pros | Cons |
  | Redis | Fast, built-in TTL | Extra infra |
  | PostgreSQL | Already in stack | Slower for session lookups |
  | JWT (stateless) | No storage needed | Can't revoke tokens easily |
-->

| Option | Pros | Cons |
| - | - | - |
| [OPTION_A] | [PROS] | [CONS] |
| [OPTION_B] | [PROS] | [CONS] |

## Decision

**[CHOSEN_OPTION]** — [ONE_LINE_REASON]

## Consequences

- ✅ [POSITIVE_CONSEQUENCE]
- ⚠️ Trade-off: [TRADE_OFF]
