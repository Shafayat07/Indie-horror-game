extends Node3D
## BLACKWOOD FOREST + THE OLD RADIO TOWER + THE ROOST (optional chapter).
## Kell's hut at the tower holds his diaries and the floodlight switch. His
## roost is a cave in the rock outcrop to the north-west; he sleeps there and
## hunts the woods for ten minutes after the bell strikes each hour. His nest
## holds the third part of the last recording — take it and he hunts you
## until the tower floodlight burns him out of the sky.

const TOWER := Vector3(-64, 0, 36)
const HUT := Vector3(-57, 0, 33)
const MOUTH := Vector3(-72, 0, 61)
const O := Vector3(0, -200, 220)   # must match island.ROOST_ORIGIN

var level: Node
var kell: Node3D
var floodlight_on := false
var _flood: SpotLight3D
var _flood_glow: MeshInstance3D


func build(lv: Node) -> void:
	level = lv
	add_to_group("navsrc_surface")
	level.checkpoints["forest"] = [HUT + Vector3(4.5, Terrain.height(HUT.x + 4.5, HUT.z) + 0.2, 0), 90.0, "surface"]
	level.checkpoints["roost"] = [O + Vector3(0, 0.3, -2.0), 0.0, "roost"]
	level.checkpoints["kell_chase"] = [MOUTH + Vector3(1, Terrain.height(MOUTH.x + 1, MOUTH.z - 4) + 0.3, -4), -30.0, "surface"]
	_trees()
	_tower_and_hut()
	_outcrop()
	_roost()
	_remains()
	Zone.make(self, Vector3(-62, 6, 47), Vector3(64, 16, 64), {"ambience": "forest", "on_enter": func(_b):
		level.chapter("ch_forest")
		if not Game.has_flag("forest_line"):
			Game.set_flag("forest_line")
			level.hud.elias("forest", 2.0)})
	kell = preload("res://scripts/enemy/kell.gd").new()
	kell.name = "Kell"
	add_child(kell)
	kell.setup(level, self)
	Sound.noise_emitted.connect(_on_noise)


func roost_hang_point() -> Vector3:
	return O + Vector3(0, 6.2, -18)


func roost_mouth() -> Vector3:
	return MOUTH + Vector3(0, Terrain.height(MOUTH.x, MOUTH.z), 0)


func floodlight_target() -> Vector3:
	return TOWER + Vector3(0, Terrain.height(TOWER.x, TOWER.z), 0)


func _g(x: float, z: float) -> float:
	return Terrain.height(x, z)


# ------------------------------------------------------------------ trees
func _trees() -> void:
	var meshes := Models.meshes("res://assets/models/trees.glb")
	var kinds := [["Pine0_trunk", "Pine0_foliage"], ["Pine1_trunk", "Pine1_foliage"], ["Pine2_trunk", "Pine2_foliage"], ["Dead0"], ["Dead1"]]
	var xforms := {}
	for k in kinds:
		xforms[k[0]] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var placed := 0
	var tries := 0
	while placed < 190 and tries < 3000:
		tries += 1
		var x := rng.randf_range(-100, -28)
		var z := rng.randf_range(16, 82)
		var h := _g(x, z)
		if h < 1.8 or Terrain.path_weight(x, z).x > 0.05:
			continue
		if Vector2(x, z).distance_to(Vector2(TOWER.x, TOWER.z)) < 13 or Vector2(x, z).distance_to(Vector2(MOUTH.x, MOUTH.z)) < 9 or x < -88:
			continue
		if x > -34 and z < 30:
			continue
		var k: Array = kinds[rng.randi() % kinds.size()] if rng.randf() < 0.8 else kinds[3 + rng.randi() % 2]
		var s := rng.randf_range(0.8, 1.35)
		var xf := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * s), Vector3(x, h - 0.2, z))
		xforms[k[0]].append(xf)
		var sb := StaticBody3D.new()
		sb.collision_layer = B.LAYER_WORLD
		sb.set_meta("surface", "grass")
		var cs := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.3 * s
		cyl.height = 5.0
		cs.shape = cyl
		sb.add_child(cs)
		add_child(sb)
		sb.position = Vector3(x, h + 2.3, z)
		placed += 1
	for k in kinds:
		for part in k:
			if not meshes.has(part):
				continue
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = meshes[part]
			var list: Array = xforms[k[0]]
			mm.instance_count = list.size()
			for i in list.size():
				mm.set_instance_transform(i, list[i])
			var mmi := MultiMeshInstance3D.new()
			mmi.multimesh = mm
			add_child(mmi)
	var notice_pos := Vector3(-33, _g(-33, 47) + 1.5, 47)
	B.box(self, notice_pos + Vector3(0, -0.6, -0.1), Vector3(0.15, 2.6, 0.15), B.mat("wood_dark", Color.WHITE, 1.0), {})
	P.note(self, notice_pos, "woods_notice", 90, true)
	_missing(Vector3(-34.5, 0, 50.5))
	_shelter(HUT + Vector3(7.0, 0, -9.0))


