#!/usr/bin/env bash
#
# set-status.sh — Update the **Status** field in an artifact header
#
# Safe in-place update of the Status field. Validates that:
#   - File exists
#   - Status field present (not creating one if missing)
#   - New status is one of the canonical values
#
# Canonical statuses: Draft, In Review, Approved, Deprecated
#
# Usage:
#   .docs-scripts/set-status.sh <file> <new-status> [--json]
#
# Exit codes:
#   0 — updated
#   1 — file invalid or status not found
#   2 — script error

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

FILE=""
NEW_STATUS=""
JSON=false

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --json) JSON=true; shift ;;
    -h|--help)
      sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      if [[ -z "$FILE" ]]; then
        FILE="$1"
      elif [[ -z "$NEW_STATUS" ]]; then
        NEW_STATUS="$1"
      else
        log_error "Unexpected arg: $1"
        exit 2
      fi
      shift
      ;;
  esac
done

if [[ -z "$FILE" ]] || [[ -z "$NEW_STATUS" ]]; then
  log_error "Usage: set-status.sh <file> <new-status> [--json]"
  exit 2
fi
[[ "$JSON" == "true" ]] && require_jq

# Validate new status
case "$NEW_STATUS" in
  "Draft"|"In Review"|"Approved"|"Deprecated") ;;
  *)
    log_error "Invalid status: '$NEW_STATUS'"
    log_error "Allowed: Draft | In Review | Approved | Deprecated"
    exit 2
    ;;
esac

if [[ ! -f "$FILE" ]]; then
  log_error "File not found: $FILE"
  exit 1
fi

# Check the raw line presence directly — get_artifact_status filters out
# template placeholder values like "[Draft | In Review | Approved]" and would
# otherwise return empty for a perfectly valid (just unfilled) header.
if ! grep -q '^\*\*Status\*\*:' "$FILE"; then
  log_error "No **Status** field found in $FILE"
  log_info "Add a line like '**Status**: Draft' in the header first"
  exit 1
fi

old_status=$(get_artifact_status "$FILE" 2>/dev/null || echo "")
# When the existing value is a template placeholder, treat it as "(unset)"
# in the report but still allow set_artifact_status to overwrite it.
[[ -z "$old_status" ]] && old_status="(unset)"

if [[ "$old_status" == "$NEW_STATUS" ]]; then
  if [[ "$JSON" == "true" ]]; then
    jq -n --arg file "$FILE" --arg status "$NEW_STATUS" \
      '{file: $file, modified: false, old_status: $status, new_status: $status, message: "no change needed"}'
  else
    log_info "Status already set to '$NEW_STATUS' — no change"
  fi
  exit 0
fi

set_artifact_status "$FILE" "$NEW_STATUS"

if [[ "$JSON" == "true" ]]; then
  jq -n \
    --arg file "$FILE" \
    --arg old "$old_status" \
    --arg new "$NEW_STATUS" \
    '{file: $file, modified: true, old_status: $old, new_status: $new}'
else
  log_ok "Updated $FILE: $old_status → $NEW_STATUS"
fi
