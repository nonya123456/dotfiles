---
name: commit-push
description: Stage, commit, and push git changes. Use when the user asks to commit and push changes.
allowed-tools: Bash(git *)
---

Create a git commit and push it following these steps:

1. Run `git status` and `git diff` (staged + unstaged) in parallel to review all changes
2. Run `git log --oneline -5` to match the repo's commit message style
3. Use `git add .` to stage all changes
4. Write a concise commit message within one line — no body, no footer, no trailers (no Co-Authored-By or similar)
5. Run `git push`
6. Run `git status` to confirm the commit and push succeeded

If `$ARGUMENTS` is provided, use it as the commit message or additional instructions.

Rules:

- Never use `--no-verify`, `--no-gpg-sign`, or `--force`
- Never amend unless explicitly asked
- Do not commit files that likely contain secrets (.env, credentials, etc.)
- If the branch has no upstream, push with `git push -u origin HEAD`
