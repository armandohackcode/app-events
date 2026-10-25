#!/usr/bin/env bash
# PostToolUse (Edit|Write|MultiEdit) on .dart files:
#   1. formats the file,
#   2. lib/: rejects imports that break the layer rules,
#   3. test/: rejects skips without a 'BUG:' reason and new architecture debt.
# The authoritative rules live in test/architecture/layer_dependencies_test.dart;
# this hook mirrors them for immediate feedback.
set -euo pipefail

root=${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}
file=$(jq -r '.tool_response.filePath // .tool_input.file_path // empty')
[[ "$file" == *.dart && -f "$file" ]] || exit 0
rel=${file#"$root"/}
arch_test="$root/test/architecture/layer_dependencies_test.dart"

dart format "$file" >/dev/null

errors=()

case "$rel" in
  lib/domain/*)
    forbidden='^(package:flutter/|package:cloud_firestore/|package:firebase_|package:provider/|package:app_events/(data|ui|config)/|dart:io)'
    reason='domain must be pure Dart and must not depend on any implementation' ;;
  lib/data/*)
    forbidden='^(package:flutter/(material|widgets|cupertino)\.dart|package:provider/|package:app_events/(ui|config)/)'
    reason='data implements domain contracts and must not know about the UI' ;;
  lib/ui/*)
    forbidden='^(package:cloud_firestore/|package:firebase_|package:app_events/data/|package:app_events/config/di/)'
    reason='ui talks only to abstract repositories from domain' ;;
  *) forbidden='' ;;
esac

if [[ -n "$forbidden" ]]; then
  while IFS= read -r import; do
    [[ -z "$import" ]] && continue
    # Debt already listed in the architecture test baseline is tolerated.
    grep -qF "'$rel|$import'" "$arch_test" 2>/dev/null && continue
    errors+=("$rel imports $import ($reason)")
  done < <(grep -E "^\s*(import|export)\s+['\"]" "$file" |
    sed -E "s/^[[:space:]]*(import|export)[[:space:]]+['\"]([^'\"]+)['\"].*/\2/" |
    grep -E "$forbidden" || true)
fi

# Hardcoded texts, colors, assets and URLs belong in lib/config/theme
# (mirrors test/architecture/hardcoded_values_test.dart).
if [[ "$rel" == lib/ui/* || "$rel" == lib/main.dart ]]; then
  while IFS= read -r finding; do
    errors+=("$rel:$finding")
  done < <(perl -ne '
    next if /^\s*\/\//;
    my @hits;
    push @hits, "hardcoded text (use AppStrings)" if /\bText\(\s*[\x27"](?![\x27"]|\$\{)/;
    push @hits, "hardcoded label (use AppStrings)" if /\b(labelText|hintText|helperText|tooltip|semanticLabel|semanticsLabel)\s*:\s*[\x27"](?![\x27"]|\$\{)/;
    push @hits, "hardcoded color (use AppStyles)" if /\bColor\(0x|\bColor\.from(ARGB|RGBO)\(|\bColors\.(?!transparent\b)\w+/;
    push @hits, "hardcoded asset path (use AppAssetsPath)" if /[\x27"]assets\//;
    push @hits, "hardcoded URL (use AppLinks)" if /[\x27"]https?:\/\//;
    print "$.: $_\n" for @hits;
  ' "$file")
fi

if [[ "$rel" == test/* ]]; then
  while IFS= read -r line; do
    errors+=("$rel:$line skip without a 'BUG: <description>' reason. Tests must assert correct behavior; known bugs are skipped only with skip: 'BUG: ...'")
  done < <(grep -nE "skip:\s*" "$file" | grep -vE "skip:\s*'BUG: " | cut -d: -f1 || true)
fi

if [[ "$file" == "$arch_test" ]] && git -C "$root" cat-file -e "HEAD:$rel" 2>/dev/null; then
  count() { grep -cE "^\s*'lib/[^']+\|[^']+',?$" || true; }
  before=$(git -C "$root" show "HEAD:$rel" | count)
  after=$(count < "$file")
  if (( after > before )); then
    errors+=("New entries in _knownViolations: fix the layer violation instead of adding it to the baseline")
  fi
fi

if (( ${#errors[@]} > 0 )); then
  printf 'Project rules violated (see CLAUDE.md):\n' >&2
  printf ' - %s\n' "${errors[@]}" >&2
  exit 2
fi
