---
name: comment-check
description: Check code comments in the working tree diff — remove redundant or noisy ones, fix stale or wrong ones. Use when the user asks to check, clean up, or review comments.
allowed-tools: Bash(git *), Read, Edit, Glob, Grep
---

Check comments in all changed code in the working tree:

1. Run `git diff` (staged + unstaged) and `git status` in parallel to see what changed
2. Read the full content of any modified or new files
3. For every comment added or touched by the diff, and every existing comment next to changed code, check for:
   - Redundant: restates what the code plainly does (`// increment i`, `// return result`)
   - Stale or wrong: no longer matches the code it describes (renamed vars, changed behavior, outdated params)
   - Noise: change-log notes (`// added X`, `// fixed bug`, `// new:`), commented-out code, leftover TODOs that are already done
   - Unclear: a non-obvious "why" that is missing or too vague to help
4. Fix issues using Edit: delete redundant/noise comments, correct stale ones, tighten unclear ones
5. Report what was changed and why

If `$ARGUMENTS` is provided, treat it as a file/path to limit the check to, or additional focus.

Rules:
- Keep comments that explain why, intent, invariants, workarounds, or non-obvious constraints
- Keep doc comments on public APIs; only fix them if wrong
- Do not add comments to code that is clear without them
- Do not touch code, only comments
- Match the surrounding comment style (syntax, casing, punctuation)
