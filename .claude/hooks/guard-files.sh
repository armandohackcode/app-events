#!/usr/bin/env bash
# PreToolUse (Edit|Write|MultiEdit): block writes to secrets and local
# Firebase config. These files are git-ignored and must be edited by hand.
set -euo pipefail

file=$(jq -r '.tool_input.file_path // empty')
[[ -z "$file" ]] && exit 0

case "$file" in
  */lib/env.dart | */lib/firebase_options.dart | */google-services.json | \
    */GoogleService-Info.plist | */key.properties | *.jks | *.keystore)
    echo "Blocked: $file holds secrets or local Firebase config." \
      "Ask the user to edit it manually (see README, section Configuración)." >&2
    exit 2
    ;;
esac

root=${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}
case "${file#"$root"/}" in
  macos/* | windows/* | linux/*)
    echo "Blocked: $file is in an unsupported platform folder." \
      "This app only supports Android, iOS and Web." >&2
    exit 2
    ;;
esac
