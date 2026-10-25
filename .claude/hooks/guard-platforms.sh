#!/usr/bin/env bash
# PreToolUse (Bash): the app targets Android, iOS and Web only. Block commands
# that create, enable or build desktop platforms (macOS, Windows, Linux).
set -euo pipefail

cmd=$(jq -r '.tool_input.command // empty')

if perl -e '
  my $c = $ARGV[0];
  exit(($c =~ /\bflutter\s+create\b.*--platforms[=\s]+\S*\b(macos|windows|linux)\b/
     || $c =~ /\bflutter\s+config\b.*--enable-(macos|windows|linux)-desktop\b/
     || $c =~ /\bflutter\s+build\s+(macos|windows|linux)\b/
     || $c =~ /\bflutter\s+run\b.*(-d|--device-id)[=\s]+(macos|windows|linux)\b/) ? 0 : 1)
' "$cmd"; then
  echo "Blocked: this app only supports Android, iOS and Web." \
    "Do not create, enable or build macOS, Windows or Linux platforms." >&2
  exit 2
fi
