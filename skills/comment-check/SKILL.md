---
name: comment-check
description: Check code comments in the working tree diff — remove redundant or noisy ones, fix stale or wrong ones. Use when the user asks to check, clean up, or review comments.
allowed-tools: Bash(git *), Read, Edit, Glob, Grep
---

Check comments in all changed code in the working tree:

1. Run `git diff` (staged + unstaged) and `git status` in parallel to see what changed
2. Read the full content of any modified or new files
3. For every comment added or touched by the diff, and every existing comment next to changed code, use your own judgment: would a competent reader of this code lose anything if the comment were gone? Also check that it is still accurate and clear enough to help
4. Fix issues using Edit: delete comments that add nothing, correct wrong ones, tighten unclear ones
5. Report what was changed and why

If `$ARGUMENTS` is provided, treat it as a file/path to limit the check to, or additional focus.

Rules:
- Default to deleting. A comment stays only if it tells the reader something the code cannot
- When unsure whether a comment adds anything, delete it
- Doc comments on public APIs: keep only the parts that add information beyond the signature
- Do not add comments to code that is clear without them
- Do not touch code, only comments
- Match the surrounding comment style
