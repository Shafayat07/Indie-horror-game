extends Node3D
## LOCATION D — THE EXPOSED TIDAL CAVES.
## A carved heightfield cave (floor and walls from one signed-distance layout,
## plus a ceiling). Puzzle: record the drowned bell (only audible while
## listening) and replay it into the seal's horn. Then the gallery: The
## Listener patrols it; record the loose plate in the side cave and replay it
## to send it away, or creep past. A survey cable on the floor guides you.

const O := Vector3(0, -200, 0)   # must match island.CAVE_ORIGIN
const STEP := 0.5
const MIN := Vector2(-30, -95)
const MAX := Vector2(30, 8)
const HORN := Vector2(0.9, -34.8)
const BELL := Vector2(-14.5, -31)
const PLATE := Vector2(12.5, -55)
const GALLERY_PATROL := [Vector3(0, 0, -70), Vector3(-2.5, 0, -60), Vector3(2, 0, -48), Vector3(-1, 0, -41), Vector3(3, 0, -64), Vector3(8, 0, -55)]

## Layout: segments [ax, az, bx, bz, half_width] and chambers [x, z, radius]
const SEGS := [
	[0.0, 2.0, 0.0, -16.0, 1.8],
	[-3.0, -24.0, -14.5, -31.0, 1.5],
	[0.0, -28.0, 0.0, -38.0, 1.4],
	[0.0, -38.0, 0.0, -74.0, 3.0],
	[0.0, -55.0, 12.5, -55.0, 1.3],
	[0.0, -72.0, 0.0, -80.0, 2.2],
	[-4.0, -46.0, -6.5, -48.0, 1.1],
	[3.5, -66.0, 6.5, -68.0, 1.1],
]
const ROOMS := [
	[0.0, -22.0, 8.5],
	[-14.5, -31.0, 4.0],
	[12.5, -55.0, 3.6],
	[0.0, -84.0, 7.0],
	[-6.8, -48.3, 1.6],
	[6.8, -68.3, 1.6],
]
## Pools: [x, z, radius]
const POOLS := [[-3.5, -20.0, 2.6], [4.0, -25.0, 2.0], [-14.5, -31.5, 2.2], [1.5, -52.0, 1.8], [-1.5, -63.0, 2.2]]

var level: Node
var _noise := FastNoiseLite.new()
var _seal: Door
var _horn_pos := Vector3.ZERO
var _bell_caption_cd := 0.0


func build(lv: Node) -> void:
	level = lv
	add_to_group("navsrc_caves")
	_noise.seed = 9
	_noise.frequency = 0.15
	level.checkpoints["caves"] = [_p(0, 0, 0.3), 180.0, "caves"]
	level.checkpoints["caves_gate"] = [_p(0, -32, 0.3), 180.0, "caves"]
	_build_mesh()
	_pools()
	_dress()
	_puzzle()
	_gallery()
	_exit()
	_surface_mouth()
	_annex_door()
	Zone.make(self, O + Vector3(0, 2, -45), Vector3(64, 14, 110), {"ambience": "caves", "reverb": 0.45})


