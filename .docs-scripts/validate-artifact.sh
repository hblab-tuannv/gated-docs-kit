#!/usr/bin/env bash
#
# validate-artifact.sh — Structural validation of a single docs artifact
#
# Validates:
#   - File exists
#   - Status field present (and optionally matches expected value)
#   - Required sections all present (per artifact type)
#   - No remaining [PLACEHOLDER] tokens
#   - No NEEDS CLARIFICATION beyond allowed limit
#
# The artifact type is auto-detected from filename suffix:
#   01_PRD.md, 02_change-impact.md, 03_technical-design.md,
#   04_test-plan.md, 05_traceability-matrix.md, 06_ADR-*.md
#
# Usage:
#   .docs-scripts/validate-artifact.sh <file> [--max-clarifications N] [--allow-placeholders] [--json]
#
# Exit codes:
#   0 — valid
#   1 — invalid
#   2 — script error

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

FILE=""
MAX_CLARIFICATIONS=3
ALLOW_PLACEHOLDERS=false
JSON=false

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --max-clarifications) needs_value "$1" "${2:-}"; MAX_CLARIFICATIONS="$2"; shift 2 ;;
    --allow-placeholders) ALLOW_PLACEHOLDERS=true; shift ;;
    --json) JSON=true; shift ;;
    -h|--help)
      sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      if [[ -z "$FILE" ]]; then
        FILE="$1"
        shift
      else
        log_error "Unexpected arg: $1"
        exit 2
      fi
      ;;
  esac
done

if [[ -z "$FILE" ]]; then
  log_error "Artifact file path is required"
  exit 2
fi
[[ "$JSON" == "true" ]] && require_jq

if [[ ! -f "$FILE" ]]; then
  if [[ "$JSON" == "true" ]]; then
    jq -n --arg file "$FILE" '{valid: false, file: $file, error: "file not found"}'
  else
    log_error "File not found: $FILE"
  fi
  exit 1
fi

# Detect artifact type by basename
basename_file=$(basename "$FILE")
artifact_type=""
expected_sections=""

case "$basename_file" in
  01_PRD.md)
    artifact_type="PRD"
    expected_sections="## Problem|## Solution|## Requirements|## Acceptance criteria"
    ;;
  02_change-impact.md)
    artifact_type="ChangeImpact"
    expected_sections="## Affected components|## Regression checklist"
    ;;
  03_technical-design.md)
    artifact_type="TechnicalDesign"
    expected_sections="## Overview"
    ;;
  04_test-plan.md)
    artifact_type="TestPlan"
    expected_sections="## Scope|## Test cases"
    ;;
  05_traceability-matrix.md)
    artifact_type="Traceability"
    expected_sections="## Coverage"
    ;;
  06_ADR-*.md)
    artifact_type="ADR"
    expected_sections="## Context|## Options considered|## Decision|## Consequences"
    ;;
  *)
    if [[ "$JSON" == "true" ]]; then
      jq -n --arg file "$FILE" --arg name "$basename_file" \
        '{valid: false, file: $file, error: "unknown artifact type", basename: $name, hint: "expected one of: 01_PRD.md, 02_change-impact.md, 03_technical-design.md, 04_test-plan.md, 05_traceability-matrix.md, 06_ADR-*.md"}'
    else
      log_error "Unknown artifact type: $basename_file"
      log_error "Expected one of: 01_PRD.md, 02_change-impact.md, 03_technical-design.md, 04_test-plan.md, 05_traceability-matrix.md, 06_ADR-*.md"
    fi
    exit 2
    ;;
esac

# Run checks
status_value=$(get_artifact_status "$FILE" 2>/dev/null || echo "")
ph_count=$(count_placeholders "$FILE")
ne_count=$(count_needs_evidence "$FILE")
nc_count=$(count_needs_clarification "$FILE")

# Section presence
missing_sections="[]"
section_count=0
present_count=0
if [[ -n "$expected_sections" ]]; then
  IFS='|' read -ra section_array <<< "$expected_sections"
  for section in "${section_array[@]}"; do
    section_count=$((section_count + 1))
    if grep -qF "$section" "$FILE"; then
      present_count=$((present_count + 1))
    else
      if [[ "$JSON" == "true" ]]; then
        missing_sections=$(echo "$missing_sections" | jq --arg s "$section" '. + [$s]')
      fi
    fi
  done
fi

# Determine validity
issues="[]"
valid=true

if [[ -z "$status_value" ]]; then
  valid=false
  if [[ "$JSON" == "true" ]]; then
    issues=$(echo "$issues" | jq '. + [{type: "status_missing", message: "Status field not found in header"}]')
  fi
fi

if [[ "$present_count" -ne "$section_count" ]]; then
  valid=false
  if [[ "$JSON" == "true" ]]; then
    issues=$(echo "$issues" | jq --argjson missing "$missing_sections" \
      '. + [{type: "missing_sections", message: "Required sections missing", details: $missing}]')
  fi
fi

if [[ "$ph_count" -gt 0 ]] && [[ "$ALLOW_PLACEHOLDERS" != "true" ]]; then
  valid=false
  if [[ "$JSON" == "true" ]]; then
    issues=$(echo "$issues" | jq --argjson n "$ph_count" \
      '. + [{type: "placeholders", message: "Unfilled [PLACEHOLDER] tokens remain", count: $n}]')
  fi
fi

if [[ "$nc_count" -gt "$MAX_CLARIFICATIONS" ]]; then
  valid=false
  if [[ "$JSON" == "true" ]]; then
    issues=$(echo "$issues" | jq --argjson n "$nc_count" --argjson max "$MAX_CLARIFICATIONS" \
      '. + [{type: "too_many_clarifications", message: "Too many NEEDS CLARIFICATION markers", count: $n, max: $max}]')
  fi
fi

if [[ "$JSON" == "true" ]]; then
  jq -n \
    --argjson valid "$valid" \
    --arg file "$FILE" \
    --arg type "$artifact_type" \
    --arg status "$status_value" \
    --argjson placeholders "$ph_count" \
    --argjson needs_evidence "$ne_count" \
    --argjson needs_clarification "$nc_count" \
    --argjson sections_present "$present_count" \
    --argjson sections_total "$section_count" \
    --argjson missing_sections "$missing_sections" \
    --argjson issues "$issues" \
    '{
      valid: $valid,
      file: $file,
      type: $type,
      status: $status,
      counts: {
        placeholders: $placeholders,
        needs_evidence: $needs_evidence,
        needs_clarification: $needs_clarification
      },
      sections: {
        present: $sections_present,
        total: $sections_total,
        missing: $missing_sections
      },
      issues: $issues
    }'
else
  echo "File: $FILE"
  echo "Type: $artifact_type"
  echo "Status: ${status_value:-(not set)}"
  echo "Placeholders: $ph_count"
  echo "NEEDS EVIDENCE: $ne_count"
  echo "NEEDS CLARIFICATION: $nc_count (max $MAX_CLARIFICATIONS)"
  echo "Sections: $present_count/$section_count present"
  echo
  if [[ "$valid" == "true" ]]; then
    log_ok "VALID"
  else
    log_error "INVALID — see issues above"
  fi
fi

if [[ "$valid" == "true" ]]; then
  exit 0
else
  exit 1
fi
