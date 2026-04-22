# fix-pr-comments

A Claude Code skill that triages unresolved GitHub PR review threads: fixes valid feedback and resolves the thread, or posts a reasoned rebuttal for invalid feedback and leaves it open.

Works against any GitHub repo via `gh` + GraphQL — no custom server, no stored credentials beyond what `gh` already manages.

## What it does

Given a PR (or inferred from the current branch), the skill will:

1. List all **unresolved** review threads.
2. For each thread, read the real code at `path:line` and judge validity against a rubric (real bug / convention violation / testable correctness issue = valid; style preference / wrong premise / out-of-scope = invalid).
3. **Valid** → edit the file, commit with a message linking the thread, then resolve the thread via GraphQL.
4. **Invalid** → reply with a short, specific rebuttal citing the code; leave the thread open for the reviewer.
5. Push once at the end and report a compact table of outcomes.

## Requirements

- [`gh`](https://cli.github.com/) CLI, authenticated (`gh auth login`) with `repo` scope
- `jq`
- `git` with write access to the PR branch
- Claude Code (the skill is loaded from `~/.claude/skills/` or as a plugin)

## Install

### Option A — As a standalone skill

```bash
git clone --depth 1 https://github.com/debugtheworldbot/fix-pr-comments /tmp/fpc
cp -r /tmp/fpc/skills/fix-pr-comments ~/.claude/skills/
chmod +x ~/.claude/skills/fix-pr-comments/scripts/*.sh
rm -rf /tmp/fpc
```

Or, if you prefer a single clone you can update with `git pull`:

```bash
mkdir -p ~/.claude/skills && cd ~/.claude/skills
git clone https://github.com/debugtheworldbot/fix-pr-comments _fix-pr-comments-src
ln -s _fix-pr-comments-src/skills/fix-pr-comments fix-pr-comments
```

### Option B — As a Claude Code plugin

```
/plugin marketplace add debugtheworldbot/fix-pr-comments
/plugin install fix-pr-comments
```

## Usage

In Claude Code, trigger the skill with any of:

- `/fix-pr-comments` (if mounted as a slash command in your setup)
- "fix-pr-comments"
- "处理 PR 评论" / "修复 PR review"
- "go through the review comments on PR #123"

The skill auto-detects the PR from the current branch, or you can pass a PR number / URL.

## Scripts

All three can also be used standalone from any repo:

| Script | Purpose |
|---|---|
| `scripts/list_threads.sh [PR]` | List unresolved review threads as JSON lines |
| `scripts/resolve_thread.sh <thread_id>` | Resolve one thread (GraphQL node id, `PRRT_...`) |
| `scripts/reply_thread.sh <PR> <first_comment_db_id> <body>` | Reply to a thread |

`body` can be a file path, a literal string, or `-` for stdin.

## License

MIT
