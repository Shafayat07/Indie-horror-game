extends Node3D
## LOCATION B — THE ABANDONED SETTLEMENT.
## Lit windows with no power, a teahouse radio that announces a conversation
## you then overhear from the blue house, the backwards clock holding the
## station key, wet footprints that stop at a door, the motionless bell — and
## The Listener's first patrol. Also the wall and gate that close off the
## lighthouse road until the endings.

var level: Node
var silhouette: Node3D
var _sil_lamp: OmniLight3D
var clock_hands: Array[Node3D] = []
var bell: Node3D
var _plank := B.mat("wood_planks", Color(0.62, 0.62, 0.6), 0.5)
var _plaster := B.mat("plaster_white", Color(0.62, 0.63, 0.62), 0.5)

const PATROL := [Vector3(-2, 4.4, 27), Vector3(4, 4.2, 47), Vector3(-3, 4.2, 58), Vector3(-15, 4.2, 42), Vector3(2, 4.3, 33), Vector3(-12, 4.4, 20)]


func build(lv: Node) -> void:
	level = lv
	add_to_group("navsrc_surface")
	level.checkpoints["settlement"] = [Vector3(0, 4.0, 62), 180.0, "surface"]
	level.checkpoints["settlement_key"] = [Vector3(9.5, 4.3, 39.5), -90.0, "surface"]
	Zone.make(self, Vector3(0, 6, 40), Vector3(50, 12, 46), {"ambience": "settlement"})
	_teahouse()
	_blue_house()
	_office()
	_collapsed()
	_square()
	_lighthouse_wall()
	_dressing()


func _house(center: Vector3, size: Vector3, door_side: String, door_at: float, outer: Material, windows: Array, lit: bool) -> Node3D:
	var openings := [{"side": door_side, "at": door_at, "w": 1.0, "h": 2.1}]
	for w in windows:
		openings.append({"side": w[0], "at": w[1], "w": 0.9, "h": 0.9, "sill": 1.0})
	var r := B.room(self, center, size, {"wall": B.mat("wallpaper", Color.WHITE, 0.6), "outer": outer,
		"openings": openings, "roof": true, "floor": B.mat("wood_planks", Color(0.7, 0.66, 0.6), 0.6)})
	for w in windows:
		var side: String = w[0]
		var at: float = w[1]
		var p := Vector3.ZERO
		var yaw := 0.0
		match side:
			"n": p = Vector3(at, 1.45, -size.z * 0.5 - 0.12); yaw = 180
			"s": p = Vector3(at, 1.45, size.z * 0.5 + 0.12); yaw = 0
			"e": p = Vector3(size.x * 0.5 + 0.12, 1.45, at); yaw = 90
			"w": p = Vector3(-size.x * 0.5 - 0.12, 1.45, at); yaw = -90
		if lit:
			B.window_glow(r, p, Vector2(0.9, 0.9), yaw, Color(1.0, 0.6, 0.28), 1.4)
		else:
			B.box(r, p, Vector3(0.9, 0.9, 0.02) if side in ["n", "s"] else Vector3(0.02, 0.9, 0.9), B.glass(Color(0.2, 0.25, 0.3, 0.5)), {"collide": false})
	return r


func _door_pos(size: Vector3, side: String, at: float) -> Array:
	match side:
		"e": return [Vector3(size.x * 0.5 + 0.1, 0, at), 90.0]
		"w": return [Vector3(-size.x * 0.5 - 0.1, 0, at), -90.0]
		"n": return [Vector3(at, 0, -size.z * 0.5 - 0.1), 0.0]
	return [Vector3(at, 0, size.z * 0.5 + 0.1), 180.0]


