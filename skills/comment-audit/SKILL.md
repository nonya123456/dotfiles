---
name: comment-audit
description: Audit code comments across the whole project — remove redundant or noisy ones, fix stale or wrong ones. Like comment-check but not limited to the diff. Use when the user asks to audit or clean up comments project-wide.
allowed-tools: Bash(git *), Read, Edit, Glob, Grep
---

Audit comments in every source file in the project:

1. Run `git ls-files` to list tracked files; skip generated, vendored, lock, minified, and binary files
2. Read each remaining source file in full
3. For every comment, check for:
   - Redundant: restates what the code plainly does (`// increment i`, `// return result`)
   - Stale or wrong: no longer matches the code it describes (renamed vars, changed behavior, outdated params)
   - Noise: change-log notes (`// added X`, `// fixed bug`, `// new:`), commented-out code, leftover TODOs that are already done
   - Unclear: a non-obvious "why" that is missing or too vague to help
4. Fix issues using Edit: delete redundant/noise comments, correct stale ones, tighten unclear ones
5. Report what was changed and why, grouped by file

If `$ARGUMENTS` is provided, treat it as a file/path to limit the audit to, or additional focus.

Rules:
- Keep comments that explain why, intent, invariants, workarounds, or non-obvious constraints
- Keep doc comments on public APIs; only fix them if wrong
- Keep license headers, shebangs, and tool directives (`eslint-disable`, `nolint`, `# type: ignore`, modelines, etc.)
- Do not add comments to code that is clear without them
- Do not touch code, only comments
- Match the surrounding comment style (syntax, casing, punctuation)
