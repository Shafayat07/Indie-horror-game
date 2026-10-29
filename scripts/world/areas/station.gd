extends Node3D
## LOCATION C — THE WEATHER STATION.
## Restore power (fuel valve + generator), hear the relay order hidden on
## calibration tape 13 (only audible while listening — it is the sound of you
## pressing the relays, later tonight), run the relay sequence, transmit the
## report. The transmission pulls the tide out and exposes the caves.

const ORIGIN := Vector3(-60, 6.5, -10)
const SEQUENCE := [1, 0, 2, 0]   # B, A, C, A — matches tools/gen_audio.py
const RELAY_NAMES := ["A", "B", "C"]
const RELAY_PITCH := ["LOW", "MIDDLE", "HIGH"]

var level: Node
var root: Node3D
var lights: Array[Light3D] = []
var light_energy: Array[float] = []
var glow_panels: Array[MeshInstance3D] = []
var _input: Array = []
var _blackout := false
var _gen_loop: AudioStreamPlayer3D
var _tape_hiss: AudioStreamPlayer3D
var _mast_light: OmniLight3D
var _console_lamp: MeshInstance3D
var _tape_caption_cd := 0.0
var _tape_pos := Vector3.ZERO
var _transmitting := false
var _reels: Array[MeshInstance3D] = []
var _relay_lamps: Array[MeshInstance3D] = []


func build(lv: Node) -> void:
	level = lv
	add_to_group("navsrc_surface")
	root = Node3D.new()
	add_child(root)
	root.position = ORIGIN
	level.checkpoints["station"] = [ORIGIN + Vector3(17, 0.1, 2), 90.0, "surface"]
	level.checkpoints["station_power"] = [ORIGIN + Vector3(-5, 0.1, 6.5), 180.0, "surface"]
	level.checkpoints["station_relays"] = [ORIGIN + Vector3(4, 0.1, 0), -90.0, "surface"]
	level.checkpoints["station_transmit"] = [ORIGIN + Vector3(4, 0.1, 0), 90.0, "surface"]
	_compound()
	_building()
	_generator_room()
	_office()
	_corridor()
	_monitoring()
	_mast()
	Zone.make(self, ORIGIN + Vector3(0, 3, 0), Vector3(40, 10, 36), {"ambience": "station"})
	Zone.make(root, Vector3(0, 1.6, 0), Vector3(14, 3.2, 9), {"ambience": "station_in", "reverb": 0.22})
	_apply_power(Game.has_flag("station_power"), true)
	if Game.has_flag("relays_ok"):
		_console_lamp.material_override = B.glow(Color(0.3, 1.0, 0.45), 3.0)
		for c in _relay_lamps:
			c.material_override = B.glow(Color(0.3, 1.0, 0.45), 3.0)


