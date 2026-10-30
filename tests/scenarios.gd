extends Node
## Scripted playthrough tests. They drive the real game systems: zones fire
## from the player body entering them, interactables are used through their
## public interact() API, the recorder records and replays through its own
## code paths. Teleports stand in for walking between points.

var level: Node
var p: Node3D
var failures: Array[String] = []


func run(name: String, lv: Node) -> bool:
	level = lv
	p = level.player
	level.listener.hunt_enabled = false   # AI is tested separately in "ai"
	match name:
		"full_break":
			await _full("break")
		"full_send":
			await _full("send")
		"ai":
			await _ai()
		"death":
			await _death()
		"walk_surface":
			await _walk([Vector3(4.5, 0, 106), Vector3(1.5, 0, 110), Vector3(0, 0, 100), Vector3(0, 0, 80), Vector3(0, 0, 62),
				Vector3(0, 0, 30), Vector3(-2, 0, 22), Vector3(-20, 0, 8), Vector3(-36, 0, -6), Vector3(-42.5, 0, -8)])
		"walk_cliff":
			var so: Vector3 = level.areas.station.ORIGIN
			await _walk([so + Vector3(6.5, 0, 1.5), so + Vector3(12, 0, 1.8), so + Vector3(18, 0, 2.0), Vector3(-36, 0, -6), Vector3(-2, 0, 22), Vector3(20, 0, 18), Vector3(42, 0, 10), Vector3(52, 0, 2),
				Vector3(62, 0, -4), Vector3(66, 0, -6), Vector3(66, 0, -20), Vector3(66, 0, -44), Vector3(66, 0, -50.2)])
			await wait(2.0)
			expect(level.space == "caves", "walked into the cave mouth")
		"walk_cave":
			var c = level.areas.caves
			await _walk([c._p(0, -34, 0), c._p(0, -38, 0), c._p(-1, -50, 0), c._p(0, -70, 0), c._p(0, -78, 0), c._p(1.2, -83, 0)])
		"walk_cave_a":
			var c = level.areas.caves
			await _walk([c._p(0, -10, 0), c._p(-1, -20, 0), c._p(-6, -27, 0), c._p(-13, -31, 0), c._p(-4, -25, 0), c._p(0, -30, 0), c._p(0, -34, 0)])
		"walk_return":
			var C: Vector3 = level.areas.lighthouse.C
			await _walk([C + Vector3(0, 0, 3.5), C + Vector3(0, 0, 7.5), Vector3(0, 0, -36.5), Vector3(0, 0, -30), Vector3(0, 0, 22),
				Vector3(0, 0, 62), Vector3(0, 0, 80), Vector3(0, 0, 104), Vector3(1.5, 0, 108.75), Vector3(5.2, 0, 108.75)])
		"walk_forest":
			await _walk([Vector3(-4, 0, 40), Vector3(-35, 0, 44), Vector3(-58, 0, 40), Vector3(-54, 0, 34), Vector3(-58, 0, 40),
				Vector3(-66, 0, 52), Vector3(-71.5, 0, 57), Vector3(-62, 0, 42), Vector3(-88, 0, 46), Vector3(-97, 0, 46)])
		"walk_lighthouse":
			var C: Vector3 = level.areas.lighthouse.C
			var e: float = level.areas.lighthouse.S + 0.55
			await _walk([C + Vector3(-2.8, 0, -0.5), C + Vector3(-2.8, 0, -e), C + Vector3(e, 3, -e), C + Vector3(e, 6, e),
				C + Vector3(-e, 9, e), C + Vector3(-e, 12, -e), C + Vector3(-1.0, 12, -e), C + Vector3(1.5, 12, -1.5)])
			expect(p.global_position.y > C.y + 11.5, "reached the control room floor (y=%.1f)" % (p.global_position.y - C.y))
		"mouselook":
			p.freeze(false)
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			await physics(2)
			var yaw0: float = p._yaw
			var pitch0: float = p._pitch
			for i in 10:
				var ev := InputEventMouseMotion.new()
				ev.relative = Vector2(20, 8)
				ev.position = get_viewport().get_visible_rect().size * 0.5
				Input.parse_input_event(ev)
				await get_tree().process_frame
			await physics(2)
			expect(abs(p._yaw - yaw0) > 0.1, "mouse motion turns the view (yaw %.3f -> %.3f)" % [yaw0, p._yaw])
			expect(abs(p._pitch - pitch0) > 0.05, "mouse motion tilts the view (pitch %.3f -> %.3f)" % [pitch0, p._pitch])
		"menus":
			var pm = level.pause_menu
			pm.toggle()
			await get_tree().process_frame
			expect(get_tree().paused and pm.is_open, "pause menu pauses the game")
			expect(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "mouse released while paused")
			pm._show_options()
			await get_tree().process_frame
			expect(pm._options != null and not pm._menu.visible, "options panel opens from pause")
			Game.settings.mouse_sensitivity = 0.33
			pm._options.closed.emit()
			Game.save_settings()
			await get_tree().process_frame
			expect(pm._options == null and pm._menu.visible, "options panel closes back to the pause menu")
			pm.toggle()
			await get_tree().process_frame
			expect(not get_tree().paused, "resume unpauses")
			var cfg := ConfigFile.new()
			expect(cfg.load(Game.SETTINGS_PATH) == OK and abs(float(cfg.get_value("settings", "mouse_sensitivity")) - 0.33) < 0.001, "settings persisted to disk")
			Game.settings.mouse_sensitivity = 0.18
			Game.save_settings()
		"kell_hunt":
			var k = level.areas.forest.kell
			expect(k.state == k.S.ROOST, "Kell roosting before the hour")
			Game.state.clock = 3600.0 * (24 - 23) - 40 * 60 - 5.0 + 1200.0 - 1200.0   # 23:59:55
			await wait(3.0)
			expect(k.state == k.S.OUT, "the bell strikes and Kell comes out (clock %s)" % Game.clock_text())
			var spot := Vector3(-50, 0, 46)
			await tp(Vector3(spot.x, Terrain.height(spot.x, spot.z) + 0.5, spot.z))
			p.freeze(false)
			k.global_position = Vector3(spot.x + 6, Terrain.height(spot.x, spot.z) + 10, spot.z)
			k._ping_t = 1.0
			# standing perfectly still: the clicks pass over
			await wait(2.5)
			expect(k.state == k.S.OUT, "standing still under the sonar: not detected")
			# walking in the open: detected, screech, dive, caught
			Input.action_press("move_forward")
			var dove := false
			var caught := false
			k._ping_t = 0.3
			for i in 480:
				await get_tree().physics_frame
				if i % 30 == 0 and is_instance_valid(p):
					p._yaw += 1.2
				if is_instance_valid(k) and (k.state == k.S.WARN or k.state == k.S.DIVE):
					dove = true
				if not is_instance_valid(p) or p.dead:
					caught = true
					break
			Input.action_release("move_forward")
			expect(dove, "moving under the sonar: he screeches and dives")
			expect(caught, "the dive catches a player in the open")
		"horror":
			var h = level.horror
			h._cooldown = 0.0
			p.freeze(false)
			await wait(27.0 + 7.0)
			expect(h._cooldown > 60.0, "standing still: the Lodger came and whispered")
			var g = h.apparition(p.global_position - p.global_transform.basis.z * 8.0, 0.0, {"flag": "test_ghost"})
			p._yaw += PI
			await wait(0.5)
			expect(g.visible, "apparition stands where you are not looking")
			p._yaw -= PI
			await wait(1.0)
			expect(Game.has_flag("test_ghost"), "looking at it banishes it")
			Game.set_flag("left_boat")
			await wait(0.2)
			expect("j_arrival" in Game.state.journal, "journal entry unlocked by progress")
			level.hud.open_journal()
			expect(level.hud._journal.visible and "Why I'm here" in level.hud._journal_text.text, "journal opens with entries")
			level.hud._journal.visible = false
			p.freeze(false)
			level.hud.show_watch()
			expect(":" in level.hud._watch.text, "watch shows the island clock")
			h.suha_presence()
			await wait(0.5)
			expect(h._suha_i > 0 and h._apparitions.size() > 0, "Suha whispers and appears at a distance")
		"suha":
			level.listener.hunt_enabled = false
			for i in 3:
				await use("Engage coupling %d" % (i + 1))
			await wait(9.5)
			expect(Game.has_flag("suha_call"), "Suha calls after the transmitter is armed")
			var lc: Vector3 = level.areas.lighthouse.C
			await level.travel(lc + Vector3(1.0, 12.2, 1.0), 0.0, "surface", "lighthouse")
			await use("Climb to the light")
			expect(Game.has_flag("chose_suha"), "followed her voice to the lantern room")
			await wait(40.0)
			expect(get_tree().current_scene.name == "Ending" and Game.ending_choice == "suha", "ending THE LIGHT (SUHA) reached")
		"voices":
			for id in ["elias_arrive", "suha_line_0", "boat_arrival_1", "suha_3_0", "ending_suha_4", "lodger_0", "rec_mayday", "teahouse_0"]:
				var d := Sound.voice(id)
				expect(d > 0.8, "voice line %s plays (%.1fs)" % [id, d])
			expect(Sound.voice("boat_arrival_2") == 0.0, "narration lines stay text-only")
		"optional":
			await _optional()
		"seal":
			var caves = level.areas.caves
			await tp(caves._p(0, -33.3, 0.3))
			print("player at ", p.global_position, " horn ", caves._horn_pos, " recs ", Game.state.recordings)
			await replay("knocks")
			await replay("bell")
			await wait(3.0)
			expect(Game.has_flag("seal_open"), "bell opens seal")
		_:
			failures.append("unknown scenario " + name)
	for f in failures:
		print("[scenario] FAIL: ", f)
	return failures.is_empty()


