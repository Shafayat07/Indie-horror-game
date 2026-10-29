extends Node3D
## LOCATION A — THE FLOODED DOCK.
## Opening: radio pre-echo on the boat, footsteps that follow you down the
## dock and keep walking three steps after you stop, the recorder in the shed
## (Listen + Record tutorial), and the boat you leave on at the end.

const DECK_Y := 1.5
var level: Node
var boat: Node3D
var boat_radio: Node3D
var _follow_active := false
var _follow_count := 0
var _still_time := 0.0


func build(lv: Node) -> void:
	level = lv
	add_to_group("navsrc_surface")
	level.checkpoints["dock_start"] = [Vector3(5.6, 1.5, 108.5), 0.0, "surface"]
	level.checkpoints["dock_recorder"] = [Vector3(5.6, 2.1, 72.5), 90.0, "surface"]
	level.checkpoints["ending_boat"] = [Vector3(0, DECK_Y, 100.0), 0.0, "surface"]
	_build_dock()
	_build_boat()
	_build_shed()
	_build_shore()
	Zone.make(self, Vector3(0, 3, 95), Vector3(40, 10, 40), {"ambience": "dock"})
	Zone.make(self, Vector3(5.5, 2.5, 107), Vector3(3.2, 3, 7.5), {"ambience": "boat"})


func _build_dock() -> void:
	var plank := B.mat("wood_planks", Color(0.95, 0.92, 0.88), 0.55)
	var post := B.mat("wood_dark", Color(0.8, 0.8, 0.8), 0.6)
	# main walk, a T-head and pilings down into black water
	B.box(self, Vector3(0, DECK_Y - 0.1, 96), Vector3(3.0, 0.2, 34), plank, {"surface": "wood"})
	B.box(self, Vector3(-0.75, DECK_Y - 0.1, 111), Vector3(8.5, 0.2, 6), plank, {"surface": "wood"})
	for z in range(80, 115, 4):
		for x in [-1.4, 1.4]:
			B.box(self, Vector3(x, DECK_Y - 4.0, z), Vector3(0.25, 7.6, 0.25), post, {"surface": "wood"})
	for x in [-4.8, 3.3]:
		for z in [108.5, 113.5]:
			B.box(self, Vector3(x, DECK_Y - 4.0, z), Vector3(0.25, 7.6, 0.25), post, {"surface": "wood"})
	# a few missing planks, a low rail on one side
	B.box(self, Vector3(0.6, DECK_Y - 0.05, 90), Vector3(1.0, 0.12, 0.6), B.flat(Color(0.01, 0.01, 0.01)), {"collide": false})
	for z in range(82, 108, 3):
		B.box(self, Vector3(-1.45, DECK_Y + 0.45, z), Vector3(0.1, 0.9, 0.1), post, {"surface": "wood"})
	B.box(self, Vector3(-1.45, DECK_Y + 0.9, 95), Vector3(0.08, 0.08, 26), post, {"collide": false})
	# keep the player out of the sea
	B.collider(self, Vector3(1.6, DECK_Y + 1, 93), Vector3(0.2, 2.5, 26))
	B.collider(self, Vector3(-1.6, DECK_Y + 1, 95), Vector3(0.2, 2.5, 30))
	B.collider(self, Vector3(-0.75, DECK_Y + 1, 114.1), Vector3(8.5, 2.5, 0.2))
	B.collider(self, Vector3(-5.1, DECK_Y + 1, 111), Vector3(0.2, 2.5, 6))
	B.collider(self, Vector3(-3.0, DECK_Y + 1, 107.9), Vector3(4.2, 2.5, 0.2))
	# clutter
	P.crate(self, Vector3(-3.8, DECK_Y, 112.6), 15)
	P.crate(self, Vector3(-3.8, DECK_Y + 0.8, 112.6), 40, 0.6)
	P.barrel(self, Vector3(-2.6, DECK_Y, 113.3))
	P.net_pile(self, Vector3(-1.0, DECK_Y, 85))
	P.crate(self, Vector3(0.8, DECK_Y, 83), -10, 0.7)
	P.buoy(self, Vector3(-7, -0.3, 102), 35)
	P.buoy(self, Vector3(9, -0.4, 96), -25)
	P.buoy(self, Vector3(-4, -0.2, 120), 60)
	P.lamp_post(self, Vector3(-1.2, DECK_Y, 97), Color(1.0, 0.66, 0.32), 1.8)
	B.label(self, Vector3(-0.9, DECK_Y + 2.3, 97.05), "VEY ISLE\nPOP. —", 40, Color(0.75, 0.72, 0.65))