func _compound() -> void:
	# chain-link fence with a locked gate on the road side
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in 64:
		for k in [-1, 0, 1]:
			img.set_pixel(i, (i + k + 64) % 64, Color(0.45, 0.47, 0.45, 1))
			img.set_pixel(i, (63 - i + k + 64) % 64, Color(0.45, 0.47, 0.45, 1))
	var tex := ImageTexture.create_from_image(img)
	var fm := StandardMaterial3D.new()
	fm.albedo_texture = tex
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	fm.alpha_scissor_threshold = 0.5
	fm.cull_mode = BaseMaterial3D.CULL_DISABLED
	fm.uv1_triplanar = true
	fm.uv1_world_triplanar = true
	fm.uv1_scale = Vector3(3, 3, 3)
	fm.metallic = 0.6
	fm.roughness = 0.5
	var post_m := B.mat("metal_rust", Color(0.7, 0.7, 0.7), 1.0)
	var sides := [[Vector3(-16, 0, -14), Vector3(16, 0, -14)], [Vector3(-16, 0, 13), Vector3(16, 0, 13)],
		[Vector3(-16, 0, -14), Vector3(-16, 0, 13)], [Vector3(16, 0, -14), Vector3(16, 0, -0.6)], [Vector3(16, 0, 4.6), Vector3(16, 0, 13)]]
	for s in sides:
		var a: Vector3 = s[0]
		var b: Vector3 = s[1]
		var mid := (a + b) * 0.5
		var length := a.distance_to(b)
		var along_z: bool = abs(a.x - b.x) < 0.01
		var q := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(length, 2.4)
		q.mesh = qm
		q.material_override = fm
		root.add_child(q)
		q.position = mid + Vector3(0, 1.2, 0)
		if along_z:
			q.rotation_degrees.y = 90
		B.collider(root, mid + Vector3(0, 1.3, 0), Vector3(0.1, 2.6, length) if along_z else Vector3(length, 2.6, 0.1))
		var n := int(length / 3.0)
		for i in n + 1:
			var p := a.lerp(b, float(i) / max(n, 1))
			B.box(root, p + Vector3(0, 1.25, 0), Vector3(0.08, 2.5, 0.08), post_m, {"collide": false})
	var gate := Door.make(root, Vector3(16, 0, 2.0), 90, {"id": "station_gate", "w": 2.6, "h": 2.3, "lock": "has_station_key",
		"mat": post_m, "locked_text": "The compound gate is locked. The key will be somewhere in the settlement.",
		"unlock_text": "The station key turns, stiff with salt.", "noise": 12.0})
	gate.opened.connect(func():
		if not Game.has_flag("reached_station"):
			Game.set_flag("reached_station")
			level.objective("restore_power")
			level.checkpoint("station"))
	B.label(root, Vector3(16.2, 2.9, 2.0), "VEY ISLE COASTAL WEATHER STATION", 26, Color(0.7, 0.68, 0.62), Vector3(0, 90, 0))


func _building() -> void:
	var conc := B.mat("concrete", Color(0.8, 0.82, 0.8), 0.4)
	var inner := B.mat("plaster_white", Color(0.62, 0.64, 0.6), 0.5)
	B.room(root, Vector3.ZERO, Vector3(14, 3.2, 9), {"wall": inner, "outer": conc, "floor": B.mat("concrete", Color(0.55, 0.55, 0.52), 0.5),
		"ceiling": B.mat("concrete", Color(0.5, 0.5, 0.5), 0.5), "surface": "stone",
		"openings": [
			{"side": "e", "at": 1.5, "w": 1.1, "h": 2.2},            # main entrance
			{"side": "s", "at": -5.0, "w": 1.1, "h": 2.2},           # generator room
			{"side": "e", "at": -2.5, "w": 1.2, "h": 1.0, "sill": 1.1},
			{"side": "s", "at": 4.0, "w": 1.6, "h": 1.0, "sill": 1.1},
			{"side": "n", "at": 4.0, "w": 1.6, "h": 1.0, "sill": 1.1},
		]})
	# flat roof lip
	B.box(root, Vector3(0, 3.45, 0), Vector3(14.8, 0.3, 9.8), conc, {"collide": false})
	for w in [[Vector3(7.1, 1.6, -2.5), Vector3(0.03, 1.0, 1.2)], [Vector3(4, 1.6, 4.6), Vector3(1.6, 1.0, 0.03)], [Vector3(4, 1.6, -4.6), Vector3(1.6, 1.0, 0.03)]]:
		B.box(root, w[0], w[1], B.glass(Color(0.25, 0.3, 0.32, 0.35)), {"collide": false})
	var main_door := Door.make(root, Vector3(7.1, 0, 1.5), 90, {"id": "station_main", "w": 1.1, "h": 2.2, "mat": B.mat("metal_green", Color(0.8, 0.85, 0.8), 1.0)})
	# interior partitions: wall at x=1 (monitoring | west block), wall at z=0 in the west block, wall at x=-3 in the south half
	var t := 0.2
	_wall(Vector3(1, 0, -4.5), Vector3(1, 0, 4.5), [[-2.5, 1.2], [2.5, 1.0]], inner)
	_wall(Vector3(-7, 0, 0), Vector3(1, 0, 0), [], inner)
	_wall(Vector3(-3, 0, 0), Vector3(-3, 0, 4.5), [], inner)
	var lamp_m := B.glow(Color(1.0, 0.85, 0.6), 2.0)
	for p in [Vector3(4, 3.05, -2), Vector3(4, 3.05, 2.5), Vector3(-1, 3.05, 2.2), Vector3(-5, 3.05, 2.2), Vector3(-3, 3.05, -2.2)]:
		var l := B.omni(root, p + Vector3(0, -0.15, 0), Color(1.0, 0.86, 0.66), 1.3, 7.0, p.x > 2.0 and p.z < 0)
		lights.append(l)
		light_energy.append(1.3)
		var fixture := B.box(root, p, Vector3(0.9, 0.08, 0.2), lamp_m, {"collide": false})
		glow_panels.append(fixture)


