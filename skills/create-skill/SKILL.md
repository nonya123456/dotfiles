---
name: create-skill
description: Create a new skill in the dotfiles repo's skills/ folder using skill-creator. Use when the user asks to create, add, or write a new skill for their dotfiles.
---

Create a new skill with skill-creator, saved in the dotfiles repo instead of skill-creator's default location.

1. Find the dotfiles repo: a git clone whose `.claude-plugin/marketplace.json` has `"name": "nonya-dotfiles"`. Check, in order:
   - the current repo (`git rev-parse --show-toplevel`)
   - a clone path you already know from memory or this conversation
   - ask the user

   The installed plugin copy under the Claude config directory is a cache, so write to the clone.
2. Invoke the `skill-creator` skill (it may be namespaced, e.g. `anthropic-skills:skill-creator`) with the user's request and `$ARGUMENTS`, targeting `<repo>/skills/<skill-name>/SKILL.md`. If skill-creator is unavailable, write the skill directly. Either way, match the format of the existing skills in `skills/`.
3. Keep the skill portable: paths are repo-relative or discovered at runtime, and credentials come from env vars or the user at runtime. CI (`.github/workflows/check.yml`) enforces this on push.
4. Report the new skill's path. Commit only when asked.
