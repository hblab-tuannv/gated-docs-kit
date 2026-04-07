#!/usr/bin/env bash
#
# compute-traceability.sh — Compute coverage statistics for a feature
#
# Combines outputs from parse-prd-frs.sh + parse-test-cases.sh + reads
# 05_traceability-matrix.md (if exists) to compute:
#   - Total FRs
#   - FRs with at least 1 mapped test
#   - FRs at status ✅
#   - List of gaps (FRs with no test)
#
# Usage:
#   .docs-scripts/compute-traceability.sh --feature <slug-or-path>
#
# Exit codes:
#   0 — computed
#   1 — feature folder invalid
#   2 — script error

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

FEATURE=""
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --feature) needs_value "$1" "${2:-}"; FEATURE="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) log_error "Unknown arg: $1"; exit 2 ;;
  esac
done

[[ -z "$FEATURE" ]] && { log_error "--feature required"; exit 2; }
require_jq

feature_dir=$(resolve_feature_dir "$FEATURE" || true)
if [[ -z "$feature_dir" ]] || [[ ! -d "$feature_dir" ]]; then
  log_error "Feature folder not found: $FEATURE"
  exit 1
fi

prd="$feature_dir/01_PRD.md"
matrix="$feature_dir/05_traceability-matrix.md"
test_plan="$feature_dir/04_test-plan.md"

# Get FR list
fr_data="{}"
if [[ -f "$prd" ]]; then
  fr_data=$("$SCRIPT_DIR/parse-prd-frs.sh" "$prd" 2>/dev/null || echo '{"frs":[],"count":{"total":0}}')
fi
total_frs=$(echo "$fr_data" | jq '.count.total // 0')

# Get test counts
test_counts="{}"
if [[ -f "$test_plan" ]]; then
  test_data=$("$SCRIPT_DIR/parse-test-cases.sh" "$test_plan" 2>/dev/null || echo '{"count":{"total":0}}')
  test_counts=$(echo "$test_data" | jq '.count')
fi

# Parse matrix rows if matrix exists
with_test=0
passing=0
failing=0
in_progress=0
no_test=0
gaps_json="[]"

if [[ -f "$matrix" ]]; then
  while IFS= read -r line; do
    trimmed=$(echo "$line" | sed 's/^| *//; s/ *|$//')
    fr_id=$(echo "$trimmed" | awk -F'|' '{gsub(/^ +| +$/, "", $1); print $1}')
    test_ids=$(echo "$trimmed" | awk -F'|' '{gsub(/^ +| +$/, "", $5); print $5}')
    status=$(echo "$trimmed" | awk -F'|' '{gsub(/^ +| +$/, "", $6); print $6}')

    [[ -z "$fr_id" ]] && continue
    case "$fr_id" in FR-*) ;; *) continue ;; esac

    # Has test?
    if [[ -n "$test_ids" ]] && [[ "$test_ids" != "[TEST_IDS]" ]]; then
      with_test=$((with_test + 1))
    else
      no_test=$((no_test + 1))
      gaps_json=$(echo "$gaps_json" | jq --arg id "$fr_id" '. + [$id]')
    fi

    # Status (look for emoji)
    if echo "$status" | grep -q "✅"; then
      passing=$((passing + 1))
    elif echo "$status" | grep -q "❌"; then
      failing=$((failing + 1))
    elif echo "$status" | grep -q "🔄"; then
      in_progress=$((in_progress + 1))
    fi
  done < "$matrix"
fi

# Coverage percentages
coverage_pct=0
passing_pct=0
if [[ "$total_frs" -gt 0 ]]; then
  coverage_pct=$(awk -v w="$with_test" -v t="$total_frs" 'BEGIN {printf "%.0f", (w/t)*100}')
  passing_pct=$(awk -v p="$passing" -v t="$total_frs" 'BEGIN {printf "%.0f", (p/t)*100}')
fi

# Gate G4 readiness
g4_ready=false
if [[ "$total_frs" -gt 0 ]] && [[ "$passing" -eq "$total_frs" ]] && [[ "$failing" -eq 0 ]]; then
  g4_ready=true
fi

jq -n \
  --arg feature_dir "$feature_dir" \
  --argjson total "$total_frs" \
  --argjson with_test "$with_test" \
  --argjson no_test "$no_test" \
  --argjson passing "$passing" \
  --argjson failing "$failing" \
  --argjson in_progress "$in_progress" \
  --argjson coverage_pct "$coverage_pct" \
  --argjson passing_pct "$passing_pct" \
  --argjson gaps "$gaps_json" \
  --argjson test_counts "$test_counts" \
  --argjson g4_ready "$g4_ready" \
  '{
    feature_dir: $feature_dir,
    coverage: {
      total_frs: $total,
      with_test: $with_test,
      no_test: $no_test,
      coverage_pct: $coverage_pct
    },
    status: {
      passing: $passing,
      failing: $failing,
      in_progress: $in_progress,
      passing_pct: $passing_pct
    },
    test_counts: $test_counts,
    gaps: $gaps,
    g4_ready: $g4_ready
  }'