func _wall(a: Vector3, b: Vector3, gaps: Array, m: Material) -> void:
	## Interior wall from a to b (axis-aligned) with door gaps [[offset_from_a_center, width]].
	var along_z: bool = abs(a.x - b.x) < 0.01
	var length := a.distance_to(b)
	var h := 3.2
	var cursor := -length * 0.5
	var segs := []
	for g in gaps:
		var s0: float = g[0] - g[1] * 0.5
		segs.append([cursor, s0])
		segs.append([s0, g[0] + g[1] * 0.5, true])
		cursor = g[0] + g[1] * 0.5
	segs.append([cursor, length * 0.5])
	var mid := (a + b) * 0.5
	for s in segs:
		var w: float = s[1] - s[0]
		if w <= 0.01:
			continue
		var c: float = (s[0] + s[1]) * 0.5
		var is_gap: bool = s.size() > 2
		var y0 := 2.25 if is_gap else 0.0
		var hh := h - y0
		var p := mid + (Vector3(0, 0, c) if along_z else Vector3(c, 0, 0))
		p.y = y0 + hh * 0.5
		B.box(root, p, Vector3(0.2, hh, w) if along_z else Vector3(w, hh, 0.2), m, {"surface": "stone"})


func _generator_room() -> void:
	var gdoor := Door.make(root, Vector3(-5.0, 0, 4.6), 0, {"id": "gen_room", "w": 1.1, "h": 2.2, "mat": B.mat("metal_rust", Color(0.8, 0.8, 0.8), 1.0), "noise": 10.0})
	var metal := B.mat("metal_green", Color(0.9, 0.9, 0.9), 1.2, {"metallic": 0.4})
	var gen := Node3D.new()
	root.add_child(gen)
	gen.position = Vector3(-5.6, 0, 1.6)
	B.box(gen, Vector3(0, 0.5, 0), Vector3(1.8, 1.0, 1.0), metal, {"surface": "metal"})
	B.cyl(gen, Vector3(1.0, 0.55, 0), 0.35, 0.15, B.mat("metal_rust", Color.WHITE, 2.0), {"collide": false, "rot": Vector3(0, 0, 90)})
	B.cyl(gen, Vector3(-0.6, 1.5, -0.3), 0.08, 1.2, B.mat("metal_rust", Color.WHITE, 2.0), {"collide": false})
	B.box(gen, Vector3(0.3, 1.15, 0), Vector3(0.6, 0.3, 0.5), B.mat("metal_red", Color(0.8, 0.8, 0.8), 2.0), {"collide": false})
	_gen_loop = Sound.attach_loop(gen, "amb_generator", -4.0, {"unit_size": 3.0, "max_distance": 35.0, "autoplay": false})
	# fuel tank and valve
	var tank := B.cyl(root, Vector3(-6.4, 0.9, 3.7), 0.45, 1.8, B.mat("metal_red", Color(0.7, 0.7, 0.7), 1.0), {"surface": "metal"})
	var wheel := B.cyl(root, Vector3(-5.85, 1.0, 3.7), 0.16, 0.04, B.flat(Color(0.5, 0.1, 0.08), 0.5, 0.6), {"collide": false, "rot": Vector3(0, 0, 90)})
	B.label(root, Vector3(-6.4, 1.9, 3.24), "FUEL", 28, Color(0.8, 0.75, 0.6))
	var valve := Interactable.make(root, Vector3(-5.85, 1.0, 3.7), Vector3(0.3, 0.4, 0.4), "Open the fuel valve")
	valve.used.connect(func(p):
		if Game.has_flag("fuel_open"):
			p.hud.toast("The valve is already open.")
			return
		Game.set_flag("fuel_open")
		Sound.play_at("door_creak_1", wheel.global_position, -6.0, {"pitch": 1.6})
		var tw := create_tween()
		tw.tween_property(wheel, "rotation_degrees:x", 540.0, 1.2)
		p.hud.toast("Fuel trickles into the line."))
	var starter := Interactable.make(gen, Vector3(1.0, 0.6, 0.0), Vector3(0.5, 0.8, 1.0), "Pull the starter cord")
	starter.used.connect(_start_generator)
	B.omni(root, Vector3(-5, 2.0, 2.2), Color(0.3, 0.35, 0.45), 0.15, 4.0)  # moonlight spill so it is not pitch black


