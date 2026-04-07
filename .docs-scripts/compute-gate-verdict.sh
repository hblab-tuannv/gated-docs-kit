#!/usr/bin/env bash
#
# compute-gate-verdict.sh — Run structural checks for a review gate
#
# Each gate has a fixed set of structural items the script can verify
# deterministically. Semantic items (e.g. "does this test verify this FR?")
# are intentionally NOT checked here — those need AI judgment.
#
# Gates supported: G1, G2, G3, G4
#
# Usage:
#   .docs-scripts/compute-gate-verdict.sh --gate G2 --feature <slug-or-path> [--strict] [--json]
#
# Exit codes:
#   0 — PASS
#   1 — FAIL or PASS_WITH_WARNINGS (with --strict, also fails on warnings)
#   2 — script error

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

GATE=""
FEATURE=""
STRICT=false
JSON=false

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --gate)    needs_value "$1" "${2:-}"; GATE="$2"; shift 2 ;;
    --feature) needs_value "$1" "${2:-}"; FEATURE="$2"; shift 2 ;;
    --strict)  STRICT=true; shift ;;
    --json)    JSON=true; shift ;;
    -h|--help)
      sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) log_error "Unknown arg: $1"; exit 2 ;;
  esac
done

if [[ -z "$GATE" ]]; then
  log_error "--gate is required (G1|G2|G3|G4)"
  exit 2
fi
if [[ -z "$FEATURE" ]]; then
  log_error "--feature is required"
  exit 2
fi
[[ "$JSON" == "true" ]] && require_jq

feature_dir=$(resolve_feature_dir "$FEATURE" || true)
if [[ -z "$feature_dir" ]] || [[ ! -d "$feature_dir" ]]; then
  log_error "Feature folder not found: $FEATURE"
  exit 1
fi

# Helper: append a check result
items_json="[]"
pass=0
fail=0
warn=0
na=0

add_item() {
  local name="$1"
  local result="$2"  # pass | fail | warn | na
  local evidence="$3"
  local fix="${4:-}"

  case "$result" in
    pass) pass=$((pass + 1)) ;;
    fail) fail=$((fail + 1)) ;;
    warn) warn=$((warn + 1)) ;;
    na)   na=$((na + 1)) ;;
  esac

  if [[ "$JSON" == "true" ]]; then
    items_json=$(echo "$items_json" | jq \
      --arg name "$name" \
      --arg result "$result" \
      --arg evidence "$evidence" \
      --arg fix "$fix" \
      '. + [{item: $name, result: $result, evidence: $evidence, fix: $fix}]')
  fi
}