func _sdf(x: float, z: float) -> float:
	var p := Vector2(x, z)
	var d := 1e9
	for s in SEGS:
		var a := Vector2(s[0], s[1])
		var b := Vector2(s[2], s[3])
		var ab := b - a
		var t: float = clamp((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		d = min(d, p.distance_to(a + ab * t) - s[4])
	for r in ROOMS:
		d = min(d, p.distance_to(Vector2(r[0], r[1])) - r[2])
	return d + _noise.get_noise_2d(x * 1.3, z * 1.3) * 0.7


func floor_h(x: float, z: float) -> float:
	var h := _noise.get_noise_2d(x * 0.6 + 50, z * 0.6) * 0.25
	for pl in POOLS:
		var d := Vector2(x, z).distance_to(Vector2(pl[0], pl[1]))
		h -= 0.45 * (1.0 - smoothstep(pl[2] * 0.6, pl[2], d))
	return h


func _height(x: float, z: float) -> float:
	var d := _sdf(x, z)
	var f := floor_h(x, z)
	if d <= 0.0:
		return f
	return f + min(d * 5.0, 9.0) + _noise.get_noise_2d(x * 3.0, z * 3.0) * 0.4 * min(d, 1.0)


func _ceil(x: float, z: float) -> float:
	var room := 0.0
	for r in ROOMS:
		room = max(room, 1.0 - smoothstep(r[2] * 0.4, r[2] + 1.5, Vector2(x, z).distance_to(Vector2(r[0], r[1]))))
	return 3.6 + room * 3.0 + _noise.get_noise_2d(x * 2.2 + 99, z * 2.2) * 0.9


func _build_mesh() -> void:
	## Built in tiles so each piece is touched by few lights (and culls well).
	var rock := B.mat("rock_cave", Color(1.5, 1.5, 1.45), 0.4, {"roughness": 0.7, "normal": 1.5})
	var tile := 12.0
	var tx := MIN.x
	while tx < MAX.x - 0.01:
		var tz := MIN.y
		while tz < MAX.y - 0.01:
			_tile(Vector2(tx, tz), Vector2(min(tx + tile, MAX.x), min(tz + tile, MAX.y)), rock)
			tz += tile
		tx += tile


func _tile(a: Vector2, b: Vector2, rock: Material) -> void:
	var nx := int(round((b.x - a.x) / STEP)) + 1
	var nz := int(round((b.y - a.y) / STEP)) + 1
	# skip tiles that are solid rock everywhere (never seen)
	var any_open := false
	for iz in range(0, nz, 2):
		for ix in range(0, nx, 2):
			if _sdf(a.x + ix * STEP, a.y + iz * STEP) < 2.5:
				any_open = true
				break
		if any_open:
			break
	if not any_open:
		return
	var floor_st := SurfaceTool.new()
	floor_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ceil_st := SurfaceTool.new()
	ceil_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in nz:
		for ix in nx:
			var x := a.x + ix * STEP
			var z := a.y + iz * STEP
			floor_st.add_vertex(Vector3(x, _height(x, z), z))
			ceil_st.add_vertex(Vector3(x, _ceil(x, z), z))
	for iz in nz - 1:
		for ix in nx - 1:
			var i0 := iz * nx + ix
			var i1 := i0 + 1
			var i2 := i0 + nx
			var i3 := i2 + 1
			floor_st.add_index(i0); floor_st.add_index(i1); floor_st.add_index(i2)
			floor_st.add_index(i1); floor_st.add_index(i3); floor_st.add_index(i2)
			ceil_st.add_index(i0); ceil_st.add_index(i2); ceil_st.add_index(i1)
			ceil_st.add_index(i1); ceil_st.add_index(i2); ceil_st.add_index(i3)
	floor_st.generate_normals()
	ceil_st.generate_normals()
	var fm := floor_st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = fm
	mi.material_override = rock
	add_child(mi)
	mi.position = O
	var sb := StaticBody3D.new()
	sb.collision_layer = B.LAYER_WORLD
	sb.set_meta("surface", "stone")
	var cs := CollisionShape3D.new()
	var tri := fm.create_trimesh_shape()
	tri.backface_collision = true
	cs.shape = tri
	sb.add_child(cs)
	mi.add_child(sb)
	var cm := MeshInstance3D.new()
	cm.mesh = ceil_st.commit()
	cm.material_override = rock
	add_child(cm)
	cm.position = O


func _pools() -> void:
	# shallow pools: water surfaces that make your footsteps loud
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.02, 0.04, 0.045, 0.75)
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.roughness = 0.02
	water.metallic = 0.5
	for pl in POOLS:
		var w := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(pl[2] * 2.2, pl[2] * 2.2)
		w.mesh = pm
		w.material_override = water
		add_child(w)
		w.position = O + Vector3(pl[0], -0.18, pl[1])
		Zone.make(self, O + Vector3(pl[0], 0.2, pl[1]), Vector3(pl[2] * 1.3, 1.0, pl[2] * 1.3), {"water": true})


func _p(x: float, z: float, up := 0.0) -> Vector3:
	return O + Vector3(x, floor_h(x, z) + up, z)


func _dress() -> void:
	var mineral := B.glow(Color(0.35, 0.75, 0.7), 1.6)
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	# glowing mineral seams: a cold landmark light in every chamber
	for spot in [Vector2(-6, -18), Vector2(6, -27), Vector2(-17, -33), Vector2(-3, -50), Vector2(4, -62), Vector2(14.5, -57), Vector2(-5, -86), Vector2(4, -10)]:
		for i in 5:
			var pm := PrismMesh.new()
			pm.size = Vector3(0.12, rng.randf_range(0.3, 0.8), 0.12)
			var m := MeshInstance3D.new()
			m.mesh = pm
			m.material_override = mineral
			add_child(m)
			m.position = _p(spot.x + rng.randf_range(-0.6, 0.6), spot.y + rng.randf_range(-0.6, 0.6), 0.2)
			m.rotation_degrees = Vector3(rng.randf_range(-30, 30), rng.randf_range(0, 360), rng.randf_range(-30, 30))
		B.omni(self, _p(spot.x, spot.y, 0.8), Color(0.3, 0.7, 0.65), 1.0, 8.0)
	# moonlight spilling in at the mouth
	B.omni(self, _p(0, 1.5, 2.5), Color(0.45, 0.55, 0.75), 1.2, 9.0)
	# hanging ropes from the old survey
	var rope := B.mat("rope", Color.WHITE, 2.0)
	for i in 14:
		var x := rng.randf_range(-3, 3)
		var z := rng.randf_range(-80, -5)
		if _sdf(x, z) > -0.5:
			continue
		var len := rng.randf_range(1.2, 2.6)
		B.box(self, _p(x, z, _ceil(x, z) - len * 0.5 - floor_h(x, z)), Vector3(0.04, len, 0.04), rope, {"collide": false})
	# the survey cable: a black line with yellow tags, from the mouth to the lighthouse stair
	var cable := B.flat(Color(0.03, 0.03, 0.03), 0.4)
	var tag := B.glow(Color(0.8, 0.65, 0.1), 0.6)
	var pts := [Vector2(0.6, 1), Vector2(0.8, -14), Vector2(1.2, -26), Vector2(0.6, -36), Vector2(-0.8, -45), Vector2(-1.8, -58), Vector2(-0.8, -70), Vector2(0.5, -78), Vector2(1.0, -82)]
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var steps := int(a.distance_to(b) / 1.5)
		for k in steps:
			var p := a.lerp(b, (k + 0.5) / steps)
			var seg := B.box(self, _p(p.x, p.y, 0.04), Vector3(0.05, 0.05, 1.55), cable, {"collide": false, "shadow": false})
			seg.rotation.y = atan2(b.x - a.x, b.y - a.y)
			if k % 3 == 0:
				B.box(self, _p(p.x, p.y, 0.08), Vector3(0.12, 0.04, 0.08), tag, {"collide": false})
	# research lamps: mostly dead, one flickers
	for spot in [Vector2(1.5, -40), Vector2(-2.5, -66)]:
		var post := B.mat("metal_rust", Color.WHITE, 1.0)
		B.box(self, _p(spot.x, spot.y, 1.0), Vector3(0.08, 2.0, 0.08), post, {})
		B.box(self, _p(spot.x, spot.y, 2.05), Vector3(0.3, 0.2, 0.2), B.glow(Color(1.0, 0.7, 0.35), 2.0), {"collide": false})
		var l := B.omni(self, _p(spot.x, spot.y, 1.9), Color(1.0, 0.7, 0.35), 1.1, 9.0, true)
		l.set_script(preload("res://scripts/world/flicker.gd"))
	# pillars in the gallery to hide behind
	var rock := B.mat("rock_cave", Color.WHITE, 0.4)
	for spot in [Vector2(-1.8, -44), Vector2(1.9, -51), Vector2(-1.5, -57), Vector2(1.2, -62), Vector2(-1.9, -68)]:
		B.rock(self, _p(spot.x, spot.y, 1.6), Vector3(0.9, 2.6, 0.9), rng.randi() % 5, rock, true, rng.randf() * TAU)
	# a voice that seems close but has no source (listen-only)
	var v := Node3D.new()
	add_child(v)
	v.position = _p(7, -18, 1.2)
	Sound.attach_loop(v, "amb_static", -80.0, {"autoplay": false})
	var whisper := AudioStreamPlayer3D.new()
	whisper.stream = Sound.get_stream("whisper_1")
	whisper.bus = "ListenOnly"
	whisper.unit_size = 4.0
	v.add_child(whisper)
	var t := Timer.new()
	t.wait_time = 7.0
	t.autostart = true
	v.add_child(t)
	t.timeout.connect(func(): whisper.play())
	# footsteps from inside the rock in the entrance tunnel
	Zone.make(self, O + Vector3(0, 1, -8), Vector3(4, 3, 2), {"once": true, "on_enter": func(_b):
		Sound.pre_echo("echo_footsteps_stone", O + Vector3(4.5, 1, -10), "[footsteps — coming from inside the rock]", -2.0)})
	# splash pre-echoes at the pools in the hall
	for i in 2:
		var pl: Array = POOLS[i]
		Zone.make(self, O + Vector3(pl[0], 1, pl[1] + 4.0), Vector3(5, 3, 2.5), {"once": true, "on_enter": func(_b):
			Sound.pre_echo("splash", O + Vector3(pl[0], 0, pl[1]), "[a splash in the pool ahead — the water is still]", -4.0)})


func _puzzle() -> void:
	# the drowned bell, lying in its pool
	var bell := B.cyl(self, _p(BELL.x, BELL.y, -0.05), 0.42, 0.7, B.mat("metal_green", Color(0.6, 0.75, 0.65), 1.0, {"metallic": 0.6, "roughness": 0.4}), {"collide": false, "top": 0.22})
	bell.rotation_degrees = Vector3(70, 30, 0)
	Recordable.make(self, _p(BELL.x, BELL.y, 0.5), "bell", "bell_drowned", {"listen_only": true, "radius": 5.0, "interval": 8.0, "volume": 2.0, "unit_size": 4.0})
	var bell_it := Interactable.make(self, _p(BELL.x, BELL.y, 0.2), Vector3(1.0, 0.6, 1.0), "Drowned bell")
	bell_it.used.connect(func(p): p.hud.toast("A ship's bell, half under water. It's perfectly still. Listen to it.  [Q]"))
	# the resonance seal
	var iron := B.mat("metal_rust", Color(0.75, 0.7, 0.65), 0.8, {"metallic": 0.5})
	var gz := -36.5
	B.box(self, _p(-2.4, gz, 2.0), Vector3(2.0, 4.0, 0.6), iron, {})
	B.box(self, _p(2.4, gz, 2.0), Vector3(2.0, 4.0, 0.6), iron, {})
	B.box(self, _p(0, gz, 3.4), Vector3(3.0, 1.2, 0.6), iron, {})
	_seal = Door.make(self, _p(0, gz, 0.0), 0, {"id": "seal", "w": 2.6, "h": 2.8, "mat": iron, "lock": "seal_open",
		"locked_text": "A resonance seal. It won't move by hand.", "prompt": "Iron seal", "noise": 20.0})
	B.label(self, _p(0, gz, 2.95) + Vector3(0, 0, 0.33), "LOWER GALLERY", 34, Color(0.8, 0.75, 0.6))
	B.omni(self, _p(0, gz + 2.0, 2.6), Color(0.9, 0.15, 0.08), 0.8, 6.0)
	B.sphere(self, _p(0, gz + 0.35, 2.75), 0.08, B.glow(Color(1, 0.15, 0.08), 4.0))
	# the horn receiver
	_horn_pos = _p(HORN.x, HORN.y, 1.4)
	var horn := B.cyl(self, _horn_pos, 0.06, 0.8, B.mat("metal_green", Color(0.8, 0.8, 0.6), 1.0, {"metallic": 0.7}), {"collide": false, "top": 0.35})
	horn.rotation_degrees = Vector3(-90, 0, 0)
	B.box(self, _p(HORN.x, HORN.y, 0.6), Vector3(0.1, 1.2, 0.1), iron, {})
	P.note(self, _p(-1.6, gz + 0.45, 1.5), "cave_plaque", 0, true)
	add_to_group("replay_receivers")


func on_replay(id: String, pos: Vector3) -> void:
	if Game.debug_ai:
		print("[debug] replay ", id, " at ", pos, " horn dist ", pos.distance_to(_horn_pos))
	if Game.has_flag("seal_open"):
		return
	if pos.distance_to(_horn_pos) > 5.0:
		return
	if id != "bell":
		Sound.play_at("door_locked", _horn_pos, -6.0)
		level.hud.toast("The horn rattles, then goes still. Wrong sound.")
		return
	Game.set_flag("seal_open")
	await get_tree().create_timer(1.0).timeout
	Sound.play_at("bell_drowned", _horn_pos, 4.0, {"unit_size": 10.0})
	Sound.play_at("hatch_open", _seal.global_position + Vector3(0, 1.4, 0), 2.0, {"unit_size": 10.0})
	level.player.shake(0.6)
	await get_tree().create_timer(1.5).timeout
	_seal.open_from_script(-1.0)
	level.hud.toast("The seal answers the bell and swings open.")
	level.objective("cross_caves")
	level.checkpoint("caves_gate")


func _gallery() -> void:
	# the loose plate in the side cave: a recordable lure
	var plate := B.box(self, _p(PLATE.x + 1.6, PLATE.y + 0.5, 1.2), Vector3(0.05, 1.4, 1.0), B.mat("metal_rust", Color.WHITE, 1.0, {"metallic": 0.5}), {"collide": false})
	plate.rotation_degrees.z = 8
	Recordable.make(self, _p(PLATE.x + 1.2, PLATE.y + 0.5, 1.0), "plate", "metal_knock", {"radius": 5.5, "interval": 18.0, "volume": -8.0, "unit_size": 4.0})
	P.note(self, _p(PLATE.x - 3.0, PLATE.y - 1.25, 1.4), "cave_scrawl", 180, true)
	# entering the gallery: your own running footsteps come down it toward you
	Zone.make(self, O + Vector3(0, 1, -40), Vector3(6, 3, 2), {"once": true, "require": "seal_open", "block": "gallery_entered", "on_enter": func(_b):
		Game.set_flag("gallery_entered")
		Sound.pre_echo("echo_running", O + Vector3(0, 1, -66), "[running footsteps coming down the gallery — yours]", 2.0, 0.0, {"unit_size": 12.0})
		await get_tree().create_timer(5.0).timeout
		_activate_listener()})


func _activate_listener() -> void:
	var pts: Array = []
	for p in GALLERY_PATROL:
		pts.append(_p(p.x, p.z))
	level.listener.activate(_p(0, -76), pts)
	level.listener.hearing = 1.0
	await get_tree().create_timer(4.0).timeout
	level.hud.toast("It's in the gallery. Something in the side cave knocks when the sea breathes.", 5.0)


func _exit() -> void:
	# iron stair up into the lighthouse foundations
	var iron := B.mat("metal_rust", Color(0.7, 0.7, 0.7), 1.0, {"metallic": 0.5})
	var base := _p(0, -86)
	for i in 10:
		var a := i * 0.6
		B.box(self, base + Vector3(cos(a) * 1.0, i * 0.3 + 0.15, sin(a) * 1.0), Vector3(1.2, 0.06, 0.4), iron, {"collide": false})
	B.cyl(self, base + Vector3(0, 2.0, 0), 0.12, 4.0, iron, {})
	B.spot(self, base + Vector3(0, 6.5, 0), Color(0.7, 0.8, 1.0), 2.5, 10.0, 30.0)
	var it := Interactable.make(self, base + Vector3(0.8, 1.0, 0.5), Vector3(1.6, 2.0, 1.6), "Climb the iron stair")
	it.used.connect(func(_p):
		level.listener.deactivate()
		if not Game.has_flag("reached_lighthouse"):
			Game.set_flag("reached_lighthouse")
			level.objective("release_seal")
			Game.state.checkpoint = "lighthouse"
			level.checkpoint("lighthouse")
		var cp: Array = level.checkpoints["lighthouse"]
		level.travel(cp[0], cp[1], "surface", "lighthouse"))
	var back := Interactable.make(self, O + Vector3(0, 1.0, 3.0), Vector3(3.0, 2.0, 1.0), "Go back out to the beach")
	back.used.connect(func(_p):
		level.listener.deactivate()
		level.travel(Vector3(65.5, Terrain.height(65.5, -46.0) + 0.3, -46.0), 180.0, "surface", "cliffs"))


func _annex_door() -> void:
	## an iron door in the gallery's west pocket: Project Morrow's annex
	var iron := B.mat("metal_rust", Color(0.6, 0.6, 0.6), 1.0, {"metallic": 0.5})
	var p := _p(-7.6, -48.6, 1.1)
	B.box(self, p, Vector3(0.2, 2.2, 1.3), iron, {}).rotation_degrees.y = -60
	B.label(self, p + Vector3(0.25, 0.9, 0.1), "MORROW", 26, Color(0.8, 0.75, 0.6), Vector3(0, 30, 0))
	var it := Interactable.make(self, p + Vector3(0.4, 0, 0.2), Vector3(1.0, 2.0, 1.4), "Iron door — PROJECT MORROW")
	it.used.connect(func(_p):
		level.listener.deactivate()
		var cp: Array = level.checkpoints["annex"]
		level.travel(cp[0], cp[1], "annex", "station_in"))


func _surface_mouth() -> void:
	## The cave mouth on the exposed tidal shelf, at the foot of the east cliffs.
	var mouth := Node3D.new()
	mouth.name = "CaveMouth"
	add_child(mouth)
	var rock := B.mat("cliff", Color(0.8, 0.8, 0.8), 0.3)
	var c := Vector3(66, -1.0, -50.5)
	for spec in [[Vector3(-3.2, 2.2, 0), Vector3(2.2, 4.6, 2.6)], [Vector3(3.2, 2.0, 0), Vector3(2.4, 4.4, 2.6)], [Vector3(0, 5.2, -0.5), Vector3(5.0, 1.8, 2.6)],
			[Vector3(-6.5, 3.0, -1.5), Vector3(4, 6, 3)], [Vector3(7, 3.5, -1.5), Vector3(4, 7, 3)]]:
		B.rock(mouth, c + spec[0], spec[1], randi() % 5, rock, true, randf() * TAU)
	var dark := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(4.5, 4.5)
	dark.mesh = qm
	dark.material_override = B.flat(Color(0, 0, 0), 1.0)
	mouth.add_child(dark)
	dark.position = c + Vector3(0, 2.0, -0.8)
	B.collider(mouth, c + Vector3(0, 2.0, -1.2), Vector3(4.5, 4.5, 0.4))
	Zone.make(mouth, c + Vector3(0, 1.5, 0.2), Vector3(3.5, 3, 1.2), {"require": "tide_out", "on_enter": func(_b):
		if not Game.has_flag("found_caves"):
			Game.set_flag("found_caves")
			level.objective("open_gate")
			level.chapter("ch_caves")
			level.hud.elias("caves", 3.0)
			Game.state.checkpoint = "caves"
			level.checkpoint("caves")
		var cp: Array = level.checkpoints["caves"]
		level.travel(cp[0], cp[1], "caves", "caves")})
	# the cliff path down and the shelf are the "cliffs" ambience
	Zone.make(mouth, Vector3(62, 2, -18), Vector3(30, 14, 70), {"ambience": "cliffs"})
	B.label(mouth, c + Vector3(2.6, 0.9, 1.4), "SURVEY CABLE →", 26, Color(0.8, 0.65, 0.2), Vector3(0, 0, 0))


func stair_spawn() -> Vector3:
	return _p(2.0, -82.0, 0.3)


func on_spawn(cp: String) -> void:
	if cp == "caves_gate" and Game.has_flag("gallery_entered"):
		_activate_listener()
	if Game.has_flag("seal_open"):
		_seal._set_open_instant()


func _process(delta: float) -> void:
	_bell_caption_cd = max(_bell_caption_cd - delta, 0.0)
	if level.space == "caves" and level.player.recorder.listening and _bell_caption_cd <= 0.0:
		if level.player.global_position.distance_to(_p(BELL.x, BELL.y)) < 6.0:
			_bell_caption_cd = 14.0
			Sound.say("[the bell is ringing, under the water. It isn't moving.]", "hint", 4.0)
