#!/usr/bin/env bash
#
# list-features.sh — List all feature folders with their metadata
#
# For each features/<dir>/, extracts: slug, number, status of each artifact,
# and overall progress (which steps are complete).
#
# Usage:
#   .docs-scripts/list-features.sh [--json]
#
# Exit codes:
#   0 — listed
#   2 — script error

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

JSON=false
if [[ "${1:-}" == "--json" ]]; then
  JSON=true
  require_jq
fi

features_json="[]"
total=0

for dir in "$FEATURES_DIR"/*/; do
  [[ -d "$dir" ]] || continue
  name=$(basename "$dir")
  [[ "$name" == "_template" ]] && continue
  total=$((total + 1))

  # Extract number and slug
  number=""
  slug="$name"
  if [[ "$name" =~ ^([0-9]+)-(.+)$ ]]; then
    number="${BASH_REMATCH[1]}"
    slug="${BASH_REMATCH[2]}"
  fi

  # Status of each step
  step_status="[]"
  steps_done=0
  steps_total=0
  for step_file in $FEATURE_FILES; do
    steps_total=$((steps_total + 1))
    f="$dir$step_file"
    if [[ -f "$f" ]]; then
      ph=$(count_placeholders "$f")
      st=$(get_artifact_status "$f" 2>/dev/null || echo "")
      done_state="draft"
      if [[ "$ph" -eq 0 ]] && [[ -n "$st" ]] && [[ "$st" != "Draft" ]]; then
        done_state="ready"
        steps_done=$((steps_done + 1))
      elif [[ "$ph" -eq 0 ]]; then
        done_state="filled"
      fi
      if [[ "$JSON" == "true" ]]; then
        step_status=$(echo "$step_status" | jq \
          --arg file "$step_file" \
          --arg status "$st" \
          --argjson placeholders "$ph" \
          --arg state "$done_state" \
          '. + [{file: $file, status: $status, placeholders: $placeholders, state: $state}]')
      fi
    else
      if [[ "$JSON" == "true" ]]; then
        step_status=$(echo "$step_status" | jq \
          --arg file "$step_file" \
          '. + [{file: $file, status: "missing", placeholders: 0, state: "missing"}]')
      fi
    fi
  done

  # Count ADRs
  adr_count=0
  for adr_file in "$dir"/06_ADR-*.md; do
    [[ -f "$adr_file" ]] || continue
    name_adr=$(basename "$adr_file")
    if [[ "$name_adr" != "06_ADR-001_[title].md" ]]; then
      adr_count=$((adr_count + 1))
    fi
  done

  if [[ "$JSON" == "true" ]]; then
    features_json=$(echo "$features_json" | jq \
      --arg dir "$dir" \
      --arg name "$name" \
      --arg number "$number" \
      --arg slug "$slug" \
      --argjson steps_done "$steps_done" \
      --argjson steps_total "$steps_total" \
      --argjson adr_count "$adr_count" \
      --argjson steps "$step_status" \
      '. + [{
        dir: $dir,
        name: $name,
        number: $number,
        slug: $slug,
        progress: {done: $steps_done, total: $steps_total},
        adr_count: $adr_count,
        steps: $steps
      }]')
  fi
done

if [[ "$JSON" == "true" ]]; then
  jq -n \
    --argjson total "$total" \
    --arg features_dir "$FEATURES_DIR" \
    --argjson features "$features_json" \
    '{features_dir: $features_dir, total: $total, features: $features}'
else
  echo "Features in: $FEATURES_DIR"
  echo "Total: $total"
  echo
  for dir in "$FEATURES_DIR"/*/; do
    [[ -d "$dir" ]] || continue
    name=$(basename "$dir")
    [[ "$name" == "_template" ]] && continue
    done_count=0
    total_count=0
    for step_file in $FEATURE_FILES; do
      total_count=$((total_count + 1))
      f="$dir$step_file"
      if [[ -f "$f" ]]; then
        ph=$(count_placeholders "$f")
        st=$(get_artifact_status "$f" 2>/dev/null || echo "")
        if [[ "$ph" -eq 0 ]] && [[ -n "$st" ]] && [[ "$st" != "Draft" ]]; then
          done_count=$((done_count + 1))
        fi
      fi
    done
    printf "  %-40s %d/%d steps ready\n" "$name" "$done_count" "$total_count"
  done
fi
