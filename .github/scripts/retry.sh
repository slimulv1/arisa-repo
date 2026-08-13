#!/usr/bin/env bash
# Shared exponential-backoff retry for GitHub CLI commands.
#
# This file only DEFINES the retry() function — source it from any step
# that needs it (do not execute directly):
#
#   source "$GITHUB_WORKSPACE/.github/scripts/retry.sh"
#   retry 3 gh release upload "$TAG" "$pkg" --repo "$REPO" --clobber
#
# Usage: retry <attempts> <command...>
# Starts at 10s delay and doubles after each failed attempt.
retry() {
  local attempts=$1; shift
  local delay=10
  local i
  for ((i = 1; i <= attempts; i++)); do
    if "$@"; then
      return 0
    fi
    echo "Attempt $i/$attempts failed, retrying in ${delay}s..."
    sleep "$delay"
    delay=$((delay * 2))
  done
  echo "Command failed after $attempts attempts: $*" >&2
  return 1
}
