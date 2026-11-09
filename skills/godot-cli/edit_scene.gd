extends SceneTree

# Template for editing a scene headless. Copy it to a temp file, set SCENE, fill
# in the `--- edits ---` block, then run:
#   godot --headless --path <project> --script <copy>.gd
#
# Edits the scene through Godot's own serializer so the saved .tscn is
# byte-for-byte what the editor would write. A headless re-save drops the uid
# header, so read it first and re-inject it after saving.
#
# The save is guarded: a headless run can silently lose scripts (see below), so
# the file is compared against its own before-image and rolled back rather than
# written lossy.

const SCENE := "res://scenes/main.tscn"

# Substrings whose count must not drop across a re-save. Each one is something a
# headless run can silently lose:
#   scripts     - a script that failed to compile leaves its node script-less
#   node_paths  - exported NodePaths vanish with the script that declared them
#   uids        - ext_resource uid="..." attributes are dropped without the editor
#   nodes       - a node whose owner was lost is not packed at all
#   editables   - an instance's "editable children" flag, without which nodes
#                 added inside that instance are dropped
const GUARDED := {
	"nodes": "[node ",
	"ext_resources": "[ext_resource ",
	"scripts": "script = ExtResource(",
	"node_paths": "node_paths=",
	"uids": "uid=\"uid://",
	"editables": "[editable ",
}

# Set true only when the edit is *meant* to remove nodes/scripts, which would
# otherwise trip the guard. Leave false for property-only edits.
const ALLOW_SHRINK := false


func _attr(line: String, key: String) -> String:
	var marker := ' %s="' % key
	var start := line.find(marker)
	if start == -1:
		return ""
	start += marker.length()
	var end := line.find('"', start)
	return "" if end == -1 else line.substr(start, end - start)


## Every script the scene loads, including those reached through sub-scenes — a
## sub-scene's script never appears in the parent's ext_resource list but is still
## compiled. Returns the ones that will not compile in this run.
func _uncompilable(path: String, seen: Dictionary) -> Array:
	if seen.has(path):
		return []
	seen[path] = true
	var bad := []
	for line in FileAccess.get_file_as_string(path).split("\n"):
		if not line.begins_with("[ext_resource "):
			continue
		var res_path := _attr(line, "path")
		if res_path.ends_with(".gd"):
			var s := ResourceLoader.load(res_path)
			# load() still succeeds for a script that failed to compile; only
			# can_instantiate() distinguishes it.
			if s == null or not (s is GDScript) or not (s as GDScript).can_instantiate():
				bad.append(res_path)
		elif res_path.ends_with(".tscn"):
			bad.append_array(_uncompilable(res_path, seen))
	return bad