# ------------------------------------------------------------------ helpers
func wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func physics(n := 4) -> void:
	for i in n:
		await get_tree().physics_frame


func tp(pos: Vector3) -> void:
	p.global_position = pos
	p.velocity = Vector3.ZERO
	await physics(6)


func expect(cond: bool, what: String) -> void:
	if cond:
		print("[scenario] ok: ", what)
	else:
		failures.append(what)


func find_use(prompt_part: String) -> Node:
	for n in get_tree().current_scene.find_children("*", "Interactable", true, false):
		if prompt_part.to_lower() in n.prompt.to_lower():
			return n
	return null


func use(prompt_part: String) -> bool:
	var it := find_use(prompt_part)
	if it == null:
		failures.append("no interactable '%s'" % prompt_part)
		return false
	await tp(it.global_position + Vector3(0, -0.8, 0.0))
	it.interact(p)
	await wait(0.2)
	if level.hud.reading:
		level.hud.close_note()
	return true


func door(id: String) -> Door:
	for d in get_tree().current_scene.find_children("*", "Door", true, false):
		if d.id == id:
			return d
	return null


func open_door(id: String) -> void:
	var d := door(id)
	if d == null:
		failures.append("no door " + id)
		return
	await tp(d.global_position + d.global_transform.basis.z * 1.2)
	d.interact(p)
	await wait(1.4)