# ------------------------------------------------------------------ buildings
func _teahouse() -> void:
	var size := Vector3(6, 2.8, 5)
	var r := _house(Vector3(-9, 4.2, 50), size, "e", 1.0, _plank, [["e", -1.4], ["s", 0.0], ["n", 1.5]], true)
	var d := _door_pos(size, "e", 1.0)
	Door.make(r, d[0], d[1], {"id": "teahouse"})
	B.omni(r, Vector3(0, 2.3, 0), Color(1.0, 0.62, 0.32), 1.0, 7.0, true)
	# the tea, still steaming, and the chair turned to face the wall
	P.table(r, Vector3(0.3, 0, -0.6), 0, Vector2(1.2, 0.8))
	var cup := B.cyl(r, Vector3(0.1, 0.83, -0.5), 0.045, 0.09, B.flat(Color(0.8, 0.78, 0.72), 0.3), {"collide": false})
	var steam := CPUParticles3D.new()
	steam.amount = 10
	steam.lifetime = 2.5
	steam.gravity = Vector3(0, 0.15, 0)
	steam.initial_velocity_min = 0.05
	steam.initial_velocity_max = 0.1
	steam.scale_amount_min = 0.03
	steam.scale_amount_max = 0.08
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	steam.mesh = sm
	var stm := StandardMaterial3D.new()
	stm.albedo_color = Color(0.8, 0.8, 0.8, 0.08)
	stm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	stm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	steam.material_override = stm
	cup.add_child(steam)
	steam.position.y = 0.06
	P.chair(r, Vector3(-2.3, 0, -1.6), 180)   # facing the wall
	P.chair(r, Vector3(0.9, 0, 0.1), 200)
	P.shelf(r, Vector3(2.75, 0, -1.6), -90, 1.2)
	P.stove(r, Vector3(-2.4, 0, 1.7), 0)
	P.note(r, Vector3(0.6, 0.8, -0.75), "tea_room", -15)
	var radio := P.radio_set(r, Vector3(-0.2, 0.8, -0.85), 0)
	var radio_pos: Vector3 = radio.global_position
	Sound.attach_loop(radio, "amb_static", -16.0, {"unit_size": 2.0, "max_distance": 14.0})
	Zone.make(r, Vector3(0, 1.3, 0), Vector3(5.8, 2.5, 4.8), {"ambience": "interior", "reverb": 0.15})
	Zone.make(r, Vector3(0, 1.3, 0), Vector3(5.8, 2.5, 4.8), {"once": true, "block": "heard_teahouse", "on_enter": func(_b): _teahouse_radio(radio_pos)})
	# three knocks from inside the west wall (there's nothing behind it)
	Recordable.make(r, Vector3(-3.1, 1.4, 0.5), "knocks", "knock3", {"radius": 5.0, "interval": 11.0, "volume": -2.0, "unit_size": 3.0})


func _teahouse_radio(radio_pos: Vector3) -> void:
	Game.set_flag("heard_teahouse")
	Sound.play_at("radio_burst", radio_pos, -4.0)
	await get_tree().create_timer(0.6).timeout
	Sound.play_at("radio_voice_b", radio_pos, -6.0, {"bus": "Voice", "unit_size": 2.5})
	level.hud.radio("teahouse")
	await get_tree().create_timer(5.0).timeout
	Sound.play_at("radio_voice_a", radio_pos, -6.0, {"bus": "Voice", "unit_size": 2.5})
	await get_tree().create_timer(8.0).timeout
	# ...and moments later, the same conversation from the blue house across the path
	Sound.pre_echo("radio_voice_a", Vector3(9, 5.5, 40), "", 2.0)
	level.hud.radio("teahouse_echo")


