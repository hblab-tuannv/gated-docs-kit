#!/usr/bin/env bash
#
# parse-test-cases.sh — Extract test cases from 04_test-plan.md
#
# Parses test case rows by ID prefix:
#   TC-U-* (Unit), TC-A-* (API), TC-E-* (E2E), TC-P-* (Performance), TC-R-* (Regression)
#
# Returns JSON grouped by layer with counts.
#
# Usage:
#   .docs-scripts/parse-test-cases.sh <file>
#
# Exit codes:
#   0 — parsed
#   1 — file invalid
#   2 — script error

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

FILE="${1:-}"
[[ -z "$FILE" ]] && { log_error "File path required"; exit 2; }
[[ ! -f "$FILE" ]] && { log_error "File not found: $FILE"; exit 1; }
require_jq

# Extract test cases by ID prefix
extract_layer() {
  local prefix="$1"
  local result="[]"
  while IFS= read -r line; do
    trimmed=$(echo "$line" | sed 's/^| *//; s/ *|$//')
    id=$(echo "$trimmed" | awk -F'|' '{gsub(/^ +| +$/, "", $1); print $1}')
    desc=$(echo "$trimmed" | awk -F'|' '{gsub(/^ +| +$/, "", $2); print $2}')
    [[ -z "$id" ]] && continue
    [[ "$id" == "ID" ]] && continue
    [[ "$id" == "-" ]] && continue
    case "$id" in
      "$prefix"-*)
        result=$(echo "$result" | jq --arg id "$id" --arg desc "$desc" \
          '. + [{id: $id, description: $desc}]')
        ;;
    esac
  done < <(grep -E "^\| ${prefix}-[0-9]+" "$FILE" 2>/dev/null || true)
  echo "$result"
}

unit_json=$(extract_layer "TC-U")
api_json=$(extract_layer "TC-A")
e2e_json=$(extract_layer "TC-E")
perf_json=$(extract_layer "TC-P")
regr_json=$(extract_layer "TC-R")

unit_count=$(echo "$unit_json" | jq 'length')
api_count=$(echo "$api_json" | jq 'length')
e2e_count=$(echo "$e2e_json" | jq 'length')
perf_count=$(echo "$perf_json" | jq 'length')
regr_count=$(echo "$regr_json" | jq 'length')
total_count=$((unit_count + api_count + e2e_count + perf_count + regr_count))

status_value=$(get_artifact_status "$FILE" 2>/dev/null || echo "")

jq -n \
  --arg file "$FILE" \
  --arg status "$status_value" \
  --argjson unit "$unit_json" \
  --argjson api "$api_json" \
  --argjson e2e "$e2e_json" \
  --argjson perf "$perf_json" \
  --argjson regr "$regr_json" \
  --argjson uc "$unit_count" \
  --argjson ac "$api_count" \
  --argjson ec "$e2e_count" \
  --argjson pc "$perf_count" \
  --argjson rc "$regr_count" \
  --argjson tc "$total_count" \
  '{
    file: $file,
    status: $status,
    tests: {
      unit: $unit,
      api: $api,
      e2e: $e2e,
      performance: $perf,
      regression: $regr
    },
    count: {
      unit: $uc,
      api: $ac,
      e2e: $ec,
      performance: $pc,
      regression: $rc,
      total: $tc
    }
  }'
