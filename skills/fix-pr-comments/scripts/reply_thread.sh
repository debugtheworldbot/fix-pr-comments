#!/usr/bin/env bash
# Post a reply to a PR review comment thread.
# Usage: reply_thread.sh <PR_NUMBER> <IN_REPLY_TO_DB_ID> <BODY_FILE|-BODY_STRING>
#   PR_NUMBER: pull request number
#   IN_REPLY_TO_DB_ID: the first_comment_db_id from list_threads.sh (integer)
#   BODY: either a file path (body content) or a literal string. If "-", read from stdin.
set -euo pipefail

PR="${1:?pr number required}"
IN_REPLY_TO="${2:?in_reply_to comment db id required}"
BODY_SRC="${3:?body file path, '-' for stdin, or literal string required}"

if [ "$BODY_SRC" = "-" ]; then
  BODY=$(cat)
elif [ -f "$BODY_SRC" ]; then
  BODY=$(cat "$BODY_SRC")
else
  BODY="$BODY_SRC"
fi

REPO_JSON=$(gh repo view --json owner,name)
OWNER=$(printf '%s' "$REPO_JSON" | jq -r .owner.login)
NAME=$(printf '%s' "$REPO_JSON" | jq -r .name)

gh api -X POST \
  "repos/$OWNER/$NAME/pulls/$PR/comments/$IN_REPLY_TO/replies" \
  -f body="$BODY" \
  --jq '"posted reply id=\(.id) url=\(.html_url)"'
