---
name: format-glsl
description: Formats GLSL shader files (.glsl, .vert, .frag, .comp — e.g. Godot compute shaders with a #[compute] header) using clang-format and the project's .clang-format. Use this skill any time you finish creating or editing a GLSL file in a project that has a .clang-format — formatting after every shader edit is the project's standing convention, not an optional cleanup step.
---

## Task

Run `clang-format -i` on every GLSL file you just created or edited.

```bash
clang-format -i --fallback-style=none <path/to/shader.glsl> [<path/to/other.glsl> ...]
```

Pass all changed shader paths in one invocation when possible. clang-format picks up the nearest `.clang-format` above each file, so the project's style (tabs, no line limit, etc.) applies automatically. `--fallback-style=none` makes it skip files in projects with no `.clang-format`, instead of rewriting them in LLVM style the project never chose; if that happens and the user wants formatting, offer to add a config rather than picking a style yourself.

Run it immediately after editing; don't batch it up for later or skip it because the change looks small.

## Expected quirks

clang-format treats GLSL as C-like, so a few results look odd but are harmless:

- A named interface block's instance name moves to its own line (`}` then `pc;`). The shader still compiles.
- Godot's `#[compute]` header line is left untouched.

If formatting ever changes meaning (it shouldn't), check that the shader still compiles; in Godot, reimport and read `RDShaderFile.get_spirv().compile_error_compute`.