# ──────────────────────────────────────────────────────────────────
#  Gate-specific structural checks (deterministic only)
# ──────────────────────────────────────────────────────────────────
case "$GATE" in
  G1)
    # PRD Review
    prd="$feature_dir/01_PRD.md"

    if [[ ! -f "$prd" ]]; then
      add_item "01_PRD.md exists" "fail" "file not found" "Run /docs-03-prd to author the PRD"
    else
      add_item "01_PRD.md exists" "pass" "file present"

      status=$(get_artifact_status "$prd")
      if [[ -z "$status" ]]; then
        add_item "PRD status field is set" "fail" "status is empty or placeholder" "Run /docs-03-prd to author the PRD (will auto-set Draft)"
      else
        add_item "PRD status field is set" "pass" "current: $status"
      fi

      nc=$(count_needs_clarification "$prd")
      if [[ "$nc" -gt 3 ]]; then
        add_item "≤3 NEEDS CLARIFICATION markers" "fail" "$nc markers found" "Resolve clarifications before review"
      elif [[ "$nc" -gt 0 ]]; then
        add_item "≤3 NEEDS CLARIFICATION markers" "warn" "$nc markers (within limit)" "Resolve before approval"
      else
        add_item "≤3 NEEDS CLARIFICATION markers" "pass" "0 markers"
      fi

      ph=$(count_placeholders "$prd")
      if [[ "$ph" -gt 0 ]]; then
        add_item "All [PLACEHOLDER] tokens filled" "fail" "$ph placeholders remain" "Fill all template placeholders"
      else
        add_item "All [PLACEHOLDER] tokens filled" "pass" "0 placeholders"
      fi

      # Has Problem section
      if grep -q "^## Problem" "$prd"; then
        add_item "Problem section present" "pass" "found ## Problem"
      else
        add_item "Problem section present" "fail" "## Problem missing" "Add Problem section"
      fi

      # Has Requirements / FR table
      if grep -qE "^\| FR-[0-9]+" "$prd"; then
        fr_count=$(grep -cE "^\| FR-[0-9]+" "$prd" || echo 0)
        add_item "Functional requirements present" "pass" "$fr_count FRs found"

        # Check that priority column has values (no empty)
        empty_priority=$(awk -F'|' '
          /^\| FR-[0-9]+/ {
            p = $4
            gsub(/^ +| +$/, "", p)
            if (p == "" || p == "[PRIORITY]") count++
          }
          END {print count + 0}
        ' "$prd")
        if [[ "$empty_priority" -gt 0 ]]; then
          add_item "All FRs have priority assigned" "fail" "$empty_priority FRs missing priority" "Assign P0/P1/P2 to each FR"
        else
          add_item "All FRs have priority assigned" "pass" "all $fr_count FRs prioritized"
        fi
      else
        add_item "Functional requirements present" "fail" "no FR-XXX rows found" "Add Requirements table with FR-001, FR-002..."
      fi

      # Has Acceptance criteria
      if grep -q "^## Acceptance criteria" "$prd"; then
        add_item "Acceptance criteria section present" "pass" "found"
      else
        add_item "Acceptance criteria section present" "fail" "## Acceptance criteria missing" "Add acceptance criteria with Given/When/Then"
      fi
    fi
    ;;

  G2)
    # Design Review
    prd="$feature_dir/01_PRD.md"
    impact="$feature_dir/02_change-impact.md"
    design="$feature_dir/03_technical-design.md"

    # PRD prerequisite
    if [[ ! -f "$prd" ]]; then
      add_item "01_PRD.md exists (prerequisite)" "fail" "missing" "Run /docs-03-prd first"
    else
      pstatus=$(get_artifact_status "$prd")
      if [[ "$pstatus" != "Approved" ]]; then
        add_item "01_PRD.md is Approved (G1 passed)" "fail" "status: ${pstatus:-(unset)}" "Run G1 first — PRD must be Approved before G2"
      else
        add_item "01_PRD.md is Approved (G1 passed)" "pass" "Approved"
      fi
    fi

    # Change impact
    if [[ ! -f "$impact" ]]; then
      add_item "02_change-impact.md exists" "fail" "missing" "Run /docs-04-change-impact"
    else
      add_item "02_change-impact.md exists" "pass" "present"
      ph=$(count_placeholders "$impact")
      if [[ "$ph" -gt 0 ]]; then
        add_item "Change impact placeholders filled" "fail" "$ph remain" "Fill template placeholders"
      else
        add_item "Change impact placeholders filled" "pass" "0 remain"
      fi
    fi

    # Technical design
    if [[ ! -f "$design" ]]; then
      add_item "03_technical-design.md exists" "fail" "missing" "Run /docs-05-technical-design"
    else
      add_item "03_technical-design.md exists" "pass" "present"

      dstatus=$(get_artifact_status "$design")
      if [[ -z "$dstatus" ]]; then
        add_item "Design status field is set" "fail" "status is empty or placeholder" "Run /docs-05-technical-design (will auto-set Draft)"
      else
        add_item "Design status field is set" "pass" "current: $dstatus"
      fi

      ph=$(count_placeholders "$design")
      if [[ "$ph" -gt 0 ]]; then
        add_item "Design placeholders filled" "fail" "$ph remain" "Fill template placeholders"
      else
        add_item "Design placeholders filled" "pass" "0 remain"
      fi

      if grep -q "^## Overview" "$design"; then
        add_item "Overview section present" "pass" "found"
      else
        add_item "Overview section present" "fail" "## Overview missing" "Add Overview section"
      fi

      # If has API mention, expect Authorization or Auth column
      if grep -qiE "^## API|## Endpoints" "$design"; then
        if grep -qiE "^### Authorization|^## Authorization|\| auth " "$design"; then
          add_item "API endpoints have authorization documented" "pass" "auth references found"
        else
          add_item "API endpoints have authorization documented" "warn" "no Authorization section detected" "Document who can call each endpoint"
        fi
      fi

      # If has migration code block
      if grep -q "Migration" "$design"; then
        if grep -q "^-- Up" "$design" && grep -q "^-- Down" "$design"; then
          add_item "Migration has both Up and Down" "pass" "both found"
        else
          add_item "Migration has both Up and Down" "warn" "missing one direction" "Add reverse migration"
        fi
      fi
    fi
    ;;

  G3)
    # Code Review — script can only do file/path-level checks
    design="$feature_dir/03_technical-design.md"

    if [[ ! -f "$design" ]]; then
      add_item "Technical design exists" "fail" "missing" "Author design before code review"
    else
      add_item "Technical design exists" "pass" "found"
    fi

    # Look for source code in standard locations
    src_found=false
    for src in "$PROJECT_ROOT/src" "$PROJECT_ROOT/app" "$PROJECT_ROOT/lib"; do
      [[ -d "$src" ]] && src_found=true
    done
    if [[ "$src_found" == "true" ]]; then
      add_item "Source code directory exists" "pass" "src/ or app/ or lib/ found"
    else
      add_item "Source code directory exists" "warn" "no standard src dir" "Manual verification needed"
    fi

    # Look for test directory
    test_found=false
    for t in "$PROJECT_ROOT/tests" "$PROJECT_ROOT/test" "$PROJECT_ROOT/__tests__" "$PROJECT_ROOT/spec"; do
      [[ -d "$t" ]] && test_found=true
    done
    if [[ "$test_found" == "true" ]]; then
      add_item "Test directory exists" "pass" "found"
    else
      add_item "Test directory exists" "warn" "no test dir" "Add tests"
    fi

    # Hardcoded secrets quick scan over every detected source dir
    if [[ "$src_found" == "true" ]]; then
      total_hits=0
      scanned_dirs=""
      for src_dir in "$PROJECT_ROOT/src" "$PROJECT_ROOT/app" "$PROJECT_ROOT/lib"; do
        [[ -d "$src_dir" ]] || continue
        scanned_dirs="$scanned_dirs $(basename "$src_dir")/"
        local_hits=$(grep -rE "(password|api_key|secret)\s*[:=]\s*['\"][^'\"]{6,}['\"]" \
          --include="*.js" --include="*.ts" --include="*.py" --include="*.go" \
          --include="*.java" --include="*.rb" --include="*.php" \
          "$src_dir" 2>/dev/null \
          | grep -v ".env.example" \
          | wc -l \
          | awk '{print $1}') || local_hits=0
        total_hits=$((total_hits + local_hits))
      done
      if [[ "$total_hits" -gt 0 ]]; then
        add_item "No hardcoded secrets in source" "fail" "$total_hits suspicious lines in${scanned_dirs}" "Review and move to env vars"
      else
        add_item "No hardcoded secrets in source" "pass" "0 hits across${scanned_dirs}"
      fi
    fi

    add_item "Manual checklist items (semantic)" "na" "G3 requires human review of code quality" "Reviewer evaluates manually"
    ;;

  G4)
    # QA Sign-off
    test_plan="$feature_dir/04_test-plan.md"
    matrix="$feature_dir/05_traceability-matrix.md"

    if [[ ! -f "$test_plan" ]]; then
      add_item "04_test-plan.md exists" "fail" "missing" "Run /docs-06-test-plan"
    else
      add_item "04_test-plan.md exists" "pass" "present"
      ph=$(count_placeholders "$test_plan")
      if [[ "$ph" -gt 0 ]]; then
        add_item "Test plan placeholders filled" "fail" "$ph remain" "Fill placeholders"
      else
        add_item "Test plan placeholders filled" "pass" "0 remain"
      fi
    fi

    if [[ ! -f "$matrix" ]]; then
      add_item "05_traceability-matrix.md exists" "fail" "missing" "Run /docs-07-traceability"
    else
      add_item "05_traceability-matrix.md exists" "pass" "present"

      # Count statuses ONLY in matrix table rows (lines starting with `|`).
      # Avoids false-positives from the status legend ("✅ Pass / ❌ Fail / ...")
      # and from prose elsewhere in the document.
      pass_count=$(grep -c "^|.*✅" "$matrix" 2>/dev/null) || pass_count=0
      fail_count=$(grep -c "^|.*❌" "$matrix" 2>/dev/null) || fail_count=0
      open_count=$(grep -c "^|.*⬜" "$matrix" 2>/dev/null) || open_count=0
      progress_count=$(grep -c "^|.*🔄" "$matrix" 2>/dev/null) || progress_count=0

      if [[ "$fail_count" -gt 0 ]]; then
        add_item "No failing tests in matrix" "fail" "$fail_count ❌ rows" "Fix failing tests"
      else
        add_item "No failing tests in matrix" "pass" "0 failures"
      fi

      if [[ "$open_count" -gt 0 ]] || [[ "$progress_count" -gt 0 ]]; then
        add_item "All FRs reach ✅ status" "fail" "$open_count ⬜, $progress_count 🔄" "Run tests until all pass"
      else
        add_item "All FRs reach ✅ status" "pass" "$pass_count ✅ rows"
      fi
    fi
    ;;

  *)
    log_error "Unknown gate: $GATE (expected G1|G2|G3|G4)"
    exit 2
    ;;
