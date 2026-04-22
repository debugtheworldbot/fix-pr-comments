#!/usr/bin/env bash
# Resolve a PR review thread via GraphQL.
# Usage: resolve_thread.sh <THREAD_ID>
#   THREAD_ID is the node id (e.g. PRRT_xxx) from list_threads.sh.
set -euo pipefail

THREAD_ID="${1:?thread id required}"

gh api graphql \
  -f query='mutation($id:ID!){resolveReviewThread(input:{threadId:$id}){thread{id isResolved}}}' \
  -f id="$THREAD_ID" \
  --jq '.data.resolveReviewThread.thread | "\(.id) resolved=\(.isResolved)"'
