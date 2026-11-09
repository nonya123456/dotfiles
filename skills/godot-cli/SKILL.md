---
name: godot-cli
description: Drive Godot 4 from the shell for game development — run projects and read their output, playtest a running game (press inputs, read live node state, take screenshots), check animation frame by frame, inspect classes, scenes and rigs, and create or edit .tscn scenes headless so the files stay byte-for-byte what the editor writes. Use whenever working in a Godot project (a folder with project.godot, .tscn/.gd files) and you need to run or playtest the game, check that a mechanic works, check errors, look up a node's properties, or change a scene, even if the user doesn't mention the CLI.
---

# Godot from the CLI

Everything here is `godot` invoked from Bash. No MCP server is needed.

## Find the binary

Run `command -v godot` first. A shell alias is invisible to non-interactive shells, so if that finds nothing, try the platform install location (macOS: `/Applications/Godot.app/Contents/MacOS/Godot`) or ask the user. It must be an **editor build**, because `--script` does not exist in export templates. Put the path in a variable and reuse it.

## Coarse actions

| Goal | Command |
| --- | --- |
| Version | `godot --version` |
| Open editor | `godot -e --path <project>` (run in background) |
| Run the game | `godot --path <project> [res://scene.tscn]`, adding `--headless` when no window is needed |
| Import / rebuild caches | `godot --headless --path <project> --import` |
| Export | `godot --headless --path <project> --export-release "<preset>" <out>` |

Run long-lived processes (the game, the editor) with Bash `run_in_background`, then read their output and kill them when done. macOS has no `timeout` command, so don't rely on it.

## Structured work: a GDScript run headless

For anything that inspects or changes project state, write a script to a temp file and run `godot --headless [--path <project>] --script <file.gd>`. Pass `--path` so `res://` and `ProjectSettings` resolve.

- `extends SceneTree`, do the work in `_init()`, and always `quit()` (`quit(1)` on failure). Without `quit()` the process never exits.
- **The startup banner shares stdout with your `print()`.** Print the result as one marked line, `print("<<<OUT>>>" + JSON.stringify(data))`, then grep that line out instead of parsing all of stdout.
- To pass input, use an env var (`IN='{"k":1}' godot ... --script x.gd`, read with `OS.get_environment("IN")`) or args after `++` (`OS.get_cmdline_user_args()`).
- **Read optional input fields null-safely.** Assigning a JSON `null` to a typed `String` is a runtime error, and on macOS that error path can hang headless Godot forever. Use `var v = d.get("k"); var s: String = v if v is String else ""`. If a run hangs, bisect the script before suspecting the OS.
- Format any `.gd` you write with `gdscript-formatter <file>` if it is installed.

Look up a class's properties (no project needed) before setting them:

```gdscript
extends SceneTree
func _init() -> void:
	var cls := "Sprite2D"
	var props := []
	for p in ClassDB.class_get_property_list(cls, false):
		if p.usage & (PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR) and not p.usage & PROPERTY_USAGE_CATEGORY:
			props.append({"name": p.name, "type": p.class_name if p.class_name != &"" else type_string(p.type)})
	print("<<<OUT>>>" + JSON.stringify({"inherits": ClassDB.get_parent_class(cls), "properties": props}))
	quit()
```

Read a rig with [`read_skeleton.gd`](read_skeleton.gd) before animating or attaching to it: `SCENE=res://player.glb godot --headless --path <project> --script <skill dir>/read_skeleton.gd | grep '<<<OUT>>>'`. It prints one line per bone (index, name, parent, rest position) and stars the deform bones, found from skin weights rather than naming, so it holds for any rig. Add `DEFORM_ONLY=1` on a large rig; a Rigify export carries ~200 helper bones around ~35 deform ones.

## Writing files: let Godot serialize

Any `.tscn`, `.tres` or `project.godot` you write should match what the editor would produce, so that opening and re-saving in the editor gives an empty diff. Don't hand-write the text formats, since their ordering and id/uid rules are easy to get subtly wrong. Use `PackedScene.pack()` + `ResourceSaver.save()` for scenes and resources, and `ConfigFile` for `project.godot`.

Headless runs have no `EditorFileSystem`, which causes the gotchas below:

1. **UIDs are dropped.** A headless save omits the `uid="uid://…"` in the `[gd_scene …]` header *and* on every `[ext_resource]`. When editing, re-inject them after the save from the sources in gotcha 2, which also covers resources the edit newly references; a new script has no `.uid` sidecar until `godot --headless --path <project> --import` runs. For a **new** scene, mint one with `ResourceUID.id_to_text(ResourceUID.create_id())` and append it as the last attribute of the header line.
2. **`ResourceLoader.get_resource_uid()` returns -1 headless.** It reads only the editor cache. Get a uid from the file itself instead: the `.tscn`/`.tres` header, a `<file>.uid` sidecar (scripts), or `[remap] uid` in `<file>.import` (imported assets).
3. **Autoloads don't exist.** A script that references an autoload (`Events.foo`) fails to compile under `--script`. `instantiate()` then yields a node with no script, and re-saving **silently strips the script and its exported NodePaths**. `Engine.register_singleton()` doesn't help. Before editing a scene, check every `.gd` it loads, recursively through sub-scenes, with `(load(p) as GDScript).can_instantiate()`. If any fail, don't re-save headless; hand-edit the `.tscn` instead.
4. **Set `owner` on every added node** (`n.owner = root`, including descendants), or `pack()` silently drops it.
5. **Nodes inside an instanced scene** (a child added under `Player/rig/Skeleton3D`, where `Player` is an instanced `.glb` or `.tscn`):
   - Call `root.set_editable_instance(inst, true)` first, or `pack()` silently drops the node even with `owner` set. This writes `[editable path="Player"]`, as the editor's "Editable Children" does.
   - Load the scene with `instantiate(PackedScene.GEN_EDIT_STATE_MAIN)`. A plain `instantiate()` re-saves an editable instance fully inlined: every bone and mesh of the model, thousands of lines.
   - The added node is saved with every property written out at its default value. Harmless; delete those lines by hand for a clean diff.