func _start_generator(p: Node) -> void:
	if Game.has_flag("station_power"):
		p.hud.toast("The generator is running.")
		return
	if not Game.has_flag("fuel_open"):
		var s := Sound.play_at("generator_start", _gen_loop.global_position, -2.0)
		Sound.emit_noise(_gen_loop.global_position, 12.0, "machine")
		await get_tree().create_timer(1.9).timeout
		if is_instance_valid(s):
			s.stop()
		p.hud.toast("It coughs and dies. Nothing is reaching the engine.")
		return
	Game.set_flag("station_power")
	Sound.play_at("generator_start", _gen_loop.global_position, 0.0)
	Sound.emit_noise(_gen_loop.global_position, 30.0, "machine")
	await get_tree().create_timer(2.4).timeout
	_gen_loop.play()
	_apply_power(true)
	p.hud.toast("Power. The station hums awake.")
	level.objective("find_sequence")
	level.checkpoint("station_power")


func _office() -> void:
	var door := Door.make(root, Vector3(1.0, 0, 2.5), 90, {"id": "st_office", "w": 1.0, "h": 2.1})
	B.ring_mark(root, Vector3(1.12, 1.7, 1.6), 90)
	Zone.make(root, Vector3(-1, 1.5, 2.25), Vector3(3.8, 3, 4.3), {"safe": true})
	P.table(root, Vector3(-1.2, 0, 3.6), 0, Vector2(1.6, 0.8))
	P.chair(root, Vector3(-1.2, 0, 3.0), 0)
	P.shelf(root, Vector3(-2.75, 0, 1.5), 90, 1.4)
	# tape deck
	var deck := Node3D.new()
	root.add_child(deck)
	deck.position = Vector3(-1.6, 0.8, 3.7)
	B.box(deck, Vector3(0, 0.12, 0), Vector3(0.6, 0.24, 0.4), B.mat("wood_dark", Color(1.1, 1.0, 0.9), 2.0), {"collide": false})
	for sx in [-1, 1]:
		var reel := B.cyl(deck, Vector3(sx * 0.15, 0.26, 0.0), 0.11, 0.02, B.flat(Color(0.25, 0.2, 0.16), 0.5), {"collide": false})
		_reels.append(reel)
	_tape_pos = deck.global_position + Vector3(0, 0.3, 0)
	P.note(root, Vector3(-0.8, 0.8, 3.75), "tape_13", 0)
	_tape_hiss = Sound.attach_loop(deck, "amb_tape", -10.0, {"unit_size": 1.5, "max_distance": 10.0, "autoplay": false})
	Recordable.make(deck, Vector3(0, 0.3, 0), "tape_13", "calibration_tape", {"listen_only": true, "radius": 4.0, "active_flag": "station_power", "volume": 0.0, "unit_size": 3.0})
	var it := Interactable.make(deck, Vector3(0, 0.2, 0), Vector3(0.6, 0.4, 0.5), "Tape deck")
	it.used.connect(func(pl):
		if not Game.has_flag("station_power"):
			pl.hud.toast("The tape deck is dead. No power.")
		else:
			pl.hud.toast("Only hiss on the tape. The label says to listen properly.  [Q]"))


