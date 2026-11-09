---
name: comment-audit
description: Audit code comments across the whole project — remove redundant or noisy ones, fix stale or wrong ones. Like comment-check but not limited to the diff. Use when the user asks to audit or clean up comments project-wide.
allowed-tools: Bash(git *), Read, Edit, Glob, Grep
---

Audit comments in every source file in the project:

1. Run `git ls-files` to list tracked files; skip generated, vendored, lock, minified, and binary files
2. Read each remaining source file in full
3. For every comment, use your own judgment: would a competent reader of this code lose anything if the comment were gone? Also check that it is still accurate and clear enough to help
4. Fix issues using Edit: delete comments that add nothing, correct wrong ones, tighten unclear ones
5. Report what was changed and why, grouped by file

If `$ARGUMENTS` is provided, treat it as a file/path to limit the audit to, or additional focus.

Rules:
- Default to deleting. A comment stays only if it tells the reader something the code cannot
- When unsure whether a comment adds anything, delete it
- Doc comments on public APIs: keep only the parts that add information beyond the signature
- Keep license headers, shebangs, and comments that tools read as directives
- Do not add comments to code that is clear without them
- Do not touch code, only comments
- Match the surrounding comment style