## Editing a scene

Use [`edit_scene.gd`](edit_scene.gd), which sits next to this file. It handles gotchas 1, 3, 4 and the load mode of 5: it refuses when a script doesn't compile, re-injects both kinds of uid, and rolls back if the save lost nodes, scripts, NodePaths, uids or editable flags. Copy it to a temp file, set `SCENE`, replace the `--- edits ---` block, run it with `--path <project>`, and report the `<<<OUT>>>` line. Set `ALLOW_SHRINK` only when the edit is meant to remove things.

Common edits inside that block:
- Find: `root.get_node(NodePath("Path/To/Node"))`
- Set: `n.set("prop", value)`, building math types explicitly (`Vector2(x, y)`, `Color(...)`)
- Assign a resource: `n.set("texture", load("res://icon.png"))`, which saves as an `ext_resource`
- Attach a script: `n.set_script(load("res://player.gd"))`
- Remove: `n.get_parent().remove_child(n); n.free()`
- Reparent: `remove_child`, set `owner = null`, `add_child` on the new parent, then `owner = root` again
- Group: `n.add_to_group("enemies", true)` (`true` = persistent)
- Add inside an instanced scene: `root.set_editable_instance(root.get_node("Player"), true)`, then add as usual (gotcha 5)

For a new scene, build the root node, `pack()`, `save()`, then add the header uid (gotcha 1).

After any write, re-read the file and confirm the change landed and the uid header survived.

## Playtesting a running game

A `--script` run is a separate process and can't touch a running game. To play the game, install [`debug_console.gd`](debug_console.gd) as an autoload. It listens on `127.0.0.1:7777` (debug builds only) and evaluates each line it receives as a GDScript `Expression`, with the console node as `self`. Send lines with [`send.sh`](send.sh), which prints one JSON reply (`{"ok": true, "result": ...}` or `{"ok": false, "error": ...}`).

**Install it once** (ask first, since it adds a file and an autoload to the user's project). Copy `debug_console.gd` into the project, then register it through Godot's writer so `project.godot` gets a clean diff:

```gdscript
extends SceneTree
func _init() -> void:
	ProjectSettings.set_setting("autoload/DebugConsole", "*res://debug_console.gd")
	quit(ProjectSettings.save())
```

**Run the game windowed** in the background: `godot --path <project> --resolution 1280x720`. Use `--headless` only if you won't need screenshots, because headless renders nothing. Poll `nc -z 127.0.0.1 7777` until the port is up.

**Play** by sending commands with `send.sh '<expr>'`:

| Command | Effect |
| --- | --- |
| `actions()` | The project's input actions (`ui_*` excluded); start here |
| `press("jump", 0.2)` | Hold an action, replying once it's released |
| `wait(1.0)` | Reply after that much game time |
| `click(x, y)` | Left click at viewport coordinates |
| `node("Player").position` | Read any property; the path is relative to the current scene |
| `node("Player").set("hp", 1)` | Write state (`Expression` has no `=`, so use `set`/`call`) |
| `shot()` | Save a screenshot and return its absolute path; open it with Read to see the frame |
| `get_tree().change_scene_to_file("res://level2.tscn")` | Any other engine call works too |

Replies for `press`/`wait` arrive only after the time passes, so a sequence of `send.sh` calls plays out in real time without shell sleeps. Use bash's `/dev/tcp` as `send.sh` does; macOS `nc` disconnects when its input ends and never waits for a delayed reply.

A good playtest loop: list the actions, screenshot, do one thing, read the state that should have changed, screenshot again, and report what you saw against what you expected. Kill the game process when done.

## Checking motion

One screenshot can't show an animation. Record frames with Movie Maker instead; it needs no autoload and runs at a fixed timestep, so frames are reproducible:

```bash
godot --path <project> res://scene.tscn --write-movie <dir>/f.png --fixed-fps 30 --quit-after 60
```

It runs windowed (headless renders nothing) and writes `<dir>/f00000000.png` onward. Tile 6–8 frames spread across one cycle into a single image (PIL) and Read that, rather than Reading frames one by one. For another camera angle, record from a temporary copy of the scene with the camera moved, then delete the copy. Check the motion against named expectations (which way a joint bends, which limbs move in opposite phase), since sign errors are the usual bug.
