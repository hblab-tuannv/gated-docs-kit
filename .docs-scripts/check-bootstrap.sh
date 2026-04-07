#!/usr/bin/env bash
#
# check-bootstrap.sh — Verify status of docs/_common/ files
#
# Checks each of the 6 required _common/ files for:
#   - Existence
#   - Number of [PLACEHOLDER] tokens remaining
#   - Number of "NEEDS EVIDENCE" markers
#
# Output: pretty text by default, structured JSON with --json
#
# Usage:
#   .docs-scripts/check-bootstrap.sh [--json]
#
# Exit codes:
#   0 — all files exist and are complete
#   1 — at least one file is partial or missing
#   2 — script error (jq missing, etc.)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

JSON=false
if [[ "${1:-}" == "--json" ]]; then
  JSON=true
  require_jq
fi

results_json="[]"
total=0
complete=0
partial=0
missing=0

for file in $COMMON_FILES; do
  total=$((total + 1))
  filepath="$COMMON_DIR/$file"

  if [[ ! -f "$filepath" ]]; then
    missing=$((missing + 1))
    if [[ "$JSON" == "true" ]]; then
      results_json=$(echo "$results_json" | jq \
        --arg file "$file" \
        '. + [{file: $file, exists: false, placeholders: 0, needs_evidence: 0, status: "missing"}]')
    fi
    continue
  fi

  ph=$(count_placeholders "$filepath")
  ne=$(count_needs_evidence "$filepath")

  status="complete"
  if [[ "$ph" -gt 0 ]] || [[ "$ne" -gt 0 ]]; then
    status="partial"
    partial=$((partial + 1))
  else
    complete=$((complete + 1))
  fi

  if [[ "$JSON" == "true" ]]; then
    results_json=$(echo "$results_json" | jq \
      --arg file "$file" \
      --argjson ph "$ph" \
      --argjson ne "$ne" \
      --arg status "$status" \
      '. + [{file: $file, exists: true, placeholders: $ph, needs_evidence: $ne, status: $status}]')
  fi
done

overall="ok"
if [[ "$missing" -gt 0 ]]; then
  overall="missing"
elif [[ "$partial" -gt 0 ]]; then
  overall="partial"
fi

if [[ "$JSON" == "true" ]]; then
  jq -n \
    --arg status "$overall" \
    --arg common_dir "$COMMON_DIR" \
    --argjson total "$total" \
    --argjson complete "$complete" \
    --argjson partial "$partial" \
    --argjson missing "$missing" \
    --argjson files "$results_json" \
    '{
      status: $status,
      common_dir: $common_dir,
      summary: {total: $total, complete: $complete, partial: $partial, missing: $missing},
      files: $files
    }'
else
  echo "Bootstrap status: $overall"
  echo "Common dir: $COMMON_DIR"
  echo "Summary: $complete complete / $partial partial / $missing missing of $total files"
  echo
  for file in $COMMON_FILES; do
    filepath="$COMMON_DIR/$file"
    if [[ ! -f "$filepath" ]]; then
      echo "  ❌ $file (missing)"
    else
      ph=$(count_placeholders "$filepath")
      ne=$(count_needs_evidence "$filepath")
      if [[ "$ph" -gt 0 ]] || [[ "$ne" -gt 0 ]]; then
        echo "  ⚠️  $file — placeholders=$ph needs_evidence=$ne"
      else
        echo "  ✅ $file"
      fi
    fi
  done
fi

# Exit code
if [[ "$overall" == "ok" ]]; then
  exit 0
else
  exit 1
fi