func record_here(listen: bool) -> void:
	var r: Node = p.recorder
	if listen:
		r.set_listening(true)
	await wait(0.7)
	r.set_panel(true)
	r.selected = 0
	r._use()
	await wait(r.RECORD_TIME + 0.5)
	r.set_panel(false)
	if listen:
		r.set_listening(false)


func replay(id: String) -> void:
	var r: Node = p.recorder
	r.cooldown = 0.0
	for i in Game.state.recordings.size():
		if Game.state.recordings[i].id == id:
			r.set_panel(true)
			r.selected = i + 1
			r._use()
			r.set_panel(false)
			await wait(1.5)
			return
	failures.append("no recording " + id)


# ------------------------------------------------------------------ full run
func _full(ending: String) -> void:
	# A — dock
	await tp(Vector3(-0.75, 1.6, 111))
	expect(Game.has_flag("left_boat"), "stepping onto the dock sets left_boat")
	await tp(Vector3(0, 1.6, 100))
	expect(Game.has_flag("dock_echo"), "dock footstep pre-echo triggers")
	await open_door("shed")
	await use("field recorder")
	expect(Game.has_flag("has_recorder"), "recorder taken")
	expect(Game.state.objective == "try_listen", "objective -> try_listen")
	await tp(level.areas.dock.global_position + Vector3(7.5, 2.2, 72))
	p.recorder.set_listening(true)
	await wait(7.0)
	expect(Game.state.objective == "record_echo", "listening advances to record_echo")
	p.recorder.set_listening(false)
	await record_here(true)
	expect(Game.has_recording("dock_steps"), "recorded the shed footsteps (listen-only source)")
	expect(Game.state.objective == "go_inland", "objective -> go_inland")
	# B — settlement
	await tp(Vector3(0, 4.5, 62))
	expect(Game.has_flag("entered_settlement"), "entered settlement")
	expect(Game.state.objective == "find_key", "objective -> find_key")
	await open_door("teahouse")
	await tp(Vector3(-9, 4.6, 50))
	expect(Game.has_flag("heard_teahouse"), "teahouse radio plays")
	await record_here(false)
	expect(Game.has_recording("knocks"), "recorded the three knocks")
	await open_door("bluehouse")
	await use("clock case")
	expect(Game.has_flag("has_station_key"), "station key from the clock")
	expect(Game.state.objective == "reach_station", "objective -> reach_station")
	await wait(6.5)
	expect(level.listener.is_active(), "The Listener arrives after the bell")
	level.listener.hunt_enabled = false
	# replay lure: the echo should pull it toward the recording's origin (the shed)
	await tp(Vector3(9, 4.6, 40))
	level.listener.global_position = Vector3(-2, 4.5, 30)
	level.listener._change(level.listener.S.ROAMING)
	await replay("dock_steps")
	expect(level.listener.state == level.listener.S.INVESTIGATING, "replayed echo makes The Listener investigate")
	expect(level.listener.target.z > 60.0, "it heads toward the echo's origin (the shed), target z=%.1f" % level.listener.target.z)
	# C — station
	await open_door("station_gate")
	expect(Game.has_flag("reached_station"), "station gate opened with key")
	expect(Game.state.objective == "restore_power", "objective -> restore_power")
	await open_door("gen_room")
	await use("starter cord")
	await wait(2.2)
	expect(not Game.has_flag("station_power"), "generator fails without fuel")
	await use("fuel valve")
	await use("starter cord")
	await wait(3.0)
	expect(Game.has_flag("station_power"), "generator starts with fuel open")
	expect(Game.state.objective == "find_sequence", "objective -> find_sequence")
	await open_door("station_main")
	await open_door("st_office")
	await tp(level.areas.station.ORIGIN + Vector3(-1.6, 1.0, 3.0))
	await record_here(true)
	expect(Game.has_recording("tape_13"), "recorded calibration tape 13 while listening")
	await open_door("st_corridor")
	# wrong order trips the breaker and resets
	await use("relay A")
	await wait(1.5)
	expect(level.areas.station._blackout, "wrong relay order trips the breaker")
	await wait(6.5)
	expect(not level.areas.station._blackout, "breaker resets (no soft-lock)")
	for idx in [1, 0, 2, 0]:
		await use("relay " + ["A", "B", "C"][idx])
		await wait(0.3)
	await wait(1.6)
	expect(Game.has_flag("relays_ok"), "correct sequence B-A-C-A locks the relays")
	await use("Transmit the diagnostic")
	await wait(13.0)
	expect(Game.has_flag("tide_out"), "transmission pulls the tide out")
	await wait(12.0)
	expect(Game.state.objective == "find_caves", "objective -> find_caves")
	expect(level.ocean.position.y < -2.0, "ocean has dropped (y=%.2f)" % level.ocean.position.y)
	# D — caves (walk onto the exposed shelf and into the mouth)
	await tp(Vector3(65.5, Terrain.height(65.5, -40) + 0.5, -40))
	await wait(0.5)
	expect(p.global_position.z < -35.0, "the tidal shelf is walkable at low tide")
	await tp(Vector3(66, Terrain.height(66, -50.3) + 0.6, -50.3))
	await wait(2.0)
	expect(Game.has_flag("found_caves"), "cave mouth found")
	expect(level.space == "caves", "travelled into the caves")
	var caves = level.areas.caves
	await tp(caves._p(caves.BELL.x + 1.5, caves.BELL.y, 0.3))
	await record_here(true)
	expect(Game.has_recording("bell"), "recorded the drowned bell while listening")
	await tp(caves._p(0, -33.3, 0.3))
	await replay("knocks")
	expect(not Game.has_flag("seal_open"), "the wrong recording doesn't open the seal")
	await replay("bell")
	await wait(3.0)
	expect(Game.has_flag("seal_open"), "replaying the bell into the horn opens the seal")
	await tp(caves._p(0, -40, 0.3))
	await wait(6.0)
	expect(level.listener.is_active(), "The Listener patrols the gallery")
	await tp(caves._p(caves.PLATE.x, caves.PLATE.y, 0.3))
	await record_here(false)
	expect(Game.has_recording("plate"), "recorded the loose plate")
	await use("iron stair")
	await wait(2.0)
	expect(Game.has_flag("reached_lighthouse"), "climbed into the lighthouse")
	expect(level.space == "surface", "back on the surface inside the tower")
	# E — lighthouse
	await tp(level.areas.lighthouse.C + Vector3(2.0, 12.3, -1.0))
	await wait(1.0)
	await use("seal release")
	expect(Game.has_flag("seal_released"), "seal released from the control room")
	await use("Descend to the lower level")
	await wait(2.5)
	expect(level.space == "chamber", "descended to the chamber")
	expect(level.listener.is_active(), "The Listener is in the chamber")
	level.listener.hunt_enabled = false
	for i in 3:
		await use("Engage coupling %d" % (i + 1))
	await wait(2.5)
	expect(Game.has_flag("armed"), "all couplings engaged -> armed")
	expect(Game.state.objective == "choose", "objective -> choose")
	if ending == "break":
		await use("OVERLOAD")
		await wait(7.0)
		expect(Game.has_flag("chose_break"), "chose to break the signal")
	else:
		await use("TRANSMIT to the mainland")
		await wait(9.5)
		expect(Game.has_flag("chose_send"), "chose to send the warning")
	expect(Game.state.objective == "return_boat", "objective -> return_boat")
	await use("Climb back up")
	await wait(2.0)
	await use("Lift the bar")
	await open_door("lh_front")
	await use("Unhook the chain")
	expect(Game.has_flag("gate_unchained"), "gate unchained from the north side")
	await open_door("lh_gate")
	await tp(Vector3(5.6, 1.6, 108))
	var leave := find_use("leave Vey Isle")
	expect(leave != null and leave.enabled, "boat departure is available")
	leave.interact(p)
	print("[scenario] boat departing; waiting for ending scene")
	await wait(22.0)
	var scene_name := get_tree().current_scene.name if get_tree().current_scene else ""
	expect(scene_name == "Ending", "ending scene reached (got '%s')" % scene_name)
	expect(Game.ending_choice == ending, "ending choice recorded as " + ending)