func _read_uid(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var header := f.get_line()
	var marker := 'uid="'
	var start := header.find(marker)
	if start == -1:
		return ""
	start += marker.length()
	return header.substr(start, header.find('"', start) - start)


## A resource's uid as the editor would write it, read from the files themselves:
## a `.uid` sidecar (scripts, shaders), the `.import` remap (imported assets), or
## the header of a .tscn/.tres. Empty when none exists yet (run `--import` first).
func _uid_of(res_path: String) -> String:
	if FileAccess.file_exists(res_path + ".uid"):
		return FileAccess.get_file_as_string(res_path + ".uid").strip_edges()
	if FileAccess.file_exists(res_path + ".import"):
		var cfg := ConfigFile.new()
		if cfg.load(res_path + ".import") == OK:
			return str(cfg.get_value("remap", "uid", ""))
	if res_path.ends_with(".tscn") or res_path.ends_with(".tres"):
		return _read_uid(res_path)
	return ""


## A headless save drops uid= from every ext_resource, which the editor would have
## kept. Restore them, including for resources the edit newly referenced.
func _reinject_ext_uids(path: String) -> void:
	var lines := FileAccess.get_file_as_string(path).split("\n")
	for i in lines.size():
		var line: String = lines[i]
		if not line.begins_with("[ext_resource ") or not _attr(line, "uid").is_empty():
			continue
		var u := _uid_of(_attr(line, "path"))
		if not u.is_empty():
			lines[i] = line.replace(' path="', ' uid="%s" path="' % u)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("\n".join(lines))
	f.close()


func _reinject_uid(path: String, uid: String) -> void:
	if uid.is_empty():
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var content := f.get_as_text()
	f.close()
	var nl := content.find("\n")
	var header := content.substr(0, nl)
	if header.contains("uid="):
		return
	var close := header.rfind("]")
	var patched := header.substr(0, close) + ' uid="' + uid + '"' + header.substr(close)
	f = FileAccess.open(path, FileAccess.WRITE)
	f.store_string(patched + content.substr(nl))
	f.close()


func _counts(text: String) -> Dictionary:
	var c := { }
	for key in GUARDED:
		c[key] = text.count(GUARDED[key])
	return c


## Compares the saved file against its before-image and restores it if anything
## was lost. Returns the list of regressions (empty when the save is clean).
func _verify_or_rollback(path: String, before_text: String) -> Array:
	var before := _counts(before_text)
	var after := _counts(FileAccess.get_file_as_string(path))
	var lost := []
	for key in before:
		if after[key] < before[key]:
			lost.append("%s: %d -> %d" % [key, before[key], after[key]])
	if lost.is_empty() or ALLOW_SHRINK:
		return []
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(before_text)
	f.close()
	return lost


func _init() -> void:
	if not ResourceLoader.exists(SCENE):
		print("<<<OUT>>>" + JSON.stringify({ "ok": false, "error": "no such scene" }))
		quit(1)
		return
	# Refuse before touching anything. This is the actual precondition: a script
	# that references an autoload cannot compile under `--script`, so instantiate()
	# returns a node with no script and pack() saves that as the truth. The count
	# guard below cannot see it when an instanced child gains a serialized script
	# at the same time, so it must be caught here.
	var bad := _uncompilable(SCENE, { })
	if not bad.is_empty():
		print(
			"<<<OUT>>>" + JSON.stringify(
				{
					"ok": false,
					"refused": true,
					"uncompilable": bad,
					"hint": "These scripts do not compile in a headless run — almost always an autoload reference. Editing this scene would strip them. Hand-edit the .tscn instead.",
				},
			),
		)
		quit(1)
		return

	var uid := _read_uid(SCENE)
	var before_text := FileAccess.get_file_as_string(SCENE)
	# Edit state keeps instanced sub-scenes as instances, as the editor does. A plain
	# instantiate() re-saves any instance with editable children fully inlined.
	var root := (ResourceLoader.load(SCENE) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN)

	# --- edits: mutate the node tree here ---
	var sprite := Sprite2D.new()
	sprite.name = "Player"
	sprite.position = Vector2(100, 50)
	root.add_child(sprite)
	sprite.owner = root # required, else pack() drops the new node
	# --- end edits ---

	var packed := PackedScene.new()
	packed.pack(root)
	var err := ResourceSaver.save(packed, SCENE)
	root.free()
	# A failed save leaves the file untouched, which the count guard below reads as
	# a clean result.
	if err != OK:
		print("<<<OUT>>>" + JSON.stringify({ "ok": false, "error": "save failed (%d)" % err }))
		quit(1)
		return
	_reinject_uid(SCENE, uid)
	_reinject_ext_uids(SCENE)

	var lost := _verify_or_rollback(SCENE, before_text)
	if not lost.is_empty():
		print(
			"<<<OUT>>>" + JSON.stringify(
				{
					"ok": false,
					"rolled_back": true,
					"lost": lost,
					"hint": "The headless run lost data the editor would keep — almost always a script that references an autoload and so failed to compile. Autoloads do not exist under `godot --script`. Hand-edit the .tscn instead.",
				},
			),
		)
		quit(1)
		return

	print("<<<OUT>>>" + JSON.stringify({ "ok": true }))
	quit()