esac

# ──────────────────────────────────────────────────────────────────
#  Compute verdict
# ──────────────────────────────────────────────────────────────────
verdict="PASS"
if [[ "$fail" -gt 0 ]]; then
  verdict="FAIL"
elif [[ "$warn" -gt 0 ]]; then
  if [[ "$STRICT" == "true" ]]; then
    verdict="FAIL"
  else
    verdict="PASS_WITH_WARNINGS"
  fi
fi

total=$((pass + fail + warn + na))

if [[ "$JSON" == "true" ]]; then
  jq -n \
    --arg gate "$GATE" \
    --arg feature_dir "$feature_dir" \
    --arg verdict "$verdict" \
    --argjson strict "$STRICT" \
    --argjson total "$total" \
    --argjson pass "$pass" \
    --argjson fail "$fail" \
    --argjson warn "$warn" \
    --argjson na "$na" \
    --argjson items "$items_json" \
    '{
      gate: $gate,
      feature_dir: $feature_dir,
      strict: $strict,
      verdict: $verdict,
      summary: {total: $total, pass: $pass, fail: $fail, warnings: $warn, na: $na},
      items: $items,
      note: "Script checks structural items only. Semantic items (mapping correctness, content quality) require AI/human review."
    }'
else
  echo "═══════════════════════════════════════════"
  echo "  Gate $GATE — $feature_dir"
  echo "═══════════════════════════════════════════"
  echo
  echo "Summary: $pass ✅ / $warn ⚠️ / $fail ❌ / $na ⊘ (total $total)"
  echo
  echo "VERDICT: $verdict"
  [[ "$STRICT" == "true" ]] && echo "(strict mode: warnings count as failures)"
  echo
  echo "Note: Script checks structural items only."
  echo "      Semantic items require AI or human review."
fi

if [[ "$verdict" == "PASS" ]] || [[ "$verdict" == "PASS_WITH_WARNINGS" && "$STRICT" != "true" ]]; then
  exit 0
else
  exit 1
fi