## Walk with real movement input toward each waypoint (xz). Doors on the
## way are opened as a player would. Fails if progress stalls.
func _walk(points: Array) -> void:
	p.freeze(false)
	for wp in points:
		var target: Vector3 = wp
		var limit: float = Vector2(p.global_position.x - target.x, p.global_position.z - target.z).length() / 2.0 + 6.0
		var t := 0.0
		var last := p.global_position
		var still := 0.0
		Input.action_press("move_forward")
		while Vector2(p.global_position.x - target.x, p.global_position.z - target.z).length() > 0.8:
			await get_tree().physics_frame
			var d := 1.0 / Engine.physics_ticks_per_second
			t += d
			var to := target - p.global_position
			p._yaw = atan2(-to.x, -to.z)
			if p._focus is Door and not p._focus.is_open and p._focus.can_interact():
				p._focus.interact(p)
			if p.global_position.distance_to(last) < 0.02:
				still += d
			else:
				still = 0.0
			last = p.global_position
			if still > 2.5 or t > limit:
				failures.append("walk stalled at %s heading to %s" % [p.global_position, target])
				for i in p.get_slide_collision_count():
					var col = p.get_slide_collision(i)
					var o = col.get_collider()
					print("[scenario]   colliding: ", o, " ", o.get_parent().name if o else "", " at ", col.get_position(), " n=", col.get_normal())
				Input.action_release("move_forward")
				return
		print("[scenario] ok: reached ", target, " in %.1fs" % t)
	Input.action_release("move_forward")


