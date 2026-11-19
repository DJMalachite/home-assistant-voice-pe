#!/usr/bin/env bash
# Three-way merge upstream changes to home-assistant-voice.yaml into the BT Edition.
#
#   base     = upstream home-assistant-voice.yaml at the commit BT was last synced to
#   ours     = home-assistant-voice-BT-Edition.yaml (your customisations)
#   theirs   = upstream home-assistant-voice.yaml at the latest upstream commit
#
# Only upstream's *own* copy of the file is used for base/theirs, so edits you made
# to this fork's home-assistant-voice.yaml never leak into (or out of) the merge.
#
# Writes to $GITHUB_OUTPUT (if set): status, old, new, conflicts
#   status = up-to-date | no-change | clean | conflict
set -euo pipefail

UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/esphome/home-assistant-voice-pe.git}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-dev}"
SRC="home-assistant-voice.yaml"
BT="home-assistant-voice-BT-Edition.yaml"
BASE_FILE=".github/bt-edition-base"

out() { [ -n "${GITHUB_OUTPUT:-}" ] && echo "$1=$2" >> "$GITHUB_OUTPUT"; echo "$1=$2"; }

[ -f "$BT" ] || { echo "::error::$BT not found"; exit 1; }
[ -f "$BASE_FILE" ] || { echo "::error::$BASE_FILE not found"; exit 1; }

git fetch --quiet --no-tags "$UPSTREAM_URL" "+refs/heads/$UPSTREAM_BRANCH:refs/remotes/upstream/$UPSTREAM_BRANCH"
NEW="$(git rev-parse "refs/remotes/upstream/$UPSTREAM_BRANCH")"
OLD="$(tr -d '[:space:]' < "$BASE_FILE")"

git cat-file -e "${OLD}^{commit}" 2>/dev/null \
  || { echo "::error::Base commit $OLD (from $BASE_FILE) not found in upstream history"; exit 1; }
git merge-base --is-ancestor "$OLD" "$NEW" \
  || { echo "::error::$OLD is not an ancestor of upstream $UPSTREAM_BRANCH ($NEW) - upstream history was rewritten?"; exit 1; }

out old "$OLD"
out new "$NEW"

if [ "$OLD" = "$NEW" ]; then
  out status up-to-date
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git show "$OLD:$SRC" > "$TMP/base.yaml"
git show "$NEW:$SRC" > "$TMP/upstream.yaml"

if cmp -s "$TMP/base.yaml" "$TMP/upstream.yaml"; then
  # Upstream moved but didn't touch the file - nothing to merge, keep the old base.
  out status no-change
  exit 0
fi

set +e
git merge-file \
  -L "BT Edition" -L "upstream ${OLD:0:7}" -L "upstream ${NEW:0:7}" \
  "$BT" "$TMP/base.yaml" "$TMP/upstream.yaml"
RC=$?
set -e

# git merge-file: <0 (255 in shell) = error, otherwise number of conflicts (capped at 127)
if [ "$RC" -gt 127 ]; then
  echo "::error::git merge-file failed (exit $RC)"
  exit 1
fi

echo "$NEW" > "$BASE_FILE"
out conflicts "$RC"
if [ "$RC" -eq 0 ]; then
  out status clean
else
  out status conflict
  echo "::warning::$RC conflict(s) in $BT - resolve the <<<<<<< / >>>>>>> markers in the PR"
fi