func _missing(at: Vector3) -> void:
	var pos := at + Vector3(0, _g(at.x, at.z), 0)
	var post := B.mat("wood_dark", Color.WHITE, 1.0)
	B.box(self, pos + Vector3(0, 1.0, 0), Vector3(0.12, 2.0, 0.12), post, {})
	B.box(self, pos + Vector3(0, 1.45, 0.07), Vector3(0.9, 0.8, 0.04), post, {"collide": false})
	var rng := RandomNumberGenerator.new()
	rng.seed = 71
	for i in 7:
		var paper := B.box(self, pos + Vector3(rng.randf_range(-0.32, 0.32), rng.randf_range(1.15, 1.75), 0.1 + i * 0.002), Vector3(0.2, 0.26, 0.005), B.flat(Color(0.78, 0.75, 0.66), 0.9), {"collide": false})
		paper.rotation_degrees.z = rng.randf_range(-12, 12)
	P.examine(self, pos + Vector3(0, 1.45, 0.3), Vector3(1.0, 0.9, 0.4), "missing_board")
	P.note(self, pos + Vector3(0.0, 0.05, 0.6), "missing_notice", 30)


func _shelter(at: Vector3) -> void:
	var pos := at + Vector3(0, _g(at.x, at.z), 0)
	var wood := B.mat("wood_dark", Color(0.8, 0.75, 0.7), 1.0)
	var roof := B.box(self, pos + Vector3(0, 0.9, 0), Vector3(2.2, 0.06, 2.0), B.mat("rope", Color(0.5, 0.45, 0.35), 2.0), {"collide": false})
	roof.rotation_degrees.x = 35
	for x in [-1.0, 1.0]:
		B.box(self, pos + Vector3(x, 0.65, -0.55), Vector3(0.08, 1.3, 0.08), wood, {})
	B.box(self, pos + Vector3(0, 0.05, -0.1), Vector3(0.8, 0.1, 1.6), B.flat(Color(0.25, 0.28, 0.22), 0.9), {"collide": false})
	P.examine(self, pos + Vector3(0, 0.5, 0), Vector3(1.8, 1.0, 1.6), "shelter")
	P.note(self, pos + Vector3(0.6, 0.12, 0.5), "shelter_note", 40)


