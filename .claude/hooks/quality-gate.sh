#!/usr/bin/env bash
# Stop: before Claude finishes a turn with Dart changes, run the same checks
# as CI (format, analyze, spelling, tests). A failure blocks the stop and the
# output goes back to Claude to fix. Skips when nothing changed since the last
# passing run.
set -uo pipefail

root=${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}
cd "$root" || exit 0

[[ "$(jq -r '.stop_hook_active // false')" == "true" ]] && exit 0

paths=(lib test pubspec.yaml .cspell.json .cspell)
[[ -z "$(git status --porcelain -- "${paths[@]}")" ]] && exit 0

state_file=.dart_tool/claude-quality-gate.sha
state=$({
  git diff HEAD -- "${paths[@]}"
  git ls-files --others --exclude-standard -z -- "${paths[@]}" | xargs -0 cat 2>/dev/null
} | shasum | cut -d' ' -f1)
[[ -f "$state_file" && "$(cat "$state_file")" == "$state" ]] && exit 0

fail() {
  printf 'Quality gate failed at "%s". Fix it before finishing:\n\n%s\n' "$1" "$2" | tail -n 60 >&2
  exit 2
}

out=$(dart format --output=none --set-exit-if-changed lib test 2>&1) || fail "dart format" "$out"
out=$(flutter analyze --fatal-infos 2>&1) || fail "flutter analyze" "$out"
if command -v npx >/dev/null; then
  out=$(npx --yes cspell@8.19.4 --no-progress --no-summary 2>&1) ||
    fail "cspell (Spanish text belongs only in AppStrings)" "$out"
fi
out=$(flutter test --reporter=failures-only 2>&1) || fail "flutter test" "$out"

echo "$state" > "$state_file"