func _blue_house() -> void:
	var size := Vector3(6, 2.8, 5)
	var r := _house(Vector3(9, 4.2, 40), size, "w", -0.5, B.mat("wood_planks", Color(0.42, 0.52, 0.62), 0.5), [["w", 1.6], ["n", 0.0]], false)
	var d := _door_pos(size, "w", -0.5)
	Door.make(r, d[0], d[1], {"id": "bluehouse"})
	B.ring_mark(r, Vector3(-size.x * 0.5 - 0.22, 1.7, -1.4), -90)
	P.note(r, Vector3(-size.x * 0.5 - 0.25, 1.4, -1.45), "safe_ring", -90, true)
	B.omni(r, Vector3(0.5, 2.2, 0.5), Color(0.95, 0.75, 0.5), 0.7, 6.0, true)
	P.bed(r, Vector3(2.3, 0, 1.2), 90)
	P.table(r, Vector3(-0.6, 0, 1.5), 0, Vector2(1.0, 0.7))
	P.chair(r, Vector3(-0.6, 0, 0.9), 180)
	P.note(r, Vector3(-0.6, 0.8, 1.5), "child_drawing", 10)
	P.stove(r, Vector3(2.5, 0, -1.9), 0)
	Zone.make(r, Vector3(0, 1.3, 0), Vector3(5.8, 2.5, 4.8), {"ambience": "interior", "safe": true, "reverb": 0.15})
	# the clock that runs backwards, holding the station key
	var clock := Node3D.new()
	r.add_child(clock)
	clock.position = Vector3(1.0, 0, -2.3)
	var cm := B.mat("wood_dark", Color(1.3, 1.1, 0.9), 1.5)
	B.box(clock, Vector3(0, 1.0, 0), Vector3(0.5, 2.0, 0.3), cm, {})
	B.cyl(clock, Vector3(0, 1.65, 0.16), 0.2, 0.02, B.flat(Color(0.82, 0.78, 0.68), 0.6), {"collide": false, "rot": Vector3(90, 0, 0)})
	for i in 2:
		var h := Node3D.new()
		clock.add_child(h)
		h.position = Vector3(0, 1.65, 0.18)
		B.box(h, Vector3(0, 0.08 - i * 0.02, 0), Vector3(0.015, 0.16 - i * 0.04, 0.01), B.flat(Color(0.05, 0.05, 0.05)), {"collide": false})
		clock_hands.append(h)
	B.box(clock, Vector3(0, 0.7, 0.16), Vector3(0.3, 0.6, 0.01), B.glass(Color(0.3, 0.3, 0.25, 0.4)), {"collide": false})
	var tick := Sound.attach_loop(clock, "ui_click", -18.0, {"unit_size": 1.5, "max_distance": 8.0, "autoplay": false})
	var t := Timer.new()
	t.wait_time = 1.0
	t.autostart = true
	clock.add_child(t)
	t.timeout.connect(func():
		tick.pitch_scale = 0.6
		tick.play())
	var it := Interactable.make(clock, Vector3(0, 1.0, 0.25), Vector3(0.6, 1.8, 0.3), "Open the clock case")
	it.used.connect(func(p):
		if Game.has_flag("has_station_key"):
			p.hud.toast("The case is empty. The hands keep turning back.")
			return
		Game.set_flag("has_station_key")
		Sound.play_2d("pickup", -4.0)
		p.hud.open_note("wren_key")
		p.hud.toast("Took the weather station key.")
		level.objective("reach_station")
		level.checkpoint("settlement_key")
		_after_key())
	# wet footprints from the path to this door — and none inside
	var fm := B.flat(Color(0.02, 0.025, 0.03), 0.05)
	for i in 9:
		var fp := Vector3(-1.5 - i * 0.9, 0.0, 1.0 - i * 0.18 + (0.12 if i % 2 else -0.12))
		var gp: Vector3 = r.to_global(Vector3(-size.x * 0.5, 0, 0) + fp)
		var mi := B.box(self, Vector3(gp.x, Terrain.height(gp.x, gp.z) + 0.02, gp.z), Vector3(0.13, 0.01, 0.28), fm, {"collide": false})
		mi.rotation_degrees.y = -100