# ------------------------------------------------------------------ optional chapters + third ending
func _optional() -> void:
	# Ship graveyard: the radio switches on, then the mayday can be recorded
	var gy = level.areas.graveyard
	var radio := find_use("Examine the radio")
	await tp(radio.global_position + Vector3(-1.5, -0.8, -1.0))
	await wait(3.0)
	expect(Game.has_flag("graveyard_radio"), "ship radio incident fires")
	await tp(radio.global_position + Vector3(-1.2, -0.8, -0.6))
	await record_here(false)
	expect(Game.has_recording("mayday"), "recorded the Pelagic mayday (last recording 2/3)")
	# Blackwood: Kell's hut, the roost, the tape, the chase, the floodlight
	var forest = level.areas.forest
	expect(forest.kell.state == forest.kell.S.ROOST, "Kell is asleep in the roost")
	await tp(forest.roost_mouth() + Vector3(0, 0.6, 0.4))
	await wait(2.5)
	expect(level.space == "roost", "entered the Roost")
	await use("Take Kell's tape")
	expect(Game.has_recording("kell_tape"), "took Kell's tape (last recording 3/3)")
	await wait(2.0)
	expect(forest.kell.chase and forest.kell.state != forest.kell.S.ROOST, "taking the tape wakes Kell: chase")
	await use("Climb back out")
	await wait(2.0)
	await use("Throw the floodlight switch")
	expect(forest.floodlight_on, "tower floodlight on")
	for i in 40:
		await wait(0.5)
		if Game.has_flag("kell_dead"):
			break
	expect(Game.has_flag("kell_dead"), "Kell flies into the floodlight and dies")
	# Low Vey at low tide: the thirteen seconds
	await tp(Vector3(67, Terrain.height(67, -20) + 0.4, -20))
	await wait(19.0)
	expect(Game.has_flag("lowvey_silence"), "Low Vey's thirteen-second silence plays out")
	# the Annex: Morrow's tape and the chase
	var cp: Array = level.checkpoints["annex"]
	await level.travel(cp[0], cp[1], "annex", "station_in")
	await use("Play and record Dr. Morrow's tape")
	expect(Game.has_recording("morrow_tape"), "recorded Morrow's tape (last recording 1/3)")
	p.set_safe(true)
	await wait(7.5)
	expect(level.listener.is_active(), "the Listener comes down the annex corridor")
	level.listener.hunt_enabled = false
	p.set_safe(false)
	await use("Climb back up to the caves")
	await wait(2.0)
	expect(level.space == "caves" and not level.listener.is_active(), "escaped the annex back into the caves")
	expect(Game.last_recording_complete(), "all three parts of the last recording")
	# The chamber: the secret third choice
	Game.set_flag("seal_released")
	cp = level.checkpoints["chamber"]
	await level.travel(cp[0], cp[1], "chamber", "chamber")
	level.areas.chamber.enter()
	level.listener.hunt_enabled = false
	for i in 3:
		await use("Engage coupling %d" % (i + 1))
	await wait(2.5)
	await use("PLAY THE LAST RECORDING")
	await wait(36.0)
	expect(Game.has_flag("chose_last"), "chose THE LAST RECORDING")
	expect(Game.state.objective == "return_boat", "objective -> return_boat")
	await tp(Vector3(5.6, 1.6, 108))
	var leave := find_use("leave Vey Isle")
	expect(leave != null and leave.enabled, "boat departure available after the last recording")
	leave.interact(p)
	await wait(22.0)
	expect(get_tree().current_scene.name == "Ending" and Game.ending_choice == "last", "ending THE LAST RECORDING reached")


