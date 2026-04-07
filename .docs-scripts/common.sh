#!/usr/bin/env bash
# Common functions for docs workflow scripts.
# Source from other scripts: source "$(dirname "$0")/common.sh"
#
# Compatible with bash 3.2 (macOS default). Avoid bash 4+ features.

set -euo pipefail

# ──────────────────────────────────────────────────────────────────
#  Project root discovery
# ──────────────────────────────────────────────────────────────────
find_project_root() {
  local dir
  dir="$(pwd)"
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/docs/_common" ]] && [[ -d "$dir/docs/features" ]]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  echo "ERROR: Not in a project with docs/_common/ and docs/features/" >&2
  return 1
}

PROJECT_ROOT="$(find_project_root)"
DOCS_DIR="$PROJECT_ROOT/docs"
COMMON_DIR="$DOCS_DIR/_common"
FEATURES_DIR="$DOCS_DIR/features"
TEMPLATE_DIR="$FEATURES_DIR/_template"
SCRIPTS_DIR="$PROJECT_ROOT/.docs-scripts"

export PROJECT_ROOT DOCS_DIR COMMON_DIR FEATURES_DIR TEMPLATE_DIR SCRIPTS_DIR

# ──────────────────────────────────────────────────────────────────
#  Required Common files
# ──────────────────────────────────────────────────────────────────
COMMON_FILES="architecture.md api-conventions.md security-baseline.md test-strategy.md glossary.md review-gates.md"

# Per-feature template files (numbered 01..06)
FEATURE_FILES="01_PRD.md 02_change-impact.md 03_technical-design.md 04_test-plan.md 05_traceability-matrix.md"
# ADR file is the placeholder; real ADR files match 06_ADR-*.md

# ──────────────────────────────────────────────────────────────────
#  Dependencies
# ──────────────────────────────────────────────────────────────────
require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: 'jq' is required but not installed." >&2
    echo "Install: brew install jq (macOS) or apt install jq (Linux)" >&2
    exit 2
  fi
}

# ──────────────────────────────────────────────────────────────────
#  Date / Git helpers
# ──────────────────────────────────────────────────────────────────
today() {
  date +%Y-%m-%d
}

git_user() {
  git config user.name 2>/dev/null || echo "unknown"
}

# ──────────────────────────────────────────────────────────────────
#  Slugify a feature description
#    "User authentication via OAuth2" -> "user-authentication-via"
# ──────────────────────────────────────────────────────────────────
slugify() {
  local text="$1"
  local max_words="${2:-4}"
  echo "$text" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9 ]+/ /g' \
    | tr -s ' ' \
    | awk -v max="$max_words" '{
        n = (NF > max) ? max : NF
        out = ""
        for (i = 1; i <= n; i++) {
          out = out $i
          if (i < n) out = out "-"
        }
        print out
      }'
}

# ──────────────────────────────────────────────────────────────────
#  Resolve a feature input (slug or path) to an absolute path
# ──────────────────────────────────────────────────────────────────
resolve_feature_dir() {
  local input="$1"

  if [[ -z "$input" ]]; then
    return 1
  fi

  # Already an existing absolute or relative directory
  if [[ -d "$input" ]]; then
    (cd "$input" && pwd)
    return 0
  fi

  # Try as relative to features directory
  if [[ -d "$FEATURES_DIR/$input" ]]; then
    echo "$FEATURES_DIR/$input"
    return 0
  fi

  # Try matching by slug suffix
  local match
  match=$(find "$FEATURES_DIR" -mindepth 1 -maxdepth 1 -type d ! -name "_template" 2>/dev/null \
    | grep -E "/(([0-9]+-)?${input}|${input}(-|$))" \
    | head -1 || true)
  if [[ -n "$match" ]]; then
    echo "$match"
    return 0
  fi

  return 1
}