func _office() -> void:
	var size := Vector3(5, 2.7, 4)
	var r := _house(Vector3(-9, 4.2, 34), size, "e", 0.6, _plaster, [["e", -1.2], ["n", 0.8]], true)
	var d := _door_pos(size, "e", 0.6)
	Door.make(r, d[0], d[1], {"id": "office"})
	B.omni(r, Vector3(0, 2.2, 0), Color(1.0, 0.62, 0.3), 0.8, 6.0)
	P.table(r, Vector3(-0.8, 0, -1.0), 0, Vector2(1.6, 0.8))
	P.chair(r, Vector3(-0.8, 0, -0.4), 180)
	P.shelf(r, Vector3(-2.3, 0, 0.6), 90, 1.4)
	P.note(r, Vector3(-0.6, 0.8, -1.1), "marrow_echo", 5)
	P.radio_set(r, Vector3(-1.4, 0.8, -1.2), 0, false)
	B.label(r, Vector3(size.x * 0.5 + 0.24, 2.35, 0.6), "HARBOURMASTER", 30, Color(0.8, 0.75, 0.6), Vector3(0, 90, 0))
	Zone.make(r, Vector3(0, 1.3, 0), Vector3(4.8, 2.4, 3.8), {"ambience": "interior", "reverb": 0.12})


func _collapsed() -> void:
	var c := Vector3(11, 4.2, 55)
	var m := B.mat("wood_planks", Color(0.5, 0.48, 0.45), 0.5)
	B.box(self, c + Vector3(0, -0.2, 0), Vector3(6.4, 0.4, 5.4), m, {"surface": "wood"})
	B.box(self, c + Vector3(0, 1.4, -2.6), Vector3(6.4, 2.8, 0.2), m, {})
	B.box(self, c + Vector3(-3.1, 1.0, 0), Vector3(0.2, 2.0, 5.2), m, {})
	B.box(self, c + Vector3(3.1, 0.6, 1.2), Vector3(0.2, 1.2, 2.8), m, {})
	var roof := B.box(self, c + Vector3(0.5, 1.3, 0.4), Vector3(6.8, 0.15, 4.0), B.mat("roof", Color.WHITE, 0.5), {})
	roof.rotation_degrees = Vector3(18, 5, -14)
	B.window_glow(self, c + Vector3(-1.5, 1.5, -2.72), Vector2(0.9, 0.8), 180, Color(1.0, 0.6, 0.28), 1.2)
	for i in 6:
		P.crate(self, c + Vector3(randf_range(-2, 2), 0, randf_range(-1.5, 2)), randf() * 90, randf_range(0.3, 0.6))


func _square() -> void:
	# bell frame — the bell never moves, even when you hear it ring
	var g := Terrain.height(-4, 26)
	bell = Node3D.new()
	add_child(bell)
	bell.position = Vector3(-4, g, 26)
	var post := B.mat("wood_dark", Color(0.8, 0.8, 0.8), 0.6)
	for sx in [-1, 1]:
		B.box(bell, Vector3(sx * 1.0, 1.7, 0), Vector3(0.2, 3.4, 0.2), post, {"surface": "wood"})
	B.box(bell, Vector3(0, 3.35, 0), Vector3(2.4, 0.22, 0.25), post, {"collide": false})
	B.cyl(bell, Vector3(0, 2.75, 0), 0.38, 0.6, B.mat("metal_green", Color(0.7, 0.8, 0.7), 1.0, {"metallic": 0.6}), {"collide": false, "top": 0.2})
	P.lamp_post(self, Vector3(3, Terrain.height(3, 30), 30), Color(1.0, 0.6, 0.3), 1.4)
	P.lamp_post(self, Vector3(-2.5, Terrain.height(-2.5, 52), 52), Color(1.0, 0.6, 0.3), 1.2)
	# junction sign
	var sg := Terrain.height(3, 19)
	B.box(self, Vector3(3, sg + 1.1, 19), Vector3(0.12, 2.2, 0.12), post, {})
	var signs := [["WEATHER STATION", -90.0, Vector3(-0.6, 1.9, 0)], ["CLIFF PATH", 90.0, Vector3(0.6, 1.6, 0)], ["LIGHTHOUSE", 0.0, Vector3(0, 2.15, -0.3)]]
	for s in signs:
		var board := Node3D.new()
		add_child(board)
		board.position = Vector3(3, sg, 19) + s[2]
		board.rotation_degrees.y = s[1]
		B.box(board, Vector3.ZERO, Vector3(0.05, 0.22, 1.1), B.mat("wood_planks", Color(0.8, 0.78, 0.72), 1.0), {"collide": false})
		B.label(board, Vector3(0.04, 0, 0), s[0], 24, Color(0.15, 0.12, 0.1), Vector3(0, 90, 0))
	# the first glimpse: something standing on the lighthouse road, under a lamp
	_sil_lamp = P.lamp_post(self, Vector3(1.6, Terrain.height(1.6, -2), -2), Color(1.0, 0.55, 0.28), 2.2, false)
	silhouette = Node3D.new()
	silhouette.set_script(preload("res://scripts/enemy/listener_model.gd"))
	add_child(silhouette)
	silhouette.position = Vector3(0.4, Terrain.height(0.4, -3.5), -3.5)
	silhouette.rotation_degrees.y = 0
	silhouette.visible = false