func _build_boat() -> void:
	boat = Node3D.new()
	add_child(boat)
	boat.position = Vector3(5.6, 0, 108)
	var hull := B.mat("metal_green", Color(0.7, 0.75, 0.7), 0.8)
	var deck := B.mat("wood_planks", Color(0.7, 0.68, 0.6), 0.8)
	B.box(boat, Vector3(0, 0.55, 0), Vector3(2.6, 1.3, 7.0), hull, {"collide": false})
	var bow := B.box(boat, Vector3(0, 0.55, -4.1), Vector3(1.85, 1.3, 1.85), hull, {"collide": false})
	bow.rotation_degrees.y = 45
	B.box(boat, Vector3(0, DECK_Y - 0.1, 0), Vector3(2.4, 0.2, 7.0), deck, {"surface": "wood"})
	B.box(boat, Vector3(0, DECK_Y - 0.1, -3.6), Vector3(1.6, 0.2, 1.4), deck, {"surface": "wood"})
	# cabin with the radio
	var cab := B.mat("plaster_white", Color(0.75, 0.78, 0.76), 0.8)
	B.box(boat, Vector3(0, DECK_Y + 1.0, 2.7), Vector3(2.4, 2.0, 0.1), cab, {})
	B.box(boat, Vector3(-1.15, DECK_Y + 1.0, 1.8), Vector3(0.1, 2.0, 1.8), cab, {})
	B.box(boat, Vector3(1.15, DECK_Y + 1.0, 1.8), Vector3(0.1, 2.0, 1.8), cab, {})
	B.box(boat, Vector3(0, DECK_Y + 2.05, 1.8), Vector3(2.5, 0.1, 2.0), cab, {"collide": true})
	B.box(boat, Vector3(0, DECK_Y + 0.5, 2.4), Vector3(2.2, 1.0, 0.5), B.mat("wood_dark", Color.WHITE, 1.0), {"surface": "wood"})
	boat_radio = P.radio_set(boat, Vector3(0.4, DECK_Y + 1.0, 2.4), 180)
	B.omni(boat, Vector3(0, DECK_Y + 1.8, 1.8), Color(0.5, 0.9, 0.6), 0.6, 4.0)
	# rails
	for sx in [-1, 1]:
		B.collider(boat, Vector3(sx * 1.25, DECK_Y + 0.6, 0), Vector3(0.1, 1.2, 7.0))
		B.box(boat, Vector3(sx * 1.25, DECK_Y + 0.55, -0.5), Vector3(0.06, 0.06, 6.0), B.flat(Color(0.2, 0.2, 0.2), 0.4, 0.7), {"collide": false})
	B.collider(boat, Vector3(0, DECK_Y + 0.6, -4.4), Vector3(2.4, 1.2, 0.2))
	# the gap to the dock is flush with the T-head (x 3.5) — step across
	var leave := Interactable.make(boat, Vector3(0.4, DECK_Y + 1.0, 2.2), Vector3(0.8, 0.6, 0.6), "Start the engine and leave Vey Isle")
	leave.used.connect(_on_leave)
	leave.enabled = false
	boat.set_meta("leave", leave)
	var bob := create_tween().set_loops()
	bob.tween_property(boat, "rotation_degrees:z", 1.2, 2.6).set_trans(Tween.TRANS_SINE)
	bob.tween_property(boat, "rotation_degrees:z", -1.2, 2.6).set_trans(Tween.TRANS_SINE)


