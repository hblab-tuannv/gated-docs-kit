#!/usr/bin/env bash
#
# parse-prd-frs.sh — Extract Functional Requirements from a 01_PRD.md file
#
# Parses the FR table and returns a structured JSON list. Also extracts NFRs,
# clarification markers, and counts.
#
# Output JSON shape:
#   {
#     file, frs: [{id, requirement, priority}], nfrs: [{category, nfr, metric}],
#     count: {total, p0, p1, p2}, needs_clarification: [...], status
#   }
#
# Usage:
#   .docs-scripts/parse-prd-frs.sh <file> [--json]
#
# Exit codes:
#   0 — parsed (regardless of FR count)
#   1 — file invalid
#   2 — script error

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

FILE=""
JSON=true   # default to JSON since this script is for machine consumption

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --no-json) JSON=false; shift ;;
    --json)    JSON=true; shift ;;
    -h|--help)
      sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      if [[ -z "$FILE" ]]; then FILE="$1"; shift
      else log_error "Unexpected arg: $1"; exit 2
      fi
      ;;
  esac
done

[[ -z "$FILE" ]] && { log_error "File path required"; exit 2; }
[[ ! -f "$FILE" ]] && { log_error "File not found: $FILE"; exit 1; }
require_jq

# Extract FRs from the Requirements table only.
# The PRD has multiple tables that contain FR-NNN rows:
#   * Requirements:   | FR-001 | description | priority |              (4 pipes)
#   * Acceptance:     | FR-001 | given | when | then |                 (5 pipes)
#   * Traceability:   | FR-001 | desc | design | endpoint | tests | s | (7 pipes)
# We only want the Requirements table — identify it by exactly 4 pipes
# (= 3 cells: id, requirement, priority).
frs_json="[]"
p0=0; p1=0; p2=0; total=0

while IFS= read -r line; do
  # Count pipes to disambiguate which table this row belongs to
  pipes=$(echo "$line" | tr -cd '|' | wc -c | awk '{print $1}')
  [[ "$pipes" -eq 4 ]] || continue

  # Strip leading/trailing pipes and spaces
  trimmed=$(echo "$line" | sed 's/^| *//; s/ *|$//')
  # Split by pipe
  id=$(echo "$trimmed" | awk -F'|' '{gsub(/^ +| +$/, "", $1); print $1}')
  desc=$(echo "$trimmed" | awk -F'|' '{gsub(/^ +| +$/, "", $2); print $2}')
  prio=$(echo "$trimmed" | awk -F'|' '{gsub(/^ +| +$/, "", $3); print $3}')

  [[ -z "$id" ]] && continue
  [[ "$id" == "ID" ]] && continue
  [[ "$id" == "-" ]] && continue
  case "$id" in FR-*) ;; *) continue ;; esac

  total=$((total + 1))
  case "$prio" in
    P0) p0=$((p0 + 1)) ;;
    P1) p1=$((p1 + 1)) ;;
    P2) p2=$((p2 + 1)) ;;
  esac

  frs_json=$(echo "$frs_json" | jq \
    --arg id "$id" \
    --arg desc "$desc" \
    --arg prio "$prio" \
    '. + [{id: $id, requirement: $desc, priority: $prio}]')
done < <(grep -E "^\| FR-[0-9]+" "$FILE" || true)

# Extract NFRs from NFR table (Category | NFR | Metric)
nfrs_json="[]"
in_nfr_section=false
while IFS= read -r line; do
  # Detect entering an NFR table by header pattern
  if echo "$line" | grep -qE "Category.*NFR.*Metric"; then
    in_nfr_section=true
    continue
  fi
  # Stop at empty line or new heading after entering
  if [[ "$in_nfr_section" == "true" ]]; then
    if [[ -z "$line" ]] || echo "$line" | grep -qE "^##? "; then
      in_nfr_section=false
      continue
    fi
    if echo "$line" | grep -qE "^\| "; then
      trimmed=$(echo "$line" | sed 's/^| *//; s/ *|$//')
      cat_field=$(echo "$trimmed" | awk -F'|' '{gsub(/^ +| +$/, "", $1); print $1}')
      nfr_field=$(echo "$trimmed" | awk -F'|' '{gsub(/^ +| +$/, "", $2); print $2}')
      metric_field=$(echo "$trimmed" | awk -F'|' '{gsub(/^ +| +$/, "", $3); print $3}')
      # Skip header row and separator
      [[ "$cat_field" == "Category" ]] && continue
      [[ "$cat_field" == "-" ]] && continue
      [[ -z "$cat_field" ]] && continue
      nfrs_json=$(echo "$nfrs_json" | jq \
        --arg c "$cat_field" \
        --arg n "$nfr_field" \
        --arg m "$metric_field" \
        '. + [{category: $c, nfr: $n, metric: $m}]')
    fi
  fi
done < "$FILE"

# Extract NEEDS CLARIFICATION markers
nc_json="[]"
while IFS= read -r line; do
  text=$(echo "$line" | sed -E 's/.*\[NEEDS CLARIFICATION:?[[:space:]]*([^]]*)\].*/\1/')
  nc_json=$(echo "$nc_json" | jq --arg t "$text" '. + [$t]')
done < <(grep -oE '\[NEEDS CLARIFICATION:?[^]]*\]' "$FILE" 2>/dev/null || true)

status_value=$(get_artifact_status "$FILE" 2>/dev/null || echo "")

jq -n \
  --arg file "$FILE" \
  --arg status "$status_value" \
  --argjson frs "$frs_json" \
  --argjson nfrs "$nfrs_json" \
  --argjson total "$total" \
  --argjson p0 "$p0" \
  --argjson p1 "$p1" \
  --argjson p2 "$p2" \
  --argjson nc "$nc_json" \
  '{
    file: $file,
    status: $status,
    frs: $frs,
    nfrs: $nfrs,
    count: {total: $total, p0: $p0, p1: $p1, p2: $p2},
    needs_clarification: $nc
  }'