func _lighthouse_wall() -> void:
	## Old stone wall across the headland. Its gate is chained from the far side.
	var m := B.mat("stone_wet", Color(0.9, 0.9, 0.9), 0.4)
	var z := -38.0
	var x := -100.0
	while x < 55.0:
		if abs(x) > 1.6:
			var g := Terrain.height(x, z)
			B.box(self, Vector3(x, g + 0.6, z), Vector3(4.1, 2.8, 0.8), m, {"surface": "stone"})
		x += 4.0
	var gate_g := Terrain.height(0, z)
	var gm := B.mat("metal_rust", Color(0.6, 0.6, 0.6), 1.0, {"metallic": 0.5})
	var gate := Door.make(self, Vector3(0, gate_g, z), 0, {"id": "lh_gate", "w": 3.0, "h": 2.2, "mat": gm, "lock": "gate_unchained",
		"locked_text": "Chained shut from the other side.", "noise": 14.0})
	var chain := Interactable.make(self, Vector3(0, gate_g + 1.1, z - 0.6), Vector3(3.0, 1.0, 0.3), "Unhook the chain")
	chain.once = true
	chain.used.connect(func(p):
		Game.set_flag("gate_unchained")
		Sound.play_at("door_locked", chain.global_position, 0.0)
		p.hud.toast("The chain drops into the grass."))
	if Game.has_flag("gate_unchained"):
		chain.queue_free()
	B.label(self, Vector3(0, gate_g + 2.6, z + 0.45), "VEY LIGHT — NO ACCESS", 30, Color(0.7, 0.68, 0.6))


func _dressing() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	# fence posts along the path, rusted tools, a washing line
	var post := B.mat("wood_dark", Color(0.7, 0.7, 0.7), 0.8)
	for z in range(24, 62, 3):
		for x in [-3.2, 3.2]:
			if rng.randf() < 0.75:
				var g := Terrain.height(x, z)
				var p := B.box(self, Vector3(x, g + 0.5, z), Vector3(0.12, 1.0, 0.12), post, {})
				p.rotation_degrees.z = rng.randf_range(-12, 12)
	for i in 8:
		var x := rng.randf_range(-20, 20)
		var z := rng.randf_range(22, 62)
		if abs(x) < 4.0:
			continue
		var g := Terrain.height(x, z)
		if rng.randf() < 0.5:
			P.barrel(self, Vector3(x, g, z), Color(0.35, 0.33, 0.3))
		else:
			P.crate(self, Vector3(x, g, z), rng.randf() * 90.0)
	var rope_m := B.mat("rope", Color(1, 1, 1), 2.0)
	B.box(self, Vector3(-16, 6.0, 44), Vector3(0.03, 0.03, 8), rope_m, {"collide": false})
	for z in [40.5, 42.0, 45.0]:
		var cloth := B.box(self, Vector3(-16, 5.5, z), Vector3(0.02, 0.9, 0.7), B.flat(Color(0.55, 0.55, 0.5), 0.9), {"collide": false})
		cloth.rotation_degrees.x = rng.randf_range(-8, 8)
	for zz in [40.0, 48.0]:
		B.box(self, Vector3(-16, Terrain.height(-16, zz) + 3.0 * 0.5 + 0.5, zz), Vector3(0.1, 2.6, 0.1), post, {})
	# rocks scattered around the edges
	var rock_m := B.mat("stone_wet", Color.WHITE, 0.35)
	for i in 30:
		var x := rng.randf_range(-45, 45)
		var z := rng.randf_range(-35, 70)
		if Terrain.path_weight(x, z).x > 0.1 or (abs(x) < 22 and z > 18 and z < 64) or (x < -30 and z > -32 and z < 16):
			continue
		B.rock(self, Vector3(x, Terrain.height(x, z) - 0.2, z), Vector3.ONE * rng.randf_range(0.5, 1.8), i, rock_m, true, rng.randf() * TAU)