func _build_shed() -> void:
	var g := Terrain.height(8, 72)
	var shed := B.room(self, Vector3(8, g, 72), Vector3(4.0, 2.6, 3.4), {
		"wall": B.mat("wood_planks", Color(0.75, 0.72, 0.68), 0.7),
		"outer": B.mat("wood_planks", Color(0.6, 0.62, 0.62), 0.5),
		"openings": [{"side": "w", "at": 0.6, "w": 1.0, "h": 2.1}, {"side": "s", "at": 0.8, "w": 0.8, "h": 0.6, "sill": 1.2}],
		"roof": true,
	})
	var door := Door.make(shed, Vector3(-2.1, 0, 0.6), 90, {"id": "shed"})
	B.ring_mark(shed, Vector3(-2.25, 1.6, -0.2), -90)
	B.box(shed, Vector3(0.8, 1.5, 1.79), Vector3(0.8, 0.6, 0.02), B.glass(), {"collide": false})
	P.workbench(shed, Vector3(0.6, 0, -1.25))
	P.shelf(shed, Vector3(1.75, 0, 0.4), -90, 1.6)
	P.barrel(shed, Vector3(-1.4, 0, -1.2), Color(0.3, 0.32, 0.3))
	P.net_pile(shed, Vector3(-1.2, 0, 1.2))
	var lamp := B.omni(shed, Vector3(0.6, 2.3, -0.6), Color(1.0, 0.72, 0.42), 1.4, 6.0, true)
	B.sphere(shed, Vector3(0.6, 2.35, -0.6), 0.09, B.glow(Color(1.0, 0.72, 0.42), 4.0))
	P.note(shed, Vector3(-0.3, 1.5, -1.68), "shed_log", 0, true)
	P.note(shed, Vector3(1.1, 0.95, -1.2), "work_order", 20)
	Zone.make(shed, Vector3(0, 1.3, 0), Vector3(3.9, 2.5, 3.3), {"ambience": "interior", "safe": true, "reverb": 0.15})
	# the recorder
	var rec_model := Node3D.new()
	shed.add_child(rec_model)
	rec_model.position = Vector3(0.1, 0.95, -1.2)
	rec_model.rotation_degrees = Vector3(-90, 0, 20)
	B.box(rec_model, Vector3.ZERO, Vector3(0.11, 0.19, 0.045), B.mat("metal_green", Color(0.75, 0.8, 0.75), 2.0, {"world": false}), {"collide": false})
	B.box(rec_model, Vector3(0, 0.04, 0.024), Vector3(0.08, 0.06, 0.005), B.glow(Color(0.35, 0.55, 0.4), 0.6), {"collide": false})
	var take := Interactable.make(shed, Vector3(0.1, 1.0, -1.2), Vector3(0.4, 0.3, 0.4), "Take the field recorder")
	take.once = true
	take.used.connect(func(p):
		rec_model.queue_free()
		p.recorder.give()
		Sound.play_2d("pickup", -4.0)
		p.hud.toast("Field recorder.  Q — listen     R — open recorder")
		level.objective("try_listen"))
	if Game.has_flag("has_recorder"):
		rec_model.queue_free()
		take.queue_free()
	# what the recorder hears in here: the footsteps again, and a voice under them
	Recordable.make(shed, Vector3(-0.5, 1.2, 0.0), "dock_steps", "echo_footsteps_voice", {"listen_only": true, "radius": 5.0, "interval": 6.5, "volume": 2.0, "unit_size": 4.0})


func _build_shore() -> void:
	var rock_m := B.mat("stone_wet", Color.WHITE, 0.35, {"roughness": 0.8})
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 26:
		var x := rng.randf_range(-30, 30)
		if abs(x) < 3.0:
			x += 6.0 * sign(x + 0.01)
		var z := rng.randf_range(80, 90)
		var g := Terrain.height(x, z)
		B.rock(self, Vector3(x, g - 0.3, z), Vector3.ONE * rng.randf_range(0.8, 2.6), i, rock_m, true, rng.randf() * TAU)
	# wrecked rowboat on the rocks
	var wreck := Node3D.new()
	add_child(wreck)
	wreck.position = Vector3(-9, Terrain.height(-9, 84) + 0.2, 84)
	wreck.rotation_degrees = Vector3(12, 40, 28)
	var wm := B.mat("wood_dark", Color(0.8, 0.85, 0.9), 0.8)
	B.box(wreck, Vector3(0, 0.3, 0), Vector3(1.4, 0.08, 3.6), wm, {})
	for sx in [-1, 1]:
		B.box(wreck, Vector3(sx * 0.7, 0.55, 0), Vector3(0.08, 0.5, 3.4), wm, {"collide": false})
	B.box(wreck, Vector3(0, 0.55, 1.0), Vector3(1.3, 0.06, 0.3), wm, {"collide": false})
	# boundary along the waterline so nobody wanders into the sea
	for seg in [[Vector3(-20, 2, 86), Vector3(36, 6, 1)], [Vector3(20, 2, 86), Vector3(36, 6, 1)]]:
		var c: Vector3 = seg[0]
		if abs(c.x) < 3:
			continue
		B.collider(self, c + Vector3(0, 0, 0), seg[1])


# ------------------------------------------------------------------ events
func on_spawn(cp: String) -> void:
	var leave: Interactable = boat.get_meta("leave")
	leave.enabled = Game.has_flag("chose_break") or Game.has_flag("chose_send")
	Game.flag_set.connect(func(f):
		if f == "chose_break" or f == "chose_send":
			leave.enabled = true)
	if cp == "dock_start":
		_opening()
	level.player.stepped.connect(_on_player_step)
	level.player.recorder.listen_toggled.connect(_on_listen)
	level.player.recorder.recorded.connect(_on_recorded)
	Zone.make(self, Vector3(-0.75, DECK_Y + 1, 111), Vector3(8, 3, 6), {"once": true, "block": "left_boat",
		"on_enter": func(_b):
			Game.set_flag("left_boat")
			level.objective("find_shed")})
	Zone.make(self, Vector3(0, DECK_Y + 1, 100), Vector3(3, 3, 2), {"once": true, "block": "dock_echo",
		"on_enter": func(_b): _start_follow()})