# ------------------------------------------------------------------ AI
func _ai() -> void:
	var l = level.listener
	l.hunt_enabled = true
	var base := Vector3(-2, 4.4, 30)
	l.activate(base, [base, Vector3(4, 4.2, 47)])
	await physics(10)
	expect(l.state == l.S.ROAMING, "activates into ROAMING")
	await tp(Vector3(-10, 4.6, 50))
	p.freeze(true)
	Sound.emit_noise(Vector3(4, 4.3, 40), 16.0, "footstep")
	await physics(2)
	expect(l.state == l.S.INVESTIGATING, "sprint-loud noise -> INVESTIGATING")
	l.global_position = base
	l._change(l.S.ROAMING)
	Sound.emit_noise(Vector3(14, 4.3, 50), 1.5, "footstep")
	await physics(2)
	expect(l.state == l.S.ROAMING, "crouched footstep far away is not heard")
	# sight: stand in front of it with the flashlight on
	await tp(base + Vector3(0, 0.2, 4.0))
	l.look_at(Vector3(p.global_position.x, l.global_position.y, p.global_position.z), Vector3.UP, true)
	l.model.head.rotation = Vector3.ZERO
	p.flashlight_on = true
	for i in 120:
		await get_tree().physics_frame
		if l.state == l.S.HUNTING:
			break
	expect(l.state == l.S.HUNTING, "seeing the player -> HUNTING")
	# safe room breaks the hunt
	if not p.dead:
		p.set_safe(true)
		await physics(3)
		expect(l.state == l.S.SEARCHING, "player in a safe room -> SEARCHING")
	await wait(10.5)
	expect(l.state in [l.S.RETURNING, l.S.ROAMING], "search times out -> RETURNING/ROAMING (state %s)" % l.NAMES[l.state])
	p.set_safe(false)
	l.deactivate()


func _death() -> void:
	var l = level.listener
	l.hunt_enabled = true
	await tp(Vector3(-2, 4.6, 33))
	l.activate(Vector3(-2, 4.4, 30.5), [Vector3(-2, 4.4, 30.5)])
	l.look_at(Vector3(p.global_position.x, l.global_position.y, p.global_position.z), Vector3.UP, true)
	p.flashlight_on = true
	await wait(5.0)
	expect(p.dead or not is_instance_valid(p), "the player is caught")
	await wait(6.0)
	var lv := get_tree().current_scene
	expect(lv != level and lv.name == "Island", "the level reloads from the checkpoint")
	expect(lv.player.global_position.distance_to(lv.checkpoints[Game.state.checkpoint][0]) < 1.5, "respawned at checkpoint " + Game.state.checkpoint)
