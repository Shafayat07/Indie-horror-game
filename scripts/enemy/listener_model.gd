extends Node3D
## The Listener's body, generated from code: bundles of soaked rope strands,
## draped netting, dark mineral growths and fragments of maritime equipment.
## Animated procedurally (stride, sway, string vibration, independent head).

var hip_l: Node3D
var hip_r: Node3D
var shoulder_l: Node3D
var shoulder_r: Node3D
var torso: Node3D
var neck: Node3D
var head: Node3D
var vibrate := 0.0
var _phase := 0.0
var _t := 0.0
var _parts: Array[Node3D] = []
var _rope: Material
var _net: Material
var _mineral: Material
var _iron: Material


func _ready() -> void:
	_rope = B.mat("rope", Color(0.75, 0.75, 0.72), 3.0, {"world": false, "roughness": 0.55})
	var nm := B.mat("rope", Color(0.55, 0.55, 0.5), 3.0, {"world": false}).duplicate() as StandardMaterial3D
	nm.cull_mode = BaseMaterial3D.CULL_DISABLED
	_net = nm
	_mineral = B.flat(Color(0.03, 0.04, 0.045), 0.15, 0.4)
	_iron = B.mat("metal_rust", Color(0.6, 0.55, 0.5), 2.0, {"world": false})
	_build()


## Builds one ArrayMesh containing many rope strands running from `a` to `b`
## with noisy, twisted paths.
func _bundle(a: Vector3, b: Vector3, count: int, spread: float, radius: float, seed: int, sag := 0.0) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var axis := (b - a)
	var length := axis.length()
	var dir := axis / length
	var side := dir.cross(Vector3.FORWARD if abs(dir.z) < 0.9 else Vector3.RIGHT).normalized()
	var up := side.cross(dir).normalized()
	for s in count:
		var off := Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * spread
		var twist := rng.randf_range(-2.5, 2.5)
		var r := radius * rng.randf_range(0.6, 1.3)
		var segs := 7
		var pts: Array[Vector3] = []
		for i in segs + 1:
			var t := float(i) / segs
			var ang := twist * t
			var o := off.rotated(ang) * (1.0 - 0.35 * sin(t * PI))
			var wob := Vector2(sin(t * 9.0 + s), cos(t * 7.0 + s * 1.7)) * spread * 0.15
			var p := a + dir * length * t + side * (o.x + wob.x) + up * (o.y + wob.y)
			p.y -= sag * sin(t * PI)
			pts.append(p)
		_tube(st, pts, r, 5)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _rope
	return mi


func _tube(st: SurfaceTool, pts: Array[Vector3], r: float, sides: int) -> void:
	var rings := []
	for i in pts.size():
		var fwd := (pts[min(i + 1, pts.size() - 1)] - pts[max(i - 1, 0)]).normalized()
		var s := fwd.cross(Vector3.UP if abs(fwd.y) < 0.95 else Vector3.RIGHT).normalized()
		var u := s.cross(fwd).normalized()
		var ring := []
		var rr := r * (0.6 if i == pts.size() - 1 else 1.0)
		for k in sides:
			var a := TAU * k / sides
			ring.append(pts[i] + (s * cos(a) + u * sin(a)) * rr)
		rings.append(ring)
	for i in rings.size() - 1:
		for k in sides:
			var k2 := (k + 1) % sides
			var v0: Vector3 = rings[i][k]
			var v1: Vector3 = rings[i][k2]
			var v2: Vector3 = rings[i + 1][k]
			var v3: Vector3 = rings[i + 1][k2]
			st.set_uv(Vector2(float(k) / sides, float(i) / rings.size()))
			st.add_vertex(v0); st.add_vertex(v2); st.add_vertex(v1)
			st.add_vertex(v1); st.add_vertex(v2); st.add_vertex(v3)