func _corridor() -> void:
	var cd := Door.make(root, Vector3(1.0, 0, -2.5), 90, {"id": "st_corridor", "w": 1.2, "h": 2.2, "lock": "station_power",
		"mat": B.mat("metal_green", Color(0.7, 0.75, 0.7), 1.0), "locked_text": "An electric lock. Dead without power.", "noise": 10.0})
	P.note(root, Vector3(0.75, 1.5, -3.6), "station_manual", -90, true)
	var cab_m := B.mat("metal_green", Color(0.85, 0.9, 0.85), 1.5, {"metallic": 0.3})
	for i in 3:
		var c := Node3D.new()
		root.add_child(c)
		c.position = Vector3(-5.5 + i * 2.4, 0, -4.05)
		B.box(c, Vector3(0, 1.0, 0), Vector3(1.0, 2.0, 0.6), cab_m, {"surface": "metal"})
		B.label(c, Vector3(0, 1.85, 0.31), "RELAY  " + RELAY_NAMES[i], 30, Color(0.85, 0.82, 0.7))
		var lamp := B.box(c, Vector3(0, 1.55, 0.31), Vector3(0.12, 0.12, 0.02), B.glow(Color(0.4, 0.1, 0.05), 0.5), {"collide": false})
		_relay_lamps.append(lamp)
		B.box(c, Vector3(0, 1.1, 0.32), Vector3(0.25, 0.35, 0.05), B.flat(Color(0.12, 0.12, 0.12), 0.4, 0.6), {"collide": false})
		var it := Interactable.make(c, Vector3(0, 1.1, 0.4), Vector3(0.6, 0.6, 0.3), "Engage relay " + RELAY_NAMES[i])
		it.used.connect(_relay.bind(i, lamp))
	for i in 4:
		B.cyl(root, Vector3(-6.8 + i * 2.3, 2.95, -4.2), 0.07, 2.2, B.mat("metal_rust", Color.WHITE, 2.0), {"collide": false, "rot": Vector3(0, 0, 90)})


func _relay(_p: Node, i: int, lamp: MeshInstance3D) -> void:
	var p: Node = level.player
	if not Game.has_flag("station_power") or _blackout:
		p.hud.toast("Dead. No power to the relays.")
		return
	if Game.has_flag("relays_ok"):
		p.hud.toast("The array is locked. The signal is steady.")
		return
	Sound.play_at("relay_%d" % i, lamp.global_position, 0.0)
	Sound.emit_noise(lamp.global_position, 10.0, "machine")
	Sound.say("♪ relay %s — %s tone" % [RELAY_NAMES[i], RELAY_PITCH[i].to_lower()], "sfx", 2.2)
	lamp.material_override = B.glow(Color(1.0, 0.75, 0.3), 3.0)
	_input.append(i)
	var k := _input.size() - 1
	if _input[k] != SEQUENCE[k]:
		_input.clear()
		_trip_breaker()
		return
	if _input.size() == SEQUENCE.size():
		_input.clear()
		Game.set_flag("relays_ok")
		await get_tree().create_timer(1.2).timeout
		for c in _relay_lamps:
			c.material_override = B.glow(Color(0.3, 1.0, 0.45), 3.0)
		_console_lamp.material_override = B.glow(Color(0.3, 1.0, 0.45), 3.0)
		Sound.play_2d("amb_signal", -14.0)
		p.hud.toast("The relays lock together. A steady carrier.")
		level.objective("activate_transmitter")
		level.checkpoint("station_relays")