# ------------------------------------------------------------------ tower & hut
func _tower_and_hut() -> void:
	var base := TOWER + Vector3(0, _g(TOWER.x, TOWER.z), 0)
	var m := B.mat("metal_rust", Color(0.7, 0.7, 0.7), 1.0, {"metallic": 0.4})
	for i in 8:
		var y := 1.5 + i * 3.0
		var w := 2.2 - i * 0.22
		for c in [Vector3(-1, 0, -1), Vector3(1, 0, -1), Vector3(-1, 0, 1), Vector3(1, 0, 1)]:
			B.box(self, base + c * w * 0.5 + Vector3(0, y, 0), Vector3(0.1, 3.0, 0.1), m, {"collide": i == 0})
		B.box(self, base + Vector3(0, y + 1.5, 0), Vector3(w, 0.08, w), m, {"collide": false})
	B.label(self, base + Vector3(0, 3.0, 1.15), "VEY RELAY 2 — T. KELL", 30, Color(0.8, 0.75, 0.6))
	# the floodlight at the top, aimed down into the clearing
	_flood_glow = B.box(self, base + Vector3(0, 25.2, 0), Vector3(0.9, 0.6, 0.9), B.flat(Color(0.2, 0.2, 0.18), 0.4), {"collide": false})
	_flood = B.spot(self, base + Vector3(0, 25.0, 0), Color(1.0, 0.97, 0.88), 0.0, 40.0, 38.0, Vector3(-90, 0, 0), true)
	# Kell's hut
	var hb := HUT + Vector3(0, _g(HUT.x, HUT.z), 0)
	var r := B.room(self, hb, Vector3(5, 2.6, 4), {"wall": B.mat("wood_planks", Color(0.6, 0.55, 0.5), 0.6),
		"outer": B.mat("wood_dark", Color(0.8, 0.8, 0.8), 0.5), "openings": [{"side": "e", "at": 0.5, "w": 1.0, "h": 2.1}], "roof": true})
	Door.make(r, Vector3(2.6, 0, 0.5), 90, {"id": "kell_hut"})
	B.ring_mark(r, Vector3(2.75, 1.7, -0.4), 90)
	Zone.make(r, Vector3(0, 1.3, 0), Vector3(4.8, 2.4, 3.8), {"ambience": "interior", "safe": true, "reverb": 0.12, "on_enter": func(_b):
		if not Game.has_flag("cabin_line"):
			Game.set_flag("cabin_line")
			level.hud.elias("cabin", 0.5)})
	B.omni(r, Vector3(0, 2.2, 0), Color(0.9, 0.7, 0.45), 0.6, 6.0, true)
	P.table(r, Vector3(-1.4, 0, -1.3), 0, Vector2(1.6, 0.7))
	P.radio_set(r, Vector3(-1.9, 0.8, -1.4), 0, true)
	P.examine(r, Vector3(-1.9, 1.0, -1.3), Vector3(0.6, 0.4, 0.5), "cabin_radio")
	var d1 := P.note(r, Vector3(-0.9, 0.8, -1.3), "kell_diary_1", 15)
	d1.used.connect(func(_p): Game.set_flag("read_kell"))
	P.note(r, Vector3(-0.4, 0.8, -1.2), "kell_diary_2", -10)
	P.bed(r, Vector3(1.4, 0, -1.0), 0)
	B.box(r, Vector3(-2.45, 1.5, 0.8), Vector3(0.04, 0.8, 0.6), B.flat(Color(0.01, 0.01, 0.01), 0.1, 0.4), {"collide": false})
	P.examine(r, Vector3(-2.3, 1.5, 0.8), Vector3(0.3, 0.8, 0.7), "cabin_mirror")
	for i in 40:  # tally marks: hours, counted by the bell
		B.box(r, Vector3(-1.0 + (i % 20) * 0.1, 1.2 + (i / 20) * 0.45, 1.88), Vector3(0.015, 0.3, 0.01), B.flat(Color(0.1, 0.08, 0.06)), {"collide": false})
	var sw := Interactable.make(r, Vector3(2.3, 1.3, -1.6), Vector3(0.4, 0.5, 0.3), "Throw the floodlight switch")
	B.box(r, Vector3(2.4, 1.3, -1.6), Vector3(0.1, 0.4, 0.3), B.mat("metal_red", Color.WHITE, 2.0), {"collide": false})
	sw.used.connect(func(_p):
		if floodlight_on:
			return
		Sound.play_2d("switch_clunk", 0.0)
		_set_flood(true)
		if not Game.has_flag("kell_chase"):
			level.hud.toast("The floodlight blazes over the clearing. Nothing moves in it.", 3.5))


func _set_flood(on: bool) -> void:
	floodlight_on = on
	_flood.light_energy = 9.0 if on else 0.0
	_flood_glow.material_override = B.glow(Color(1.0, 0.97, 0.85), 8.0) if on else B.flat(Color(0.2, 0.2, 0.18))


# ------------------------------------------------------------------ the outcrop and the Roost below it
func _outcrop() -> void:
	var c := roost_mouth()
	var rock := B.mat("cliff", Color(0.8, 0.8, 0.8), 0.3)
	# the mouth faces north-east, toward the path from the radio tower
	for spec in [[Vector3(-3.4, 2.5, 1), Vector3(2.6, 5, 3)], [Vector3(3.4, 2.4, 1), Vector3(2.6, 5, 3)], [Vector3(0, 5.6, 1.6), Vector3(5, 2.2, 3)],
			[Vector3(-7, 3.5, 4), Vector3(5, 7, 5)], [Vector3(7, 3.5, 4), Vector3(5, 7, 5)], [Vector3(0, 5, 7), Vector3(9, 8, 5)]]:
		B.rock(self, c + spec[0], spec[1], randi() % 5, rock, true, randf() * TAU)
	var dark := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(4.5, 4.5)
	dark.mesh = qm
	dark.material_override = B.flat(Color(0, 0, 0), 1.0)
	add_child(dark)
	dark.position = c + Vector3(0, 2.1, 1.4)
	dark.rotation_degrees.y = 180
	B.collider(self, c + Vector3(0, 2.0, 1.8), Vector3(4.5, 4.5, 0.4))
	for i in 6:
		B.box(self, c + Vector3(randf_range(-2, 2), 0.05, randf_range(-3, 0)), Vector3(0.05, 0.02, 0.3), B.flat(Color(0.85, 0.82, 0.75)), {"collide": false})
	Zone.make(self, c + Vector3(0, 1.5, 0.6), Vector3(3.5, 3, 1.2), {"on_enter": func(_b):
		level.chapter("ch_forest")
		var cp: Array = level.checkpoints["roost"]
		level.travel(cp[0], cp[1], "roost", "caves")})