func _opening() -> void:
	level.objective("leave_boat")
	await get_tree().create_timer(3.0).timeout
	var pos: Vector3 = boat_radio.global_position + Vector3(0, 0.2, 0)
	Sound.play_at("radio_burst", pos, 0.0)
	await get_tree().create_timer(0.8).timeout
	Sound.play_at("radio_voice_elias", pos, -2.0, {"bus": "Voice", "unit_size": 3.0})
	level.hud.radio("boat_arrival")
	Sound.play_at("bell", Vector3(-10, 30, -40), -6.0, {"unit_size": 40.0, "max_distance": 400.0})


## The footsteps behind you: each step you take on the dock is answered a few
## metres back. When you stop, they take exactly three more steps.
func _start_follow() -> void:
	Game.set_flag("dock_echo")
	_follow_active = true
	_follow_count = 0
	Sound.say("[footsteps on the dock behind you]", "preecho", 3.0)


func _on_player_step(surface: String) -> void:
	if not _follow_active or surface != "wood":
		return
	_still_time = 0.0
	_follow_count += 1
	var p: Vector3 = level.player.global_position
	var behind: Vector3 = p + level.player.global_transform.basis.z * 5.0
	behind.x = clamp(behind.x, -1.2, 1.2)
	get_tree().create_timer(0.18).timeout.connect(func():
		Sound.play_at("step_wood_%d" % (randi() % 4), Vector3(behind.x, DECK_Y, behind.z), -2.0, {"bus": "PreEcho", "unit_size": 5.0}))


func _process(delta: float) -> void:
	if not _follow_active or level == null:
		return
	var moving: bool = Vector2(level.player.velocity.x, level.player.velocity.z).length() > 0.3
	if moving:
		_still_time = 0.0
		if level.player.global_position.z < 80.0:
			_follow_active = false   # reached shore; they stop with you
		return
	_still_time += delta
	if _still_time > 0.8 and _follow_count > 2:
		_follow_active = false
		_three_more_steps()


func _three_more_steps() -> void:
	var p: Vector3 = level.player.global_position
	var fwd: Vector3 = -level.player.global_transform.basis.z
	for i in 3:
		await get_tree().create_timer(0.62).timeout
		var at := p - fwd * (4.0 - i * 1.0)
		at.x = clamp(at.x, -1.2, 1.2)
		Sound.play_at("step_wood_%d" % i, Vector3(at.x, DECK_Y, at.z), 0.0, {"bus": "PreEcho", "unit_size": 5.0})
	await get_tree().create_timer(0.8).timeout
	Sound.say("[three more steps. Then nothing.]", "aside", 3.5)


func _on_listen(on: bool) -> void:
	if on and Game.state.objective == "try_listen":
		Game.set_flag("first_listen")
		await get_tree().create_timer(1.2).timeout
		Sound.say("[the footsteps again — and beneath them, a voice. Yours.]", "preecho", 4.5)
		await get_tree().create_timer(3.0).timeout
		Sound.say("\"...don't let it hear you twice...\"", "preecho", 4.0)
		await get_tree().create_timer(2.0).timeout
		level.objective("record_echo")


func _on_recorded(id: String) -> void:
	if id == "dock_steps" and Game.state.objective in ["record_echo", "try_listen"]:
		level.objective("go_inland")
		level.player.hud.toast("Recordings can be replayed: open the recorder and select one.", 4.0)
		level.checkpoint("dock_recorder")


func _on_leave(p: Node) -> void:
	## Final scene for both endings: the boat pulls away, the radio speaks.
	p.freeze(true)
	p.set_physics_process(false)
	var choice := "break" if Game.has_flag("chose_break") else "send"
	p.hud.hide_overlays()
	p.place(boat.global_position + Vector3(0, DECK_Y + 0.1, -2.0), 0.0)
	p.reparent(boat)
	Sound.play_2d("generator_start", -6.0)
	var tw := create_tween()
	tw.tween_property(boat, "position", boat.position + Vector3(10, 0, 70), 24.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(boat, "rotation_degrees:y", 160.0, 14.0).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(5.0).timeout
	var pos: Vector3 = boat_radio.global_position
	Sound.play_at("radio_burst", pos, -8.0 if choice == "break" else 0.0)
	if choice == "send":
		Sound.play_at("radio_voice_elias", pos, -2.0, {"bus": "Voice"})
	await get_tree().create_timer(1.0).timeout
	p.hud.radio("ending_" + choice)
	await get_tree().create_timer(13.0).timeout
	Game.finish_game(choice)
