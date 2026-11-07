---
name: create-skill
description: Create a new skill in the dotfiles repo's skills/ folder using skill-creator. Use when the user asks to create, add, or write a new skill for their dotfiles.
---

Create a new skill with skill-creator, but save it in the dotfiles repo instead of skill-creator's default location.

1. Find the dotfiles repo:
   - If the current directory is inside a git repo whose `.claude-plugin/marketplace.json` has `"name": "nonya-dotfiles"`, use that repo's root (`git rev-parse --show-toplevel`).
   - Otherwise, if you already know the clone's path (from memory or earlier in the conversation) and it passes the same check, use it.
   - Otherwise ask the user where their dotfiles clone is. Never hardcode a path, and never write into the installed plugin copy under the Claude config directory.
2. Invoke the `skill-creator` skill (it may be namespaced, e.g. `anthropic-skills:skill-creator`) with the user's request and `$ARGUMENTS`. Tell it the target is `<repo>/skills/<skill-name>/SKILL.md`. If skill-creator is not available, write the skill directly, following the format of the existing skills in `skills/`.
3. Follow the conventions of the existing skills in `skills/`:
   - Folder name matches the `name` in the frontmatter (kebab-case)
   - Frontmatter has `name`, `description` (what it does + when to use it), and `allowed-tools` only if needed
   - Short, imperative steps
4. Keep the skill portable — it must work on any machine:
   - No absolute or user-specific paths (`/Users/...`, `/home/...`, `~/dotfiles`), usernames, hostnames, or machine-specific tool locations
   - Refer to files relative to the repo or the current project; discover anything else at runtime
   - Before finishing, grep the new skill folder for `/Users/`, `/home/`, `~/`, and the current `$USER`, and fix any hits
5. Skills in `skills/` are picked up by the existing plugin entry in `.claude-plugin/marketplace.json`; do not edit it.
6. Report the new skill's path. Do not commit unless asked.
