#!/usr/bin/env bash
#
# auto-merge-pr.sh — arm GitHub auto-merge on a bot-created pull request,
# waiting for mergeability, resolving conflicts when possible, and verifying
# that auto-merge was actually enabled.
#
# Why this exists: `gh pr merge --auto` right after PR creation frequently
# fails or silently never merges because (1) GitHub has not yet computed
# mergeability (state UNKNOWN), (2) the PR branch is behind/conflicted, or
# (3) the merge is armed but the repo has auto-merge disabled so the arm
# silently does nothing. This script handles all three and reports loudly
# instead of leaving a PR parked forever.
#
# Usage:
#   auto-merge-pr.sh <pr-number> --repo <owner/repo> \
#       [--timeout <seconds>] [--no-update-branch] [--no-comment]
#
# Requirements:
#   - gh CLI with GH_TOKEN (pull-requests: write; contents: write when
#     branch updates are allowed)
#   - Repo setting "Allow auto-merge" must be ON, otherwise arming fails
#     and this script reports exactly that instead of warning vaguely.
#
# Exit codes:
#   0  auto-merge armed (or PR already merged) — nothing else to do
#   1  terminal failure (unresolvable conflict, failed arm, timeout)

set -euo pipefail

PR_NUMBER=""
REPO=""
TIMEOUT=600
ALLOW_UPDATE_BRANCH=1
COMMENT_ON_FAILURE=1

usage() {
  cat >&2 <<EOF
usage: $0 <pr-number> --repo <owner/repo> [--timeout <seconds>] [--no-update-branch] [--no-comment]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)              REPO="${2:?--repo requires a value}"; shift 2 ;;
    --timeout)           TIMEOUT="${2:?--timeout requires a value}"; shift 2 ;;
    --no-update-branch)  ALLOW_UPDATE_BRANCH=0; shift ;;
    --no-comment)        COMMENT_ON_FAILURE=0; shift ;;
    -h|--help)           usage; exit 0 ;;
    *)
      if [[ -z "$PR_NUMBER" ]]; then
        PR_NUMBER="$1"
      else
        usage; exit 2
      fi
      shift ;;
  esac
done

if [[ -z "$PR_NUMBER" || -z "$REPO" ]]; then
  usage
  exit 2
fi
command -v gh >/dev/null 2>&1 || { echo "::error::gh CLI not found" >&2; exit 1; }

log()  { echo "[auto-merge] $*"; }
warn() { echo "::warning::[auto-merge] $*"; }
err()  { echo "::error::[auto-merge] $*"; }

pr_json() { gh pr view "$PR_NUMBER" --repo "$REPO" --json "$1" -q "$2"; }
comment() { gh pr comment "$PR_NUMBER" --repo "$REPO" --body "$1" >/dev/null 2>&1 || true; }
fail() {
  err "$1"
  if [[ "$COMMENT_ON_FAILURE" == 1 ]]; then
    comment "⚠️ $1"
  fi
  exit 1
}

# --- Already merged? Nothing to do. ------------------------------------------
if [[ -n "$(pr_json 'mergedAt' '.mergedAt // ""' 2>/dev/null || true)" ]]; then
  log "PR #$PR_NUMBER is already merged — nothing to do."
  exit 0
fi

# --- Wait until GitHub has computed mergeability. ----------------------------
# Right after creation/update the state is UNKNOWN; arming too early fails
# transiently, so poll until a definitive state appears.
deadline=$(( $(date +%s) + TIMEOUT ))
state="UNKNOWN"
while (( $(date +%s) < deadline )); do
  state="$(pr_json 'state,mergeStateStatus' '.mergeStateStatus // "UNKNOWN"')"
  case "$state" in
    UNKNOWN|DRAFT) sleep 5 ;;
    *) break ;;
  esac
done
log "mergeability state: $state"

case "$state" in
  UNKNOWN)
    fail "Auto-merge blocked: mergeability not resolved within ${TIMEOUT}s (state=UNKNOWN). Please review PR #$PR_NUMBER manually."
    ;;
  DRAFT)
    fail "Auto-merge blocked: PR #$PR_NUMBER is a draft. Mark it ready for review to auto-merge."
    ;;
  DIRTY)
    # Conflicts: try to bring the PR branch up to date with its base first.
    # Only safe for same-repo bot branches (aur-sync, dependabot branches are
    # same-repo too); callers may disable via --no-update-branch.
    if [[ "$ALLOW_UPDATE_BRANCH" == 1 ]]; then
      warn "PR #$PR_NUMBER has merge conflicts — updating branch from base..."
      if gh pr update-branch "$PR_NUMBER" --repo "$REPO" >/tmp/am-update.log 2>&1; then
        log "branch updated. Re-checking mergeability..."
        for _ in $(seq 1 12); do
          state="$(pr_json 'mergeStateStatus' '.mergeStateStatus // "UNKNOWN"')"
          case "$state" in
            UNKNOWN|DIRTY) sleep 5 ;;
            *) break ;;
          esac
        done
      else
        warn "branch update failed: $(tr '\n' ' ' < /tmp/am-update.log)"
      fi
    fi
    if [[ "$state" == "DIRTY" ]]; then
      fail "Auto-merge blocked: PR #$PR_NUMBER still has merge conflicts after update. Please resolve them manually."
    fi
    ;;
esac

# --- Arm auto-merge (retry transient failures). -------------------------------
log "PR #$PR_NUMBER is $state — arming auto-merge (squash)..."
ARMED=0
for attempt in 1 2 3; do
  if gh pr merge "$PR_NUMBER" --repo "$REPO" --auto --squash; then
    ARMED=1
    break
  fi
  warn "gh pr merge --auto attempt $attempt/3 failed — retrying in 10s"
  sleep 10
done

if [[ "$ARMED" != 1 ]]; then
  fail "Auto-merge could not be enabled for PR #$PR_NUMBER (repo setting 'Allow auto-merge' must be ON and GH_TOKEN needs pull-requests:write). Please merge manually."
fi

# --- Verify it really is armed. ------------------------------------------------
sleep 3
am="$(pr_json 'autoMergeRequest' '.autoMergeRequest.mergeMethod // "unknown"' 2>/dev/null || echo unknown)"
if [[ "$am" == "unknown" ]]; then
  warn "could not confirm an auto-merge request for PR #$PR_NUMBER — it may still merge shortly."
else
  log "confirmed: auto-merge armed ($am) for PR #$PR_NUMBER"
fi

exit 0
