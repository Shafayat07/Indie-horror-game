class_name P
## Small composite props built from primitives. Each returns its root node so
## callers can rotate or animate it.


static func _root(parent: Node3D, pos: Vector3, yaw := 0.0) -> Node3D:
	var n := Node3D.new()
	parent.add_child(n)
	n.position = pos
	n.rotation_degrees.y = yaw
	return n


static func crate(parent: Node3D, pos: Vector3, yaw := 0.0, s := 0.8) -> Node3D:
	var r := _root(parent, pos, yaw)
	B.box(r, Vector3(0, s * 0.5, 0), Vector3(s, s, s), B.mat("wood_planks", Color(0.9, 0.85, 0.75), 1.2), {"surface": "wood"})
	var slat := B.mat("wood_dark", Color.WHITE, 1.2)
	for y in [0.08, s - 0.08]:
		B.box(r, Vector3(0, y, s * 0.5 + 0.01), Vector3(s, 0.1, 0.03), slat, {"collide": false})
	return r


static func barrel(parent: Node3D, pos: Vector3, tint := Color(0.4, 0.42, 0.4)) -> Node3D:
	var r := _root(parent, pos, randf() * 360.0)
	B.cyl(r, Vector3(0, 0.45, 0), 0.3, 0.9, B.mat("metal_rust", tint * 2.0, 1.5), {"surface": "metal"})
	return r


static func buoy(parent: Node3D, pos: Vector3, tilt := 20.0) -> Node3D:
	var r := _root(parent, pos, randf() * 360.0)
	r.rotation_degrees.z = tilt
	B.cyl(r, Vector3(0, 0.5, 0), 0.45, 1.0, B.mat("metal_red", Color.WHITE, 1.0), {"collide": false, "top": 0.25})
	B.cyl(r, Vector3(0, 1.2, 0), 0.04, 0.6, B.flat(Color(0.2, 0.2, 0.2), 0.5, 0.6), {"collide": false})
	B.box(r, Vector3(0, 1.5, 0), Vector3(0.25, 0.25, 0.04), B.flat(Color(0.75, 0.72, 0.65)), {"collide": false})
	return r


static func net_pile(parent: Node3D, pos: Vector3) -> Node3D:
	var r := _root(parent, pos, randf() * 360.0)
	var m := B.mat("rope", Color(0.9, 0.95, 0.9), 2.0)
	for i in 4:
		var s := B.sphere(r, Vector3(randf_range(-0.3, 0.3), 0.1, randf_range(-0.3, 0.3)), 0.45, m)
		s.scale = Vector3(1.0, 0.35, 0.8)
	B.collider(r, Vector3(0, 0.15, 0), Vector3(1.0, 0.3, 1.0), Vector3.ZERO, "wood")
	return r


static func lamp_post(parent: Node3D, pos: Vector3, color := Color(1.0, 0.65, 0.3), energy := 1.6, flicker := true) -> OmniLight3D:
	var r := _root(parent, pos)
	var pole := B.mat("wood_dark", Color.WHITE, 1.0)
	B.box(r, Vector3(0, 1.6, 0), Vector3(0.14, 3.2, 0.14), pole, {"surface": "wood"})
	B.box(r, Vector3(0.3, 3.15, 0), Vector3(0.7, 0.08, 0.08), pole, {"collide": false})
	B.box(r, Vector3(0.6, 2.95, 0), Vector3(0.18, 0.26, 0.18), B.glow(color, 3.0), {"collide": false})
	var l := B.omni(r, Vector3(0.6, 2.7, 0), color, energy, 11.0, true)
	if flicker:
		l.set_script(preload("res://scripts/world/flicker.gd"))
	return l


static func table(parent: Node3D, pos: Vector3, yaw := 0.0, size := Vector2(1.2, 0.8)) -> Node3D:
	var r := _root(parent, pos, yaw)
	var m := B.mat("wood_dark", Color(1.1, 1.0, 0.9), 1.0)
	B.box(r, Vector3(0, 0.76, 0), Vector3(size.x, 0.06, size.y), m, {"surface": "wood"})
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			B.box(r, Vector3(sx * (size.x * 0.5 - 0.06), 0.37, sz * (size.y * 0.5 - 0.06)), Vector3(0.06, 0.74, 0.06), m, {"collide": false})
	B.collider(r, Vector3(0, 0.4, 0), Vector3(size.x, 0.8, size.y))
	return r


static func chair(parent: Node3D, pos: Vector3, yaw := 0.0) -> Node3D:
	var r := _root(parent, pos, yaw)
	var m := B.mat("wood_dark", Color(1.0, 0.95, 0.9), 1.0)
	B.box(r, Vector3(0, 0.45, 0), Vector3(0.45, 0.05, 0.45), m, {"collide": false})
	B.box(r, Vector3(0, 0.75, -0.2), Vector3(0.45, 0.6, 0.05), m, {"collide": false})
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			B.box(r, Vector3(sx * 0.19, 0.22, sz * 0.19), Vector3(0.04, 0.45, 0.04), m, {"collide": false})
	B.collider(r, Vector3(0, 0.45, 0), Vector3(0.45, 0.9, 0.45))
	return r


