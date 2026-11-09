extends SceneTree

# Prints every Skeleton3D in a scene or model as one compact line per bone:
#   <index> <name> <- <parent> (<x>, <y>, <z>) [*]
# Position is the bone's rest position in skeleton space. `*` marks a deform bone:
# one carrying skin weight on at least one vertex, which works on any rig whatever
# its naming. Run:
#   SCENE=res://player.glb [DEFORM_ONLY=1] godot --headless --path <project> \
#       --script read_skeleton.gd | grep '<<<OUT>>>'


func _init() -> void:
	var path := OS.get_environment("SCENE")
	var deform_only := OS.get_environment("DEFORM_ONLY") == "1"
	var packed := load(path) as PackedScene
	if packed == null:
		print("<<<OUT>>> cannot load SCENE=" + path)
		quit(1)
		return
	var root := packed.instantiate()
	for skel: Skeleton3D in root.find_children("*", "Skeleton3D", true, false):
		var deform := _deform_bones(root, skel)
		print(
			"<<<OUT>>> %s: %d bones, %d deform"
			% [root.get_path_to(skel), skel.get_bone_count(), deform.size()]
		)
		for b in skel.get_bone_count():
			if deform_only and not deform.has(b):
				continue
			var parent := skel.get_bone_parent(b)
			var o := skel.get_bone_global_rest(b).origin
			print(
				"<<<OUT>>> %d %s <- %s (%.3f, %.3f, %.3f)%s"
				% [
					b,
					skel.get_bone_name(b),
					skel.get_bone_name(parent) if parent != -1 else "-",
					o.x,
					o.y,
					o.z,
					" *" if deform.has(b) else "",
				],
			)
	root.free()
	quit()


## Skeleton bone indices that carry skin weight on at least one vertex.
func _deform_bones(root: Node, skel: Skeleton3D) -> Dictionary:
	var used := { }
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null or mi.skin == null or mi.get_node_or_null(mi.skeleton) != skel:
			continue
		for s in mi.mesh.get_surface_count():
			var arrays := mi.mesh.surface_get_arrays(s)
			var bones = arrays[Mesh.ARRAY_BONES]
			var weights = arrays[Mesh.ARRAY_WEIGHTS]
			if bones == null or weights == null:
				continue
			for i in mini(bones.size(), weights.size()):
				if weights[i] <= 0.0:
					continue
				# Mesh bone indices point at skin binds, not skeleton bones.
				var bind: int = bones[i]
				var name := mi.skin.get_bind_name(bind)
				used[skel.find_bone(name) if name != &"" else mi.skin.get_bind_bone(bind)] = true
	return used
