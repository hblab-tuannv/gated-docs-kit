#!/usr/bin/env bash
#
# create-feature-folder.sh — Atomically scaffold a new feature folder
#
# Generates a slug, picks the next sequential number (or a timestamp prefix
# when --timestamp is passed), copies the _template/ directory, and pre-fills
# author/date/feature-name metadata in the 6 template files.
#
# Usage:
#   .docs-scripts/create-feature-folder.sh --description "User authentication via OAuth2" [--slug user-auth-oauth2] [--timestamp] [--force] [--json]
#
# Numbering modes:
#   sequential (default) — features/001-slug, features/002-slug, ...
#   timestamp (--timestamp) — features/YYYYMMDD-HHMMSS-slug
#
# Exit codes:
#   0 — created
#   1 — folder already exists or _template missing
#   2 — script error

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

DESCRIPTION=""
SLUG=""
NUMBERING_MODE="sequential"
FORCE=false
JSON=false

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --description) needs_value "$1" "${2:-}"; DESCRIPTION="$2"; shift 2 ;;
    --slug)        needs_value "$1" "${2:-}"; SLUG="$2"; shift 2 ;;
    --timestamp)   NUMBERING_MODE="timestamp"; shift ;;
    --sequential)  NUMBERING_MODE="sequential"; shift ;;
    --force)       FORCE=true; shift ;;
    --json)        JSON=true; shift ;;
    -h|--help)
      sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) log_error "Unknown arg: $1"; exit 2 ;;
  esac
done

if [[ -z "$DESCRIPTION" ]]; then
  log_error "--description is required"
  exit 2
fi
[[ "$JSON" == "true" ]] && require_jq

# Verify template exists
if [[ ! -d "$TEMPLATE_DIR" ]]; then
  log_error "Template directory not found: $TEMPLATE_DIR"
  exit 1
fi

# Verify all 6 template files present
for f in $FEATURE_FILES; do
  if [[ ! -f "$TEMPLATE_DIR/$f" ]]; then
    log_error "Template file missing: $TEMPLATE_DIR/$f"
    exit 1
  fi
done
# ADR is always 06_ADR-001_[title].md in template
ADR_TEMPLATE="06_ADR-001_[title].md"
if [[ ! -f "$TEMPLATE_DIR/$ADR_TEMPLATE" ]]; then
  log_error "Template ADR file missing: $TEMPLATE_DIR/$ADR_TEMPLATE"
  exit 1
fi

# Generate slug if not provided
if [[ -z "$SLUG" ]]; then
  SLUG=$(slugify "$DESCRIPTION" 4)
fi

if [[ -z "$SLUG" ]]; then
  log_error "Could not generate slug from description"
  exit 2
fi

# Build folder name from chosen numbering mode (CLI flag drives this — no
# external config file required so the workflow stays self-contained).
if [[ "$NUMBERING_MODE" == "timestamp" ]]; then
  prefix=$(date +%Y%m%d-%H%M%S)
  folder_name="${prefix}-${SLUG}"
  feature_number="$prefix"
else
  feature_number=$(next_feature_number)
  folder_name="${feature_number}-${SLUG}"
fi
numbering_mode="$NUMBERING_MODE"

target_dir="$FEATURES_DIR/$folder_name"

# Check existence
if [[ -d "$target_dir" ]]; then
  if [[ "$FORCE" != "true" ]]; then
    if [[ "$JSON" == "true" ]]; then
      jq -n --arg dir "$target_dir" \
        '{status: "exists", error: "feature folder already exists", feature_dir: $dir}'
    else
      log_error "Folder already exists: $target_dir"
      log_info "Use --force to overwrite (not recommended)"
    fi
    exit 1
  else
    log_warn "Overwriting existing folder: $target_dir"
    rm -rf "$target_dir"
  fi
fi

# Atomic copy: copy to .tmp, then rename
tmp_dir="${target_dir}.tmp.$$"
trap 'rm -rf "$tmp_dir" 2>/dev/null || true' EXIT

cp -R "$TEMPLATE_DIR" "$tmp_dir"

# Pre-fill metadata in each file
author=$(git_user)
created=$(today)
files_created="[]"

# Escape for sed: backslash, ampersand, pipe, slashes
escape_sed_replacement() {
  echo "$1" | sed -e 's/[\&|/]/\\&/g'
}

esc_desc=$(escape_sed_replacement "$DESCRIPTION")
esc_author=$(escape_sed_replacement "$author")

for f in $FEATURE_FILES; do
  filepath="$tmp_dir/$f"
  [[ -f "$filepath" ]] || continue
  # Replace [FEATURE_NAME], [AUTHOR], [DATE]
  sed -i '' \
    -e "s|\[FEATURE_NAME\]|$esc_desc|g" \
    -e "s|\[AUTHOR\]|$esc_author|g" \
    -e "s|\[DATE\]|$created|g" \
    "$filepath"
  # Resolve the **Status** placeholder (e.g. "[Draft | In Review | Approved]"
  # or "[Draft / In Review / Approved]") to a concrete "Draft" value so
  # every scaffolded file has a valid, machine-readable status from day 1.
  # The traceability matrix ships with "Living document" and is left alone.
  if [[ "$f" != "05_traceability-matrix.md" ]]; then
    sed -i '' -E 's|^(\*\*Status\*\*:)[[:space:]]*\[[^]]*\]|\1 Draft|' "$filepath"
  fi
  if [[ "$JSON" == "true" ]]; then
    files_created=$(echo "$files_created" | jq --arg f "$f" '. + [$f]')
  fi
done

# Handle ADR template (also fill metadata, keep as 06_ADR-001_[title].md placeholder)
adr_path="$tmp_dir/$ADR_TEMPLATE"
if [[ -f "$adr_path" ]]; then
  sed -i '' \
    -e "s|\[FEATURE_NAME\]|$esc_desc|g" \
    -e "s|\[AUTHOR\]|$esc_author|g" \
    -e "s|\[DATE\]|$created|g" \
    -e "s|\[DECIDERS\]|$esc_author|g" \
    "$adr_path"
  # ADRs use the "Proposed" initial state, not "Draft"
  sed -i '' -E 's|^(\*\*Status\*\*:)[[:space:]]*\[[^]]*\]|\1 Proposed|' "$adr_path"
  if [[ "$JSON" == "true" ]]; then
    files_created=$(echo "$files_created" | jq --arg f "$ADR_TEMPLATE" '. + [$f]')
  fi
fi

# Atomic rename
mv "$tmp_dir" "$target_dir"
trap - EXIT

if [[ "$JSON" == "true" ]]; then
  jq -n \
    --arg status "created" \
    --arg dir "$target_dir" \
    --arg slug "$SLUG" \
    --arg number "$feature_number" \
    --arg numbering "$numbering_mode" \
    --arg author "$author" \
    --arg date "$created" \
    --arg description "$DESCRIPTION" \
    --argjson files "$files_created" \
    '{
      status: $status,
      feature_dir: $dir,
      feature_slug: $slug,
      feature_number: $number,
      numbering_mode: $numbering,
      metadata: {author: $author, date: $date, description: $description},
      files_created: $files
    }'
else
  log_ok "Created feature folder: $target_dir"
  echo
  echo "Slug: $SLUG"
  echo "Number: $feature_number ($numbering_mode mode)"
  echo "Author: $author"
  echo "Date: $created"
  echo
  echo "Files scaffolded:"
  ls "$target_dir" | sed 's/^/  📄 /'
fi