static func shelf(parent: Node3D, pos: Vector3, yaw := 0.0, w := 1.2) -> Node3D:
	var r := _root(parent, pos, yaw)
	var m := B.mat("wood_planks", Color(0.8, 0.75, 0.7), 1.0)
	B.box(r, Vector3(0, 1.0, 0), Vector3(w, 2.0, 0.35), B.flat(Color(0, 0, 0, 0)), {"collide": true})
	r.get_child(0).visible = false
	for y in [0.05, 0.6, 1.15, 1.7]:
		B.box(r, Vector3(0, y, 0), Vector3(w, 0.04, 0.35), m, {"collide": false})
	for sx in [-1, 1]:
		B.box(r, Vector3(sx * w * 0.5, 0.95, 0), Vector3(0.04, 1.9, 0.35), m, {"collide": false})
	# clutter: jars, tins, books
	for i in 7:
		var y: float = [0.6, 1.15, 1.7][i % 3] + 0.1
		B.box(r, Vector3(randf_range(-w * 0.4, w * 0.4), y, randf_range(-0.05, 0.05)), Vector3(randf_range(0.06, 0.18), randf_range(0.12, 0.22), 0.15),
			B.flat(Color(randf_range(0.15, 0.4), randf_range(0.15, 0.35), randf_range(0.12, 0.3)), 0.7), {"collide": false})
	return r


static func bed(parent: Node3D, pos: Vector3, yaw := 0.0) -> Node3D:
	var r := _root(parent, pos, yaw)
	B.box(r, Vector3(0, 0.25, 0), Vector3(0.95, 0.5, 2.0), B.mat("wood_dark", Color.WHITE, 1.0), {"surface": "wood"})
	B.box(r, Vector3(0, 0.55, 0.05), Vector3(0.9, 0.12, 1.85), B.flat(Color(0.38, 0.37, 0.33), 0.95), {"collide": false})
	B.box(r, Vector3(0, 0.66, -0.75), Vector3(0.6, 0.12, 0.3), B.flat(Color(0.5, 0.49, 0.45), 0.95), {"collide": false})
	B.box(r, Vector3(0, 0.6, -1.0), Vector3(0.95, 1.2, 0.06), B.mat("wood_dark", Color.WHITE, 1.0), {"collide": false})
	return r


static func stove(parent: Node3D, pos: Vector3, yaw := 0.0) -> Node3D:
	var r := _root(parent, pos, yaw)
	var m := B.mat("metal_rust", Color(0.4, 0.4, 0.4), 1.5, {"metallic": 0.4})
	B.box(r, Vector3(0, 0.45, 0), Vector3(0.8, 0.9, 0.6), m, {"surface": "metal"})
	B.cyl(r, Vector3(0, 1.6, -0.15), 0.08, 1.4, m, {"collide": false})
	return r


static func workbench(parent: Node3D, pos: Vector3, yaw := 0.0) -> Node3D:
	var r := _root(parent, pos, yaw)
	var m := B.mat("wood_planks", Color(0.9, 0.85, 0.8), 1.0)
	B.box(r, Vector3(0, 0.9, 0), Vector3(2.0, 0.08, 0.7), m, {"surface": "wood"})
	for sx in [-1, 1]:
		B.box(r, Vector3(sx * 0.9, 0.45, 0), Vector3(0.08, 0.9, 0.6), m, {"collide": false})
	B.box(r, Vector3(0, 0.25, 0), Vector3(1.8, 0.05, 0.55), m, {"collide": false})
	B.collider(r, Vector3(0, 0.45, 0), Vector3(2.0, 0.9, 0.7))
	# tools and a vice
	B.box(r, Vector3(-0.7, 0.98, 0.1), Vector3(0.15, 0.12, 0.2), B.mat("metal_green", Color.WHITE, 2.0), {"collide": false})
	B.box(r, Vector3(0.6, 0.95, -0.15), Vector3(0.4, 0.03, 0.05), B.flat(Color(0.3, 0.3, 0.3), 0.4, 0.8), {"collide": false})
	return r


static func radio_set(parent: Node3D, pos: Vector3, yaw := 0.0, lit := true) -> Node3D:
	var r := _root(parent, pos, yaw)
	B.box(r, Vector3(0, 0.15, 0), Vector3(0.5, 0.3, 0.28), B.mat("wood_dark", Color(1.2, 1.0, 0.85), 2.0), {"collide": false})
	B.box(r, Vector3(-0.1, 0.16, 0.141), Vector3(0.22, 0.18, 0.01), B.flat(Color(0.12, 0.1, 0.08)), {"collide": false})
	B.box(r, Vector3(0.14, 0.2, 0.141), Vector3(0.14, 0.05, 0.01), B.glow(Color(1.0, 0.6, 0.25), 1.5 if lit else 0.0), {"collide": false})
	for i in 2:
		B.cyl(r, Vector3(0.1 + i * 0.08, 0.08, 0.15), 0.02, 0.03, B.flat(Color(0.1, 0.1, 0.1)), {"collide": false, "rot": Vector3(90, 0, 0)})
	return r


static func paper(parent: Node3D, pos: Vector3, yaw := 0.0) -> Node3D:
	var r := _root(parent, pos, yaw)
	B.box(r, Vector3(0, 0.005, 0), Vector3(0.22, 0.01, 0.3), B.flat(Color(0.75, 0.72, 0.62), 0.9), {"collide": false})
	return r


## A readable document: a sheet of paper you can pick up and read.
static func note(parent: Node3D, pos: Vector3, doc_id: String, yaw := 0.0, upright := false) -> Interactable:
	var r := paper(parent, pos, yaw)
	if upright:
		r.rotation_degrees.x = 90
	var it := Interactable.make(parent, pos + (Vector3(0, 0, 0) if upright else Vector3(0, 0.05, 0)), Vector3(0.5, 0.3, 0.5), "Read")
	it.used.connect(func(p): p.hud.open_note(doc_id))
	return it


static func pillar_rock(parent: Node3D, pos: Vector3, h: float, m: Material) -> void:
	B.rock(parent, pos + Vector3(0, h * 0.4, 0), Vector3(1.4, h * 0.6, 1.3), randi() % 5, m, true, randf() * TAU)
