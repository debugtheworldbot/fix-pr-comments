---
name: fix-pr-comments
description: Triage unresolved GitHub PR review comments via `gh`, apply fixes for valid feedback and resolve the thread, or post a reasoned rebuttal for invalid feedback without resolving. Use when the user says "fix-pr-comments", "/fix-pr-comments", "处理PR评论", "修复PR review", or asks to go through PR review comments and address them.
---

# Fix PR Comments

Triage unresolved review threads on a GitHub pull request. Fix what is valid, push them back with a resolve; push back on what is not, with a reasoned reply.

## Workflow

1. **Resolve target PR.** If the user gave a PR number or URL, use it. Otherwise `gh pr view --json number,headRefName,baseRefName,url` to get the PR for the current branch. If there is no PR, tell the user and stop.

2. **List unresolved threads.** Run `scripts/list_threads.sh [PR_NUMBER]` — it prints one JSON object per unresolved thread (`thread_id`, `first_comment_db_id`, `path`, `line`, `diff_hunk`, `author`, `body`, `url`, `comments`). If none, report "no unresolved threads" and stop. Save the JSON to a temp file so the ids can be referenced later without re-fetching.

3. **Sync local branch** with `git fetch origin && git status -sb` so fixes land on the latest code. If the PR branch is not checked out locally, check it out before continuing.

4. **Triage each thread.** For every thread:
   - **Read the real code** at `path:line` (and surrounding context) before judging. Do not trust the comment's assumption about what the code does — verify.
   - Decide valid vs. invalid using the rubric below.
   - Act (see "Act on a thread"), then move to the next.

5. **Batch-commit fixes** as you go. Prefer one commit per thread (or one per small cluster of clearly-related threads) so the review history is readable. Commit message format:
   ```
   <short summary of the fix>

   Addresses: <thread url>
   ```

6. **Push once at the end** with `git push` (never `--force` without asking). If the remote has diverged, `git pull --rebase` first.

7. **Report back** with a compact table: thread URL · verdict (fixed / rebutted) · commit sha or reply preview.

## Validity rubric

A comment is **valid** if any of these hold:
- Points at a real bug, crash path, data loss, or security issue
- Identifies a violation of a project convention that is evidenced in the repo
- Flags a concrete correctness or performance problem with a testable claim
- Improves clarity of code whose intent is genuinely ambiguous

A comment is **invalid** if any of these hold:
- Rests on a premise that the actual code disproves (check the file, not the diff hunk)
- Is a subjective style preference not backed by a lint rule or project convention
- Asks for work out of the PR's declared scope
- Duplicates a concern already addressed elsewhere in the diff
- Suggests a change that would break tests or existing behavior

When uncertain, default to **valid** and fix — but only after verifying against the code. If verification changes your mind, rebut.

## Act on a thread

### Valid → fix + resolve
1. Edit the file(s) to address the comment. Keep the change scoped to what the comment asked for; do not refactor around it.
2. If tests exist and are cheap to run for the touched area, run them.
3. `git add <files> && git commit` with the message format above.
4. `scripts/resolve_thread.sh <thread_id>` to resolve the thread. (Do this *after* the fix is committed, not before — so reviewers can see the linked change when they revisit.)

### Invalid → reply, do not resolve
1. Draft a short, respectful rebuttal that:
   - States the specific premise you disagree with
   - Cites the code (file:line) or behavior that supports your position
   - Offers a path forward if the reviewer still wants a change (e.g. "happy to add a test if you'd like to confirm")
2. Write the body to a temp file to preserve newlines, then:
   ```
   scripts/reply_thread.sh <PR_NUMBER> <first_comment_db_id> <body_file>
   ```
3. **Do not** call `resolve_thread.sh` — leave the thread open for the reviewer.

## Scripts

- `scripts/list_threads.sh [PR]` — unresolved review threads as JSON lines. Auto-detects PR from current branch if omitted.
- `scripts/resolve_thread.sh <thread_id>` — resolve one thread via GraphQL.
- `scripts/reply_thread.sh <PR> <first_comment_db_id> <body>` — post a reply. `body` is a file path, a literal string, or `-` for stdin.

Thread IDs (`PRRT_...`) are GraphQL node ids and go to `resolve_thread.sh`. Reply needs the REST `databaseId` (integer) of the thread's first comment — both come from `list_threads.sh` output as `thread_id` and `first_comment_db_id`.

## Scope notes

- This skill handles **review threads** (line-anchored comments). General PR issue comments (`gh pr view --comments`) are out of scope — mention them to the user if present but do not auto-reply.
- Never resolve a thread without either committing a fix or getting explicit user approval.
- If the PR has 10+ unresolved threads, surface the count first and ask the user whether to process all or filter (by author, by path, by severity).
