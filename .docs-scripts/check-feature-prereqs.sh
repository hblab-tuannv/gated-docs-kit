#!/usr/bin/env bash
#
# check-feature-prereqs.sh — Verify a feature folder has the required prerequisites
#
# For each required artifact, check:
#   - Exists
#   - Status field (Draft / In Review / Approved)
#   - Optionally: minimum required status
#
# Usage:
#   .docs-scripts/check-feature-prereqs.sh --feature <slug-or-path> --requires <file1,file2,...> [--min-status <status>] [--json]
#
# Examples:
#   check-feature-prereqs.sh --feature 001-user-auth --requires 01_PRD.md
#   check-feature-prereqs.sh --feature user-auth --requires 01_PRD.md,02_change-impact.md --min-status "In Review" --json
#
# Exit codes:
#   0 — all prereqs satisfied
#   1 — one or more prereqs missing or invalid
#   2 — script error

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

FEATURE=""
REQUIRES=""
MIN_STATUS=""
JSON=false

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --feature)    needs_value "$1" "${2:-}"; FEATURE="$2"; shift 2 ;;
    --requires)   needs_value "$1" "${2:-}"; REQUIRES="$2"; shift 2 ;;
    --min-status) needs_value "$1" "${2:-}"; MIN_STATUS="$2"; shift 2 ;;
    --json)       JSON=true; shift ;;
    -h|--help)
      sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) log_error "Unknown arg: $1"; exit 2 ;;
  esac
done

if [[ -z "$FEATURE" ]]; then
  log_error "--feature is required"
  exit 2
fi
if [[ -z "$REQUIRES" ]]; then
  log_error "--requires is required (comma-separated list)"
  exit 2
fi
[[ "$JSON" == "true" ]] && require_jq

# Resolve feature directory
feature_dir=$(resolve_feature_dir "$FEATURE" || true)
if [[ -z "$feature_dir" ]] || [[ ! -d "$feature_dir" ]]; then
  if [[ "$JSON" == "true" ]]; then
    jq -n --arg feature "$FEATURE" \
      '{status: "missing", error: "feature folder not found", feature_input: $feature}'
  else
    log_error "Feature folder not found for: $FEATURE"
    log_info "Available features:"
    find "$FEATURES_DIR" -mindepth 1 -maxdepth 1 -type d ! -name "_template" 2>/dev/null \
      | sed "s|$FEATURES_DIR/|  - |"
  fi
  exit 1
fi

# Status ranking for comparison
status_rank() {
  case "$1" in
    "Draft")     echo 1 ;;
    "In Review") echo 2 ;;
    "Approved")  echo 3 ;;
    *)           echo 0 ;;
  esac
}

min_rank=0
if [[ -n "$MIN_STATUS" ]]; then
  min_rank=$(status_rank "$MIN_STATUS")
fi

# Check each required file
checks_json="[]"
all_ok=true
missing_list="[]"
errors_list="[]"

# Convert comma-separated to space-separated
required_files=$(echo "$REQUIRES" | tr ',' ' ')

for file in $required_files; do
  filepath="$feature_dir/$file"
  exists=true
  status=""
  rank=0
  ok=true
  reason=""

  if [[ ! -f "$filepath" ]]; then
    exists=false
    ok=false
    reason="file does not exist"
    all_ok=false
    missing_list=$(echo "$missing_list" | jq --arg f "$file" '. + [$f]')
  else
    status=$(get_artifact_status "$filepath" 2>/dev/null || echo "")
    if [[ -z "$status" ]]; then
      status="(none)"
    fi
    rank=$(status_rank "$status")
    if [[ "$min_rank" -gt 0 ]] && [[ "$rank" -lt "$min_rank" ]]; then
      ok=false
      reason="status '$status' is below required '$MIN_STATUS'"
      all_ok=false
      errors_list=$(echo "$errors_list" | jq --arg msg "$file: $reason" '. + [$msg]')
    fi
  fi

  if [[ "$JSON" == "true" ]]; then
    checks_json=$(echo "$checks_json" | jq \
      --arg file "$file" \
      --argjson exists "$exists" \
      --arg status "$status" \
      --argjson ok "$ok" \
      --arg reason "$reason" \
      '. + [{file: $file, exists: $exists, status: $status, ok: $ok, reason: $reason}]')
  fi
done

overall_status="ok"
if [[ "$all_ok" != "true" ]]; then
  overall_status="failed"
fi

if [[ "$JSON" == "true" ]]; then
  jq -n \
    --arg status "$overall_status" \
    --arg feature_dir "$feature_dir" \
    --arg min_status "$MIN_STATUS" \
    --argjson checks "$checks_json" \
    --argjson missing "$missing_list" \
    --argjson errors "$errors_list" \
    '{
      status: $status,
      feature_dir: $feature_dir,
      min_status: $min_status,
      checks: $checks,
      missing: $missing,
      errors: $errors
    }'
else
  echo "Feature: $feature_dir"
  echo "Required: $REQUIRES"
  [[ -n "$MIN_STATUS" ]] && echo "Min status: $MIN_STATUS"
  echo
  for file in $required_files; do
    filepath="$feature_dir/$file"
    if [[ ! -f "$filepath" ]]; then
      echo "  ❌ $file (missing)"
    else
      status=$(get_artifact_status "$filepath" 2>/dev/null || echo "(none)")
      rank=$(status_rank "$status")
      if [[ "$min_rank" -gt 0 ]] && [[ "$rank" -lt "$min_rank" ]]; then
        echo "  ⚠️  $file — Status: $status (need ≥ $MIN_STATUS)"
      else
        echo "  ✅ $file — Status: $status"
      fi
    fi
  done
  echo
  echo "Verdict: $overall_status"
fi

if [[ "$all_ok" == "true" ]]; then
  exit 0
else
  exit 1
fi