func _net_sheet(w: float, h: float, seed: int) -> MeshInstance3D:
	## Hanging fishing net: a coarse lattice of thin strands.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var cols := 6
	var rows := 9
	var grid := []
	for j in rows + 1:
		var row := []
		for i in cols + 1:
			var x := (float(i) / cols - 0.5) * w * (1.0 - 0.3 * float(j) / rows)
			var y := -float(j) / rows * h
			row.append(Vector3(x + rng.randf_range(-0.04, 0.04), y, sin(x * 4.0) * 0.06 + rng.randf_range(-0.03, 0.03)))
		grid.append(row)
	for j in rows:
		for i in cols:
			if rng.randf() < 0.12:
				continue  # torn holes
			_tube(st, [grid[j][i], grid[j + 1][i + 1]] as Array[Vector3], 0.008, 3)
			_tube(st, [grid[j][i + 1], grid[j + 1][i]] as Array[Vector3], 0.008, 3)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _net
	return mi


func _shard(parent: Node3D, pos: Vector3, scale: float, rot: Vector3) -> void:
	var pm := PrismMesh.new()
	pm.size = Vector3(0.08, 0.35, 0.08) * scale
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	mi.material_override = _mineral
	parent.add_child(mi)
	mi.position = pos
	mi.rotation_degrees = rot


