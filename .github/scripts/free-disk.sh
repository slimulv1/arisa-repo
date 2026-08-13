#!/usr/bin/env bash
# Shared "free disk space" pre-build check for containerized build jobs.
#
# Run it before the heavy build step (and before any cache restore that
# needs room):
#
#   run: bash "$GITHUB_WORKSPACE/.github/scripts/free-disk.sh"
#
# Fails fast on critically low disk so a build fails cleanly up front
# instead of mid-build with a cryptic ENOSPC.
set -euo pipefail

echo "Disk before cleanup:"
df -h / | tail -1

rm -rf /tmp/* /var/tmp/* 2>/dev/null || true

echo "Disk after cleanup:"
df -h / | tail -1

avail_kb=$(df -k --output=avail / | tail -1 | tr -d ' ')
if (( avail_kb < 5242880 )); then
  echo "::error::Less than 5GB available on /. Aborting build."
  exit 1
fi
echo "OK: $(numfmt --to=iec "$((avail_kb * 1024))") available."