# ──────────────────────────────────────────────────────────────────
#  Next sequential feature number based on existing folders
# ──────────────────────────────────────────────────────────────────
next_feature_number() {
  local max=0
  local dir name num
  if [[ ! -d "$FEATURES_DIR" ]]; then
    printf "001"
    return
  fi
  for dir in "$FEATURES_DIR"/*/; do
    [[ -d "$dir" ]] || continue
    name="$(basename "$dir")"
    [[ "$name" == "_template" ]] && continue
    if [[ "$name" =~ ^([0-9]+)- ]]; then
      num="${BASH_REMATCH[1]}"
      num=$((10#$num))
      if [[ "$num" -gt "$max" ]]; then
        max="$num"
      fi
    fi
  done
  printf "%03d" $((max + 1))
}

# ──────────────────────────────────────────────────────────────────
#  Frontmatter / status field helpers
#  Templates use bold field markers (e.g. **Status**: Draft)
# ──────────────────────────────────────────────────────────────────
get_artifact_status() {
  local file="$1"
  [[ -f "$file" ]] || return 1
  local raw
  raw=$(awk '
    /^\*\*Status\*\*:/ {
      sub(/^\*\*Status\*\*:[[:space:]]*/, "")
      sub(/[[:space:]]*$/, "")
      print
      exit
    }
  ' "$file")
  # Strip template placeholder values like "[Draft | In Review | Approved]"
  # so callers see an empty string for un-filled templates rather than the
  # bracketed literal.
  case "$raw" in
    \[*\]) echo "" ;;
    "")    echo "" ;;
    *)     echo "$raw" ;;
  esac
}

set_artifact_status() {
  local file="$1"
  local new_status="$2"
  [[ -f "$file" ]] || return 1
  if grep -q '^\*\*Status\*\*:' "$file"; then
    # macOS sed needs '' after -i
    sed -i '' "s|^\*\*Status\*\*:.*|**Status**: $new_status|" "$file"
    return 0
  fi
  return 1
}

# ──────────────────────────────────────────────────────────────────
#  Counts (placeholders, NEEDS markers)
#
#  All count functions output a single integer on stdout, no whitespace.
#  They never fail (return 0 even if file empty or grep finds nothing).
#  Wrapped to be safe under `set -o pipefail`.
# ──────────────────────────────────────────────────────────────────
count_placeholders() {
  local file="$1"
  [[ -f "$file" ]] || { echo 0; return; }
  # Match [UPPERCASE_TOKENS] but exclude markdown links [text](url)
  { grep -oE '\[[A-Z][A-Z0-9_]*\]' "$file" 2>/dev/null || true; } \
    | wc -l \
    | awk '{print $1}'
}

count_needs_evidence() {
  local file="$1"
  [[ -f "$file" ]] || { echo 0; return; }
  local n
  n=$(grep -c 'NEEDS EVIDENCE' "$file" 2>/dev/null) || n=0
  echo "$n"
}

count_needs_clarification() {
  local file="$1"
  [[ -f "$file" ]] || { echo 0; return; }
  local n
  n=$(grep -c 'NEEDS CLARIFICATION' "$file" 2>/dev/null) || n=0
  echo "$n"
}

# ──────────────────────────────────────────────────────────────────
#  Section presence check
#    args: file "## Header 1" "## Header 2" ...
#    Returns 0 if all sections present, 1 otherwise
#    Echoes missing sections to stderr
# ──────────────────────────────────────────────────────────────────
check_sections() {
  local file="$1"
  shift
  local missing=0
  local section
  for section in "$@"; do
    if ! grep -qF "$section" "$file"; then
      echo "$section" >&2
      missing=$((missing + 1))
    fi
  done
  return "$missing"
}

# ──────────────────────────────────────────────────────────────────
#  Logging (to stderr so JSON output stays clean on stdout)
# ──────────────────────────────────────────────────────────────────
log_info() { echo "ℹ️  $*" >&2; }
log_warn() { echo "⚠️  $*" >&2; }
log_error() { echo "❌ $*" >&2; }
log_ok()    { echo "✅ $*" >&2; }

# ──────────────────────────────────────────────────────────────────
#  Argument parsing helpers
# ──────────────────────────────────────────────────────────────────
# usage: needs_value flag value
needs_value() {
  if [[ -z "${2:-}" ]] || [[ "${2:-}" == --* ]]; then
    log_error "Flag '$1' requires a value"
    exit 2
  fi
}