func _roost() -> void:
	var rock := B.mat("rock_cave", Color(1.3, 1.3, 1.3), 0.4)
	B.cyl(self, O + Vector3(0, -0.25, -12), 12.0, 0.5, rock, {"segments": 20, "surface": "stone"})
	# tunnel walls, then a ring of boulders around the roost chamber
	for z in range(0, -9, -2):
		for sx in [-1, 1]:
			B.rock(self, O + Vector3(sx * 2.6, 1.5, z), Vector3(1.6, 3.2, 1.6), (z + sx) % 5, rock, true, randf() * TAU)
	for i in 18:
		var a := TAU * i / 18.0
		if abs(wrapf(a, -PI, PI)) < 0.35:
			continue
		var p := O + Vector3(0, 0, -18) + Vector3(sin(a), 0, cos(a)) * 9.5
		B.rock(self, p + Vector3(0, 2.5, 0), Vector3(2.6, 5.5, 2.6), i % 5, rock, true, randf() * TAU)
	var dome := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 11.0
	sm.height = 16.0
	sm.flip_faces = true
	dome.mesh = sm
	dome.material_override = rock
	add_child(dome)
	dome.position = O + Vector3(0, 0, -16)
	B.omni(self, O + Vector3(0, 1.5, -1), Color(0.45, 0.55, 0.75), 0.8, 7.0)
	B.omni(self, O + Vector3(-5, 1.0, -22), Color(0.3, 0.7, 0.65), 0.6, 7.0)
	# the nest: gull bones, rope, radio valves, his tape
	var nest := O + Vector3(0, 0, -25)
	P.net_pile(self, nest)
	for i in 14:
		B.box(self, nest + Vector3(randf_range(-1.5, 1.5), 0.08, randf_range(-1.2, 1.2)), Vector3(0.04, 0.03, randf_range(0.15, 0.35)), B.flat(Color(0.8, 0.77, 0.68)), {"collide": false}).rotation.y = randf() * TAU
	P.corpse(self, nest + Vector3(2.2, 0, 0.5), 40, "lie")
	var tape := B.box(self, nest + Vector3(0, 0.45, 0), Vector3(0.18, 0.04, 0.12), B.flat(Color(0.1, 0.1, 0.1), 0.4), {"collide": false})
	var take := Interactable.make(self, nest + Vector3(0, 0.5, 0), Vector3(0.8, 0.5, 0.8), "Take Kell's tape")
	take.used.connect(func(p):
		if Game.has_recording("kell_tape"):
			return
		Game.add_recording("kell_tape", tape.global_position)
		tape.visible = false
		Sound.play_2d("pickup", -4.0)
		p.hud.toast("Recorded: " + Story.RECORDINGS["kell_tape"].name)
		Sound.say(Story.RECORDINGS["kell_tape"].caption, "radio", 5.0)
		kell.wake_for_chase())
	if Game.has_recording("kell_tape"):
		tape.visible = false
	var out := Interactable.make(self, O + Vector3(0, 1.2, 1.2), Vector3(3, 2.4, 1), "Climb back out")
	out.used.connect(func(_p):
		var c := roost_mouth() + Vector3(1, 0.3, -4)
		level.travel(c, -30.0, "surface", "forest"))
	Zone.make(self, O + Vector3(0, 2, -14), Vector3(22, 8, 30), {"ambience": "caves", "reverb": 0.4, "on_enter": func(_b):
		if not Game.has_flag("roost_line") and kell.state == kell.S.ROOST:
			Game.set_flag("roost_line")
			level.hud.elias("roost", 1.0)})


func _on_noise(pos: Vector3, radius: float, _kind: String) -> void:
	if level.space == "roost" and kell and pos.distance_to(kell.global_position) < radius + 4.0:
		kell.roost_noise(radius)


# ------------------------------------------------------------------ remains and silhouettes
func _remains() -> void:
	for spot in [Vector3(-44, 0, 52), Vector3(-52, 0, 62), Vector3(-80, 0, 40)]:
		var g := _g(spot.x, spot.z)
		P.corpse(self, spot + Vector3(0, g + 1.6, 0), randf() * 360.0, "hung", true)
		B.box(self, spot + Vector3(0, g + 4.2, 0), Vector3(0.04, 1.6, 0.04), B.mat("rope", Color.WHITE, 2.0), {"collide": false})
		P.blood(self, spot + Vector3(0, g, 0), Vector2(1.2, 1.0))
		P.examine(self, spot + Vector3(0, g + 1.6, 0), Vector3(0.8, 2.0, 0.8), "forest_remains")
	for spot in [Vector3(-48, 0, 40), Vector3(-70, 0, 50), Vector3(-58, 0, 70), Vector3(-40, 0, 64)]:
		level.horror.apparition(spot + Vector3(0, _g(spot.x, spot.z), 0), 0.0, {"kind": "listener", "range": 40.0, "scare": true, "sting": 2, "once": false})
