---
name: format-gdscript
description: Formats GDScript (.gd) files using gdscript-formatter --reorder-code, per this project's style convention (tabs, 2 blank lines between functions, 1 blank line at EOF, no trailing whitespace). Use this skill any time you finish creating or editing a .gd file in this project — formatting after every GDScript edit is the project's standing convention, not an optional cleanup step.
---

## Task

Run `gdscript-formatter --reorder-code` on every `.gd` file you just created or edited.

```bash
gdscript-formatter --reorder-code <path/to/file.gd> [<path/to/other.gd> ...]
```

Pass all changed `.gd` paths in one invocation when possible. This is a fast, deterministic cleanup step — run it immediately after editing, don't batch it up for later or skip it because the change looks small.
