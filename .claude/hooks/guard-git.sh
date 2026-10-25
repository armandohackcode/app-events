#!/usr/bin/env bash
# PreToolUse (Bash): the team commits and pushes by hand. Claude leaves the
# changes in the working tree and reports what is ready.
set -euo pipefail

cmd=$(jq -r '.tool_input.command // empty')

if perl -e 'exit(($ARGV[0] =~ /(^|[\s;&|(])git(\s+-C\s+\S+)?\s+(commit|push)\b/) ? 0 : 1)' "$cmd"; then
  echo "Blocked: commits and pushes are made by the developer, not by Claude." \
    "Leave the changes uncommitted and summarize what is ready." >&2
  exit 2
fi
