---
name: review
description: Review changed code in the working tree (git diff). Reads modified files, identifies issues, and fixes them.
allowed-tools: Bash(git *), Read, Edit, Glob, Grep
---

Review all changed code in the working tree:

1. Run `git diff` (staged + unstaged) and `git status` in parallel to see what changed
2. Read the full content of any modified or new files
3. Identify issues:
   - Dead code / unused imports
   - Bugs or logic errors
   - Unnecessary complexity
   - Style inconsistencies with surrounding code
4. Fix any issues found using Edit
5. Build the project to confirm it still compiles (check CLAUDE.md for the build command)
6. Report what was changed and why

If `$ARGUMENTS` is provided, treat it as additional focus or constraints for the review.

Rules:
- Do not refactor beyond what is clearly necessary
- Do not add comments, docstrings, or type annotations to unchanged code
- Do not introduce new abstractions unless an existing one is obviously being duplicated
- Fix real issues; do not make cosmetic changes for their own sake
