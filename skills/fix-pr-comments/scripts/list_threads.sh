#!/usr/bin/env bash
# List unresolved review threads on a PR as JSON lines.
# Usage: list_threads.sh [PR_NUMBER]
#   - If PR_NUMBER is omitted, uses the PR for the current branch.
# Output: one JSON object per unresolved thread with:
#   thread_id, is_resolved, is_outdated, path, line, diff_hunk,
#   first_comment_id, first_comment_db_id, author, body, url, comments (array of {author, body, url})
set -euo pipefail

PR="${1:-}"
if [ -z "$PR" ]; then
  PR=$(gh pr view --json number --jq .number)
fi

REPO_JSON=$(gh repo view --json owner,name)
OWNER=$(printf '%s' "$REPO_JSON" | jq -r .owner.login)
NAME=$(printf '%s' "$REPO_JSON" | jq -r .name)

QUERY='query($owner:String!,$name:String!,$pr:Int!,$cursor:String){
  repository(owner:$owner,name:$name){
    pullRequest(number:$pr){
      reviewThreads(first:50, after:$cursor){
        pageInfo{hasNextPage endCursor}
        nodes{
          id
          isResolved
          isOutdated
          path
          line
          originalLine
          comments(first:50){
            nodes{
              id
              databaseId
              body
              url
              diffHunk
              author{login}
            }
          }
        }
      }
    }
  }
}'

CURSOR=null
while :; do
  RESP=$(gh api graphql -f query="$QUERY" -F owner="$OWNER" -F name="$NAME" -F pr="$PR" -f cursor="$CURSOR")
  printf '%s' "$RESP" | jq -c '
    .data.repository.pullRequest.reviewThreads.nodes[]
    | select(.isResolved == false)
    | {
        thread_id: .id,
        is_resolved: .isResolved,
        is_outdated: .isOutdated,
        path: .path,
        line: (.line // .originalLine),
        diff_hunk: (.comments.nodes[0].diffHunk // ""),
        first_comment_id: .comments.nodes[0].id,
        first_comment_db_id: .comments.nodes[0].databaseId,
        author: .comments.nodes[0].author.login,
        body: .comments.nodes[0].body,
        url: .comments.nodes[0].url,
        comments: [.comments.nodes[] | {author: .author.login, body: .body, url: .url}]
      }
  '
  HAS_NEXT=$(printf '%s' "$RESP" | jq -r .data.repository.pullRequest.reviewThreads.pageInfo.hasNextPage)
  if [ "$HAS_NEXT" != "true" ]; then break; fi
  CURSOR=$(printf '%s' "$RESP" | jq -r .data.repository.pullRequest.reviewThreads.pageInfo.endCursor)
done
