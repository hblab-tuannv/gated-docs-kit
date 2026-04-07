#!/usr/bin/env bash
#
# next-adr-number.sh — Find the next ADR number for a feature
#
# Scans 06_ADR-*.md files in the feature folder and returns the next
# sequential number padded to 3 digits. Skips the placeholder
# 06_ADR-001_[title].md if it still has the literal "[title]" suffix.
#
# Usage:
#   .docs-scripts/next-adr-number.sh --feature <slug-or-path> [--title "decision-slug"]
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
TITLE=""
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --feature) needs_value "$1" "${2:-}"; FEATURE="$2"; shift 2 ;;
    --title)   needs_value "$1" "${2:-}"; TITLE="$2"; shift 2 ;;
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

# Scan existing ADRs
existing_json="[]"
max=0
placeholder_present=false

for f in "$feature_dir"/06_ADR-*.md; do
  [[ -f "$f" ]] || continue
  name=$(basename "$f")
  if [[ "$name" =~ ^06_ADR-([0-9]+)_(.+)\.md$ ]]; then
    num="${BASH_REMATCH[1]}"
    rest="${BASH_REMATCH[2]}"
    if [[ "$rest" == "[title]" ]]; then
      placeholder_present=true
      continue
    fi
    n=$((10#$num))
    if [[ "$n" -gt "$max" ]]; then
      max=$n
    fi
    existing_json=$(echo "$existing_json" | jq \
      --arg num "$num" --arg title "$rest" --arg file "$name" \
      '. + [{number: $num, title: $title, file: $file}]')
  fi
done

# If only placeholder exists, next number is 001
if [[ "$max" -eq 0 ]] && [[ "$placeholder_present" == "true" ]]; then
  next=1
else
  next=$((max + 1))
fi

next_padded=$(printf "%03d" "$next")

# Build suggested filename if title provided
suggested_file=""
if [[ -n "$TITLE" ]]; then
  title_slug=$(slugify "$TITLE" 5)
  suggested_file="06_ADR-${next_padded}_${title_slug}.md"
fi

jq -n \
  --arg feature_dir "$feature_dir" \
  --arg next "$next_padded" \
  --argjson existing "$existing_json" \
  --argjson placeholder_present "$placeholder_present" \
  --arg suggested_file "$suggested_file" \
  '{
    feature_dir: $feature_dir,
    next_number: $next,
    placeholder_present: $placeholder_present,
    existing_adrs: $existing,
    suggested_file: $suggested_file
  }'