func _trip_breaker() -> void:
	_blackout = true
	await get_tree().create_timer(0.8).timeout
	Sound.play_at("relay_wrong", ORIGIN + Vector3(-3, 1.5, -3), 0.0)
	Sound.play_at("power_down", ORIGIN + Vector3(-3, 2.0, 0), 0.0)
	Sound.emit_noise(ORIGIN, 80.0, "alarm")
	_apply_power(false)
	_gen_loop.stop()
	level.hud.toast("The breaker trips. In the dark, something outside turns toward the sound.", 4.0)
	# The Listener answers from the settlement if it's out there
	if level.listener.is_active():
		level.listener._investigate(ORIGIN + Vector3(18, 0, 2))
	await get_tree().create_timer(6.0).timeout
	_gen_loop.play()
	Sound.play_at("generator_start", _gen_loop.global_position, -6.0)
	_apply_power(true)
	for c in _relay_lamps:
		c.material_override = B.glow(Color(0.4, 0.1, 0.05), 0.5)
	_blackout = false
	level.hud.toast("The breaker resets. The relays are back at the start.")


func _monitoring() -> void:
	var desk_m := B.mat("metal_green", Color(0.75, 0.8, 0.75), 1.5, {"metallic": 0.3})
	B.box(root, Vector3(4.5, 0.5, -3.9), Vector3(4.0, 1.0, 0.9), desk_m, {"surface": "metal"})
	B.box(root, Vector3(4.5, 1.4, -4.25), Vector3(4.0, 0.8, 0.2), desk_m, {"collide": false})
	for i in 5:
		var dial := B.cyl(root, Vector3(3.0 + i * 0.75, 1.45, -4.13), 0.14, 0.03, B.flat(Color(0.75, 0.72, 0.62), 0.5), {"collide": false, "rot": Vector3(90, 0, 0)})
		glow_panels.append(dial)
	_console_lamp = B.box(root, Vector3(6.2, 1.05, -3.6), Vector3(0.18, 0.06, 0.18), B.glow(Color(0.6, 0.1, 0.05), 1.0), {"collide": false})
	P.radio_set(root, Vector3(5.6, 1.0, -3.8), 0, false)
	P.note(root, Vector3(3.2, 1.02, -3.7), "kell_log", 8)
	P.chair(root, Vector3(4.4, 0, -2.9), 180)
	P.shelf(root, Vector3(6.75, 0, 3.4), -90, 1.6)
	P.table(root, Vector3(3.0, 0, 3.4), 90, Vector2(1.4, 0.8))
	var it := Interactable.make(root, Vector3(5.6, 1.2, -3.6), Vector3(1.2, 0.6, 0.8), "Transmit the diagnostic report")
	it.used.connect(_transmit)


func _transmit(p: Node) -> void:
	if not Game.has_flag("station_power"):
		p.hud.toast("The console is dead.")
		return
	if not Game.has_flag("relays_ok"):
		p.hud.toast("NO CARRIER. The relay array isn't aligned.")
		return
	if Game.has_flag("transmitted") or _transmitting:
		p.hud.toast("The report has been sent.")
		return
	_transmitting = true
	Sound.play_at("radio_burst", p.global_position, 0.0)
	p.hud.toast("Transmitting diagnostic report...", 3.0)
	await get_tree().create_timer(3.0).timeout
	Sound.play_2d("radio_voice_elias", -6.0, "Voice")
	p.hud.radio("station_reply")
	await get_tree().create_timer(9.0).timeout
	Game.set_flag("transmitted")
	Game.set_flag("tide_out")
	# The sea draws back from the island. Far below, the caves open.
	Sound.play_2d("power_down", -2.0, "SFX", 0.5)
	Sound.play_2d("transmit_surge", -10.0, "SFX", 0.6)
	p.shake(1.5)
	level.ocean.set_level(Ocean.LOW, 14.0)
	level.listener.deactivate()
	get_tree().call_group("beacon", "flare")
	_transmitting = false
	await get_tree().create_timer(5.0).timeout
	level.objective("find_caves")
	level.checkpoint("station_transmit")