func _build() -> void:
	torso = Node3D.new()
	add_child(torso)
	torso.position.y = 1.15
	torso.add_child(_bundle(Vector3(0, 0, 0), Vector3(0.0, 1.15, 0.12), 16, 0.18, 0.035, 11))
	torso.add_child(_bundle(Vector3(-0.32, 1.05, 0.1), Vector3(0.32, 1.05, 0.1), 7, 0.06, 0.03, 12, 0.08))  # shoulder yoke
	# maritime fragments: a split buoy on one shoulder, chain on the chest
	var buoy := B.cyl(torso, Vector3(0.3, 1.12, 0.05), 0.17, 0.32, B.mat("metal_red", Color(0.7, 0.6, 0.6), 2.0, {"world": false}), {"collide": false, "segments": 8, "rot": Vector3(0, 0, 70)})
	buoy.scale = Vector3(1, 1, 0.6)
	for i in 6:
		B.cyl(torso, Vector3(-0.1 + i * 0.035, 0.85 - abs(i - 2.5) * 0.06, 0.22), 0.025, 0.06, _iron, {"collide": false, "segments": 6, "rot": Vector3(90, 0, 30 * i)})
	var net := _net_sheet(0.8, 1.3, 13)
	torso.add_child(net)
	net.position = Vector3(0, 1.1, 0.2)
	var net2 := _net_sheet(0.6, 1.0, 14)
	torso.add_child(net2)
	net2.position = Vector3(0, 1.05, -0.15)
	net2.rotation_degrees.y = 180
	for i in 7:
		_shard(torso, Vector3(-0.25 + i * 0.08, 1.12 + randf() * 0.05, -0.05), 1.0 + (i % 3) * 0.4, Vector3(randf_range(-40, 40), 0, randf_range(-50, 50)))

	for sgn in [-1, 1]:
		var hip := Node3D.new()
		add_child(hip)
		hip.position = Vector3(0.14 * sgn, 1.15, 0)
		hip.add_child(_bundle(Vector3.ZERO, Vector3(0.03 * sgn, -1.15, 0.05), 8, 0.08, 0.03, 20 + sgn))
		if sgn < 0: hip_l = hip
		else: hip_r = hip
		var sh := Node3D.new()
		torso.add_child(sh)
		sh.position = Vector3(0.33 * sgn, 1.05, 0.1)
		sh.add_child(_bundle(Vector3.ZERO, Vector3(0.12 * sgn, -1.45, 0.12), 6, 0.06, 0.025, 30 + sgn))
		# trailing strands from the fingers
		sh.add_child(_bundle(Vector3(0.12 * sgn, -1.45, 0.12), Vector3(0.16 * sgn, -1.8, 0.2), 4, 0.04, 0.012, 40 + sgn))
		if sgn < 0: shoulder_l = sh
		else: shoulder_r = sh

	neck = Node3D.new()
	torso.add_child(neck)
	neck.position = Vector3(0, 1.15, 0.14)
	neck.add_child(_bundle(Vector3.ZERO, Vector3(0, 0.25, 0.05), 6, 0.05, 0.025, 50))
	head = Node3D.new()
	neck.add_child(head)
	head.position = Vector3(0, 0.3, 0.05)
	# The head: a rusted diving-cage of iron bands stuffed with knotted rope.
	# There is no face to read, only a dark opening that tilts toward sound.
	head.add_child(_bundle(Vector3(0, -0.15, 0), Vector3(0, 0.28, -0.05), 12, 0.13, 0.03, 60))
	for i in 3:
		var band := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.17 - i * 0.02
		tm.outer_radius = 0.2 - i * 0.02
		tm.rings = 14
		tm.ring_segments = 4
		band.mesh = tm
		band.material_override = _iron
		head.add_child(band)
		band.position = Vector3(0, -0.05 + i * 0.12, 0)
		band.rotation_degrees = Vector3(randf_range(-15, 15), 0, randf_range(-10, 10))
	var hole := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.09
	sm.height = 0.14
	hole.mesh = sm
	hole.material_override = B.flat(Color(0, 0, 0), 1.0)
	head.add_child(hole)
	hole.position = Vector3(0, 0.03, 0.15)
	_shard(head, Vector3(0.08, 0.25, 0), 1.5, Vector3(0, 0, -25))
	_shard(head, Vector3(-0.1, 0.22, -0.05), 1.1, Vector3(15, 0, 30))
	for c in find_children("*", "MeshInstance3D", true, false):
		(c as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


## speed in m/s; head_target in global space (or null to face forward).
func animate(delta: float, speed: float, head_target: Variant) -> void:
	_t += delta
	_phase += delta * speed * 2.6
	var stride := clamp(speed / 2.0, 0.0, 1.0)
	hip_l.rotation.x = sin(_phase) * 0.45 * stride
	hip_r.rotation.x = -sin(_phase) * 0.45 * stride
	# arms hang and drag behind the swing, slightly out of phase
	shoulder_l.rotation.x = -sin(_phase - 0.6) * 0.3 * stride + 0.05 * sin(_t * 0.9)
	shoulder_r.rotation.x = sin(_phase - 0.6) * 0.3 * stride + 0.05 * sin(_t * 1.1)
	shoulder_l.rotation.z = -0.08 + 0.03 * sin(_t * 0.7)
	shoulder_r.rotation.z = 0.08 + 0.03 * sin(_t * 0.8)
	torso.position.y = 1.15 + abs(sin(_phase)) * 0.06 * stride + sin(_t * 0.8) * 0.015
	torso.rotation.x = 0.18 + 0.12 * stride + sin(_t * 0.6) * 0.03
	torso.rotation.z = sin(_phase) * 0.05 * stride
	# wet strings quiver at close range
	var v := vibrate * 0.012
	torso.position.x = randf_range(-v, v)
	neck.position.x = randf_range(-v, v) * 2.0
	if head_target != null:
		var local: Vector3 = neck.global_transform.affine_inverse() * (head_target as Vector3)
		var yaw := atan2(local.x, local.z)
		var pitch := -atan2(local.y, Vector2(local.x, local.z).length())
		yaw = clamp(yaw, -2.0, 2.0)
		head.rotation.y = lerp_angle(head.rotation.y, yaw, clamp(delta * 4.0, 0, 1))
		head.rotation.x = lerp_angle(head.rotation.x, clamp(pitch, -0.8, 0.8), clamp(delta * 4.0, 0, 1))
	else:
		head.rotation.y = lerp_angle(head.rotation.y, sin(_t * 0.4) * 0.5, clamp(delta * 1.5, 0, 1))
		head.rotation.x = lerp_angle(head.rotation.x, 0.2, clamp(delta * 1.5, 0, 1))
	# occasional, wrong-looking tilt
	head.rotation.z = sin(_t * 0.37) * 0.25 + (0.5 if fmod(_t, 11.0) < 0.4 else 0.0)


## Ending A: the body comes apart.
func collapse() -> void:
	var tw := create_tween().set_parallel()
	tw.tween_property(torso, "rotation:x", 1.4, 1.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(torso, "position:y", 0.25, 1.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_property(hip_l, "rotation:z", -1.3, 1.2)
	tw.tween_property(hip_r, "rotation:z", 1.3, 1.2)
	tw.tween_property(head, "rotation:z", 1.2, 1.0)
