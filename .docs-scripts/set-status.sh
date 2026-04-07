#!/usr/bin/env bash
#
# set-status.sh — Update the **Status** field in an artifact header
#
# Safe in-place update of the Status field. Validates that:
#   - File exists
#   - Status field present (not creating one if missing)
#   - New status is one of the canonical values
#
# Canonical statuses (PRD/design/impact/test plan): Draft | In Review | Approved
# Canonical statuses (ADR):                         Proposed | Accepted | Deprecated
#
# Usage:
#   .docs-scripts/set-status.sh <file> <new-status> [--only-if-unset] [--json]
#
# Flags:
#   --only-if-unset  Only update when the current Status value is a template
#                    placeholder (e.g. "[Draft | In Review | Approved]") or
#                    otherwise unrecognised. If the file already has a valid
#                    status, the script is a no-op (exit 0). Safe to call
#                    from skill Post-Execution to guarantee a valid status
#                    without overwriting a human's in-flight transition.
#
# Exit codes:
#   0 — updated (or no change needed)
#   1 — file invalid or Status field not found
#   2 — script error

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

FILE=""
NEW_STATUS=""
JSON=false
ONLY_IF_UNSET=false

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --only-if-unset) ONLY_IF_UNSET=true; shift ;;
    --json)          JSON=true; shift ;;
    -h|--help)
      sed -n '2,28p' "$0" | sed 's/^# \{0,1\}//'
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
  log_error "Usage: set-status.sh <file> <new-status> [--only-if-unset] [--json]"
  exit 2
fi
[[ "$JSON" == "true" ]] && require_jq

# Validate new status (covers both feature-doc lifecycle and ADR lifecycle)
case "$NEW_STATUS" in
  "Draft"|"In Review"|"Approved"|"Proposed"|"Accepted"|"Deprecated") ;;
  *)
    log_error "Invalid status: '$NEW_STATUS'"
    log_error "Allowed: Draft | In Review | Approved | Proposed | Accepted | Deprecated"
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
is_unset=false
if [[ -z "$old_status" ]]; then
  old_status="(unset)"
  is_unset=true
fi

# --only-if-unset: skip when current status is a real value
if [[ "$ONLY_IF_UNSET" == "true" ]] && [[ "$is_unset" != "true" ]]; then
  if [[ "$JSON" == "true" ]]; then
    jq -n --arg file "$FILE" --arg status "$old_status" \
      '{file: $file, modified: false, old_status: $status, new_status: $status, message: "status already set, --only-if-unset skipped"}'
  else
    log_info "Status already set to '$old_status' — --only-if-unset, skipping"
  fi
  exit 0
fi

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