func _mast() -> void:
	var m := B.mat("metal_rust", Color(0.8, 0.8, 0.8), 1.0, {"metallic": 0.4})
	var base := Vector3(-8, 0, -11)
	for i in 6:
		var y := 1.5 + i * 3.0
		var w := 1.4 - i * 0.18
		for c in [Vector3(-1, 0, -1), Vector3(1, 0, -1), Vector3(-1, 0, 1), Vector3(1, 0, 1)]:
			B.box(root, base + c * w * 0.5 + Vector3(0, y, 0), Vector3(0.08, 3.0, 0.08), m, {"collide": i == 0})
		B.box(root, base + Vector3(0, y + 1.5, 0), Vector3(w, 0.06, w), m, {"collide": false})
	B.box(root, base + Vector3(0, 19, 0), Vector3(2.4, 0.08, 0.08), m, {"collide": false})
	_mast_light = B.omni(root, base + Vector3(0, 19.4, 0), Color(1.0, 0.1, 0.05), 0.0, 14.0)
	B.sphere(root, base + Vector3(0, 19.4, 0), 0.15, B.glow(Color(1.0, 0.1, 0.05), 4.0))


func _apply_power(on: bool, instant := false) -> void:
	for i in lights.size():
		var l := lights[i]
		if instant:
			l.light_energy = light_energy[i] if on else 0.0
			continue
		var tw := create_tween()
		if on:
			for k in 3:
				tw.tween_property(l, "light_energy", light_energy[i] * randf_range(0.3, 1.0), 0.07)
				tw.tween_property(l, "light_energy", 0.0, 0.05)
			tw.tween_property(l, "light_energy", light_energy[i], 0.2)
		else:
			tw.tween_property(l, "light_energy", 0.0, 0.15)
	for g in glow_panels:
		g.visible = on
	if _tape_hiss:
		if on: _tape_hiss.play()
		else: _tape_hiss.stop()
	if on and Game.has_flag("station_power") and not _gen_loop.playing and not _blackout:
		_gen_loop.play()


func _process(delta: float) -> void:
	if _mast_light:
		_mast_light.light_energy = (2.0 if fmod(Time.get_ticks_msec() / 1000.0, 2.0) < 0.3 else 0.0) if Game.has_flag("station_power") else 0.0
	# the hidden tape: caption once each time you listen near it
	_tape_caption_cd = max(_tape_caption_cd - delta, 0.0)
	if Game.has_flag("station_power") and level.player.recorder.listening and _tape_caption_cd <= 0.0:
		if level.player.global_position.distance_to(_tape_pos) < 4.0:
			_tape_caption_cd = 12.0
			Sound.say("[under the hiss: footsteps on metal... then tones — MIDDLE... LOW... HIGH... LOW]", "preecho", 6.0)
			if not Game.has_flag("heard_tape"):
				Game.set_flag("heard_tape")
				await get_tree().create_timer(6.5).timeout
				Sound.say("[the footsteps between the tones are yours]", "aside", 4.0)
	if Game.has_flag("station_power"):
		for r in _reels:
			r.rotation.y += delta * 2.0


func on_spawn(_cp: String) -> void:
	level.player.flashlight_toggled.connect(_on_flashlight)


## Turn your light off in the dark station and you hear your own switch click,
## somewhere behind you. Once.
func _on_flashlight(on: bool) -> void:
	if on or Game.has_flag("flash_echo") or not Game.has_flag("reached_station"):
		return
	if level.player.global_position.distance_to(ORIGIN) > 12.0:
		return
	Game.set_flag("flash_echo")
	await get_tree().create_timer(1.8).timeout
	var p: Node3D = level.player
	Sound.pre_echo("flashlight_echo", p.global_position + p.global_transform.basis.z * 3.0 + Vector3(0, 1.4, 0), "[the click of a flashlight switch — behind you]", 2.0)