# ------------------------------------------------------------------ events
func on_spawn(cp: String) -> void:
	Zone.make(self, Vector3(0, 6, 62), Vector3(8, 6, 3), {"once": true, "block": "entered_settlement", "on_enter": func(_b): _enter()})
	Zone.make(self, Vector3(0, 6, 24), Vector3(12, 6, 6), {"once": true, "require": "chose_send", "on_enter": func(_b):
		Sound.pre_echo("radio_voice_elias", Vector3(-9, 5.2, 50), "[every radio in Vey is playing your voice]", 2.0)
		await get_tree().create_timer(4.0).timeout
		Sound.pre_echo("radio_voice_elias", Vector3(-9, 5.2, 34), "", 0.0)})
	if Game.has_flag("has_station_key") and not Game.has_flag("tide_out"):
		level.listener.activate(PATROL[2], PATROL)
		level.listener.patrol_i = 2


func _enter() -> void:
	Game.set_flag("entered_settlement")
	if Game.state.objective in ["go_inland", "find_shed", "leave_boat", "take_recorder", "try_listen", "record_echo"]:
		level.objective("find_key")
	level.checkpoint("settlement")
	silhouette.visible = true
	Sound.play_at("bell", Vector3(-4, 8, 26), -10.0, {"unit_size": 20.0})


func _process(delta: float) -> void:
	for i in clock_hands.size():
		clock_hands[i].rotation.z += delta * (0.6 if i == 1 else 0.05)  # counter-clockwise: backwards
	if silhouette and silhouette.visible:
		silhouette.animate(delta, 0.0, level.player.head.global_position)
		var d: float = level.player.global_position.distance_to(silhouette.global_position)
		if d < 30.0:
			_vanish()


func _vanish() -> void:
	silhouette.visible = false
	var e := _sil_lamp.light_energy
	_sil_lamp.light_energy = 0.0
	await get_tree().create_timer(0.5).timeout
	_sil_lamp.light_energy = e


## Taking the key: the bell rings, motionless — and The Listener comes to it.
func _after_key() -> void:
	await get_tree().create_timer(2.5).timeout
	Sound.pre_echo("bell", bell.global_position + Vector3(0, 2.7, 0), "[the bell in the square rings — the bell isn't moving]", 4.0, 0.0, {"unit_size": 20.0, "max_distance": 200.0})
	await get_tree().create_timer(3.0).timeout
	level.listener.activate(Vector3(-24, Terrain.height(-24, 8), 8), PATROL, level.listener.S.INVESTIGATING)
	level.listener._investigate(bell.global_position)
	await get_tree().create_timer(4.0).timeout
	level.hud.toast("Something is walking toward the square.  Crouch [Ctrl] to stay quiet.", 4.0)
	await get_tree().create_timer(5.0).timeout
	if Game.state.recordings.size() > 0:
		level.hud.toast("A replayed recording returns to where it was made. Use that.  [R]", 5.0)
