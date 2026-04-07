#!/usr/bin/env bash
#
# parse-design-endpoints.sh — Extract API endpoints from 03_technical-design.md
#
# Parses the Endpoints table (Method | Path | Description | Auth) and returns
# a JSON list. Also detects: data model entities, sequence diagrams count.
#
# Usage:
#   .docs-scripts/parse-design-endpoints.sh <file>
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

endpoints_json="[]"
in_endpoints_table=false

while IFS= read -r line; do
  # Detect endpoint table header (Method | Path | Description | Auth)
  if echo "$line" | grep -qE "^\| Method"; then
    in_endpoints_table=true
    continue
  fi
  # Reset on empty line or new heading
  if [[ "$in_endpoints_table" == "true" ]]; then
    if [[ -z "$line" ]] || echo "$line" | grep -qE "^##? "; then
      in_endpoints_table=false
      continue
    fi
    if echo "$line" | grep -qE "^\| "; then
      trimmed=$(echo "$line" | sed 's/^| *//; s/ *|$//')
      method=$(echo "$trimmed" | awk -F'|' '{gsub(/^ +| +$/, "", $1); gsub(/`/, "", $1); print $1}')
      path=$(echo "$trimmed" | awk -F'|' '{gsub(/^ +| +$/, "", $2); gsub(/`/, "", $2); print $2}')
      desc=$(echo "$trimmed" | awk -F'|' '{gsub(/^ +| +$/, "", $3); print $3}')
      auth=$(echo "$trimmed" | awk -F'|' '{gsub(/^ +| +$/, "", $4); print $4}')
      # Skip header / separator / empty
      [[ "$method" == "-" ]] && continue
      [[ -z "$method" ]] && continue
      [[ "$method" == "[METHOD]" ]] && continue
      endpoints_json=$(echo "$endpoints_json" | jq \
        --arg m "$method" --arg p "$path" --arg d "$desc" --arg a "$auth" \
        '. + [{method: $m, path: $p, description: $d, auth: $a}]')
    fi
  fi
done < "$FILE"

# Count entities (look for "**`EntityName`**" patterns)
entity_count=$(grep -cE '^\*\*`[A-Z][a-zA-Z0-9_]*`\*\*' "$FILE" 2>/dev/null) || entity_count=0

# Count sequence diagrams (mermaid sequenceDiagram blocks)
seq_count=$(grep -c "sequenceDiagram" "$FILE" 2>/dev/null) || seq_count=0

# Count erDiagram
er_count=$(grep -c "erDiagram" "$FILE" 2>/dev/null) || er_count=0

ep_count=$(echo "$endpoints_json" | jq 'length')
status_value=$(get_artifact_status "$FILE" 2>/dev/null || echo "")

jq -n \
  --arg file "$FILE" \
  --arg status "$status_value" \
  --argjson endpoints "$endpoints_json" \
  --argjson endpoint_count "$ep_count" \
  --argjson entity_count "$entity_count" \
  --argjson seq_diagrams "$seq_count" \
  --argjson er_diagrams "$er_count" \
  '{
    file: $file,
    status: $status,
    endpoints: $endpoints,
    counts: {
      endpoints: $endpoint_count,
      entities: $entity_count,
      sequence_diagrams: $seq_diagrams,
      er_diagrams: $er_diagrams
    }
  }'
