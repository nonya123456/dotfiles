---
name: clean-nvim-swap
description: Delete stale Neovim swap files. Use when nvim warns about an existing swap file.
allowed-tools: Bash(find *), Bash(rm *)
---

Delete stale Neovim swap files.

If `$ARGUMENTS` is provided, treat it as the filename to target (e.g. `main.c`).
Otherwise, list all swap files and delete them (or ask the user which to delete if there are many).

Steps:
1. Find swap files: `find ~/.local/state/nvim/swap/ -name "*.swp"`
2. If `$ARGUMENTS` is provided, filter to files matching that name
3. Show the files that will be deleted
4. Delete them with `rm`
