class_name Models
## Loads the Blender-made GLB models (tools/blender/build_models.py) and swaps
## their named placeholder materials for the project's texture sets.


static func material_for(name: String) -> Material:
	match name.get_slice(".", 0):
		"whitewash": return B.mat("whitewash", Color.WHITE, 0.3)
		"stone", "stone_blocks": return B.mat("stone_blocks", Color(1.05, 1.05, 1.0), 0.35)
		"red": return B.mat("metal_red", Color(0.9, 0.85, 0.85), 0.5)
		"iron": return B.mat("metal_rust", Color(0.45, 0.45, 0.45), 1.5, {"metallic": 0.5})
		"glass": return B.glass(Color(0.55, 0.65, 0.6, 0.22))
		"glass_dark": return B.flat(Color(0.02, 0.03, 0.035), 0.08, 0.6)
		"lamp": return B.glow(Color(1.0, 0.68, 0.35), 1.6)
		"copper": return B.mat("metal_green", Color(0.75, 1.1, 0.9), 0.8, {"metallic": 0.6})
		"slate": return B.mat("slate", Color.WHITE, 0.45)
		"wood": return B.mat("wood_dark", Color.WHITE, 0.8)
		"bark": return B.mat("bark", Color.WHITE, 0.45)
		"pine": return B.mat("pine", Color(1.1, 1.15, 1.1), 0.35)
		"skin": return B.mat("skin", Color(1.3, 1.25, 1.2), 3.0, {"world": false, "roughness": 0.8})
		"membrane":
			var m := B.mat("membrane", Color(1.4, 1.2, 1.2), 2.0, {"world": false}).duplicate() as StandardMaterial3D
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.backlight_enabled = true
			m.backlight = Color(0.35, 0.06, 0.05)
			return m
		"eye": return B.glow(Color(0.95, 0.75, 0.35), 2.5)
		"bone": return B.flat(Color(0.78, 0.74, 0.62), 0.5)
	return B.flat(Color(0.5, 0.5, 0.5))


## Instance a GLB, remap materials, optionally give named meshes trimesh collision.
static func spawn(path: String, parent: Node3D, pos: Vector3, yaw := 0.0, collide := [], surface := "stone") -> Node3D:
	var scene: PackedScene = load(path)
	var root: Node3D = scene.instantiate()
	parent.add_child(root)
	root.position = pos
	root.rotation.y = yaw
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		remap_materials(mi)
		if mi.name in collide or collide.has("*"):
			var sb := StaticBody3D.new()
			sb.collision_layer = B.LAYER_WORLD
			sb.set_meta("surface", surface)
			var cs := CollisionShape3D.new()
			var tri: ConcavePolygonShape3D = mi.mesh.create_trimesh_shape()
			tri.backface_collision = true
			cs.shape = tri
			sb.add_child(cs)
			mi.add_child(sb)
	return root


static func remap_materials(mi: MeshInstance3D) -> void:
	for i in mi.mesh.get_surface_count():
		var m := mi.mesh.surface_get_material(i)
		var n := m.resource_name if m else ""
		mi.set_surface_override_material(i, material_for(n))


## The meshes of a GLB by node name (for MultiMesh instancing, e.g. trees).
static func meshes(path: String) -> Dictionary:
	var scene: PackedScene = load(path)
	var root: Node3D = scene.instantiate()
	var out := {}
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var m: Mesh = mi.mesh
		for i in m.get_surface_count():
			var src := m.surface_get_material(i)
			m.surface_set_material(i, material_for(src.resource_name if src else ""))
		out[mi.name] = m
	root.free()
	return out
