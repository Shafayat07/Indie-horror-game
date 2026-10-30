extends Node3D
## THE TRANSMITTER CHAMBER — the finale beneath the lighthouse.
## Three couplings must be engaged before the console will accept a choice.
## Every coupling clanks BEFORE you touch it, and The Listener walks to that
## sound. Let it look, hide behind the pillars, then pull — or send it away
## with a replayed recording of the valve. Then choose: overload, or transmit.

const O := Vector3(0, -200, -260)   # must match island.CHAMBER_ORIGIN
const R := 14.0
const COUPLINGS := [Vector3(11.5, 0, -5.5), Vector3(-11.5, 0, -5.5), Vector3(0, 0, -12.8)]
const VALVE := Vector3(-11.0, 0, 6.5)

var level: Node
var _core_light: OmniLight3D
var _core_mat: StandardMaterial3D
var _coupling_lamps: Array[MeshInstance3D] = []
var _emergency: Array[OmniLight3D] = []
var _choice_made := false
var _transmitter: Node3D


func build(lv: Node) -> void:
	level = lv
	add_to_group("navsrc_chamber")
	level.checkpoints["chamber"] = [O + Vector3(0, 0.2, 12.0), 0.0, "chamber"]
	_hall()
	_build_transmitter()
	_couplings()
	_console()
	var ladder := Interactable.make(self, O + Vector3(0, 1.2, 13.4), Vector3(1.6, 2.4, 0.6), "Climb back up to the lighthouse")
	ladder.used.connect(func(_p):
		var cp: Array = level.checkpoints["aftermath" if _choice_made or Game.has_flag("chose_break") or Game.has_flag("chose_send") else "lighthouse"]
		level.travel(cp[0], cp[1], "surface", "lighthouse"))
	Zone.make(self, O + Vector3(0, 3, 0), Vector3(30, 10, 30), {"ambience": "chamber", "reverb": 0.5})
	P.note(self, O + Vector3(1.2, 1.12, 4.3), "marrow_final", 180)
	P.examine(self, O + Vector3(-1.0, 1.3, 3.8), Vector3(0.6, 0.4, 0.3), "chamber_dial")


func _hall() -> void:
	var conc := B.mat("concrete", Color(0.6, 0.62, 0.6), 0.35)
	var rock := B.mat("rock_cave", Color.WHITE, 0.35)
	B.cyl(self, O + Vector3(0, -0.25, 0), R + 0.5, 0.5, B.mat("concrete", Color(0.45, 0.45, 0.43), 0.4), {"segments": 24, "surface": "stone"})
	B.cyl(self, O + Vector3(0, 8.2, 0), R + 0.5, 0.4, rock, {"segments": 24})
	var n := 24
	for i in n:
		var a := TAU * i / n
		var p := O + Vector3(sin(a) * (R + 0.3), 4.0, cos(a) * (R + 0.3))
		var w := B.box(self, p, Vector3(2 * PI * (R + 0.3) / n + 0.1, 8.0, 0.6), conc if i % 2 == 0 else rock, {"surface": "stone"})
		w.rotation.y = a
	# pillars for cover
	for i in 6:
		var a := TAU * i / 6.0 + PI / 6.0
		var p := O + Vector3(sin(a) * 7.8, 0, cos(a) * 7.8)
		B.box(self, p + Vector3(0, 4.0, 0), Vector3(1.3, 8.0, 1.3), conc, {"surface": "stone"})
		B.box(self, p + Vector3(0, 0.15, 0), Vector3(1.6, 0.3, 1.6), conc, {"collide": false})
	# emergency lamps
	for i in 8:
		var a := TAU * i / 8.0
		var p := O + Vector3(sin(a) * (R - 0.4), 5.5, cos(a) * (R - 0.4))
		B.box(self, p, Vector3(0.3, 0.2, 0.2), B.glow(Color(1.0, 0.12, 0.06), 2.5), {"collide": false})
		var l := B.omni(self, p + Vector3(0, -0.3, 0), Color(1.0, 0.18, 0.1), 1.5, 11.0)
		_emergency.append(l)
	# cables running from the walls to the transmitter
	var cable := B.flat(Color(0.04, 0.04, 0.04), 0.5)
	for i in 10:
		var a := TAU * i / 10.0
		var from := O + Vector3(sin(a) * (R - 0.5), 6.8, cos(a) * (R - 0.5))
		var to := O + Vector3(sin(a) * 1.6, 7.5, cos(a) * 1.6)
		var mid := (from + to) * 0.5
		var c := B.box(self, mid, Vector3(0.12, 0.12, from.distance_to(to)), cable, {"collide": false})
		c.look_at_from_position(mid, to, Vector3.UP)
	# entry ladder
	var iron := B.mat("metal_rust", Color(0.7, 0.7, 0.7), 1.0, {"metallic": 0.5})
	for sx in [-0.4, 0.4]:
		B.box(self, O + Vector3(sx, 4.0, 13.6), Vector3(0.06, 8.0, 0.06), iron, {"collide": false})
	for k in 16:
		B.box(self, O + Vector3(0, 0.3 + k * 0.5, 13.6), Vector3(0.8, 0.04, 0.04), iron, {"collide": false})
	# the valve that hammers: a lure to record
	var pipe := B.cyl(self, O + VALVE + Vector3(0, 1.0, 0), 0.15, 2.0, iron, {"collide": true})
	B.cyl(self, O + VALVE + Vector3(0.0, 1.4, 0.2), 0.18, 0.04, B.flat(Color(0.5, 0.1, 0.08), 0.5, 0.6), {"collide": false, "rot": Vector3(90, 0, 0)})
	Recordable.make(self, O + VALVE + Vector3(0, 1.2, 0), "valve", "metal_knock", {"radius": 5.0, "interval": 16.0, "volume": -9.0, "unit_size": 4.0})
	P.note(self, O + VALVE + Vector3(0.9, 1.4, 0.0), "control_note", 90, true)


func _build_transmitter() -> void:
	_transmitter = Node3D.new()
	add_child(_transmitter)
	_transmitter.position = O
	var copper := B.mat("metal_rust", Color(1.4, 0.95, 0.6), 1.0, {"metallic": 0.8, "roughness": 0.6})
	var dark := B.mat("metal_green", Color(0.5, 0.55, 0.5), 1.0, {"metallic": 0.5})
	B.cyl(_transmitter, Vector3(0, 0.4, 0), 2.6, 0.8, dark, {"segments": 16, "surface": "metal"})
	B.cyl(_transmitter, Vector3(0, 3.5, 0), 0.7, 5.6, dark, {"segments": 12})
	for i in 7:
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.9 + (i % 2) * 0.15
		tm.outer_radius = 1.25 + (i % 2) * 0.15
		tm.rings = 24
		tm.ring_segments = 8
		ring.mesh = tm
		ring.material_override = copper
		_transmitter.add_child(ring)
		ring.position.y = 1.4 + i * 0.7
	# glowing core tubes
	_core_mat = B.glow(Color(1.0, 0.55, 0.2), 2.0).duplicate()
	for i in 4:
		var a := TAU * i / 4.0
		B.cyl(_transmitter, Vector3(sin(a) * 1.5, 2.0, cos(a) * 1.5), 0.12, 2.4, _core_mat, {"collide": false})
	var dish := B.cyl(_transmitter, Vector3(0, 6.6, 0), 2.2, 0.6, copper, {"collide": false, "top": 0.4, "segments": 16})
	dish.rotation_degrees.x = 180
	_core_light = B.omni(_transmitter, Vector3(0, 3.0, 0), Color(1.0, 0.55, 0.25), 2.0, 14.0, true)
	Sound.attach_loop(_transmitter, "amb_signal", 0.0, {"unit_size": 6.0, "max_distance": 40.0, "offset": Vector3(0, 3, 0)})
	Sound.attach_loop(_transmitter, "amb_drone", -4.0, {"unit_size": 6.0, "max_distance": 40.0, "offset": Vector3(0, 2, 0)})


func _couplings() -> void:
	var iron := B.mat("metal_red", Color(0.7, 0.6, 0.6), 1.0, {"metallic": 0.5})
	for i in COUPLINGS.size():
		var p: Vector3 = O + COUPLINGS[i]
		var c := Node3D.new()
		add_child(c)
		c.position = p
		c.look_at(Vector3(O.x, p.y, O.z), Vector3.UP)
		B.box(c, Vector3(0, 0.9, 0), Vector3(1.4, 1.8, 0.8), iron, {"surface": "metal"})
		var handle := Node3D.new()
		c.add_child(handle)
		handle.position = Vector3(0, 1.3, -0.45)
		B.box(handle, Vector3(0, 0.3, 0), Vector3(0.08, 0.6, 0.08), B.flat(Color(0.25, 0.25, 0.25), 0.4, 0.8), {"collide": false})
		handle.rotation_degrees.x = 35
		var lamp := B.box(c, Vector3(0, 1.75, -0.41), Vector3(0.18, 0.18, 0.02), B.glow(Color(0.6, 0.08, 0.04), 1.2), {"collide": false})
		_coupling_lamps.append(lamp)
		B.label(c, Vector3(0, 1.55, -0.42), "COUPLING %d" % (i + 1), 26, Color(0.85, 0.8, 0.7), Vector3(0, 180, 0))
		var it := Interactable.make(c, Vector3(0, 1.2, -0.5), Vector3(1.0, 1.2, 0.4), "Engage coupling %d" % (i + 1))
		it.used.connect(_engage.bind(i, handle))
		if Game.has_flag("coupling_%d" % i):
			handle.rotation_degrees.x = -35
			lamp.material_override = B.glow(Color(1.0, 0.7, 0.3), 3.0)
		# The pre-echo: it clanks as you approach. The Listener goes to it.
		var idx := i
		Zone.make(self, p + Vector3(0, 1.0, 0), Vector3(9.0, 3.0, 9.0), {"once": true, "block": "coupling_%d" % i, "on_enter": func(_b):
			if Game.has_flag("coupling_%d" % idx):
				return
			Sound.pre_echo("coupling", p + Vector3(0, 1.2, 0), "[coupling %d clanks into place — you haven't touched it]" % (idx + 1), 2.0, 45.0)})


func _engage(_p: Node, i: int, handle: Node3D) -> void:
	if Game.has_flag("coupling_%d" % i):
		level.hud.toast("Already engaged.")
		return
	Game.set_flag("coupling_%d" % i)
	var tw := create_tween()
	tw.tween_property(handle, "rotation_degrees:x", -35.0, 0.25)
	Sound.play_at("coupling", handle.global_position, 2.0, {"unit_size": 8.0})
	Sound.emit_noise(handle.global_position, 28.0, "machine")
	_coupling_lamps[i].material_override = B.glow(Color(1.0, 0.7, 0.3), 3.0)
	level.player.shake(0.4)
	Game.objective_changed.emit(Game.state.objective)
	_update_core()
	if _count() >= 3:
		await get_tree().create_timer(2.0).timeout
		_armed()
	else:
		Game.save_checkpoint("chamber")


func _count() -> int:
	var n := 0
	for i in 3:
		if Game.has_flag("coupling_%d" % i):
			n += 1
	return n


func _update_core() -> void:
	var k := float(_count()) / 3.0
	_core_light.light_energy = 3.0 + k * 4.0
	_core_mat.emission_energy_multiplier = 2.0 + k * 6.0


func _armed() -> void:
	Game.set_flag("armed")
	level.objective("choose")
	Game.save_checkpoint("chamber")
	Sound.play_at("transmit_surge", O + Vector3(0, 3, 0), -8.0, {"pitch": 0.5})
	# It stops. It turns its head to you. It is listening for what you will say.
	if level.listener.is_active():
		level.listener.frozen = true
		level.listener.head_target = level.player.head.global_position
		level.listener.hunt_enabled = false
	level.hud.toast("The console wakes. It has stopped moving. It is listening.", 4.0)
	await get_tree().create_timer(6.0).timeout
	if not _choice_made:
		Game.set_flag("suha_call")
		Sound.play_2d("radio_burst", -4.0)
		level.hud.radio("suha_3")
		Game.add_journal("j_suha")


func _console() -> void:
	var desk := B.mat("metal_green", Color(0.6, 0.65, 0.6), 1.0, {"metallic": 0.4})
	var c := Node3D.new()
	add_child(c)
	c.position = O + Vector3(0, 0, 4.2)
	B.box(c, Vector3(0, 0.55, 0), Vector3(2.6, 1.1, 0.9), desk, {"surface": "metal"})
	P.note(c, Vector3(0, 1.12, 0.1), "chamber_plate", 180)
	var lever := Node3D.new()
	c.add_child(lever)
	lever.position = Vector3(-0.8, 1.1, 0.1)
	B.box(lever, Vector3(0, 0.3, 0), Vector3(0.08, 0.6, 0.08), B.flat(Color(0.3, 0.3, 0.3), 0.4, 0.8), {"collide": false})
	B.sphere(lever, Vector3(0, 0.62, 0), 0.08, B.glow(Color(0.9, 0.08, 0.05), 2.0))
	var key := B.box(c, Vector3(0.8, 1.15, 0.1), Vector3(0.12, 0.1, 0.2), B.glow(Color(0.3, 0.9, 0.5), 1.5), {"collide": false})
	var a := Interactable.make(c, Vector3(-0.8, 1.4, 0.3), Vector3(0.5, 0.8, 0.5), "OVERLOAD the array  (red lever — irreversible)")
	var b := Interactable.make(c, Vector3(0.8, 1.3, 0.3), Vector3(0.5, 0.6, 0.5), "TRANSMIT to the mainland  (turn the key)")
	a.require_flag = "armed"
	b.require_flag = "armed"
	a.locked_text = "Dead. The couplings aren't engaged."
	b.locked_text = "Dead. The couplings aren't engaged."
	a.used.connect(func(_p): _choose("break", lever))
	# the secret third option: only if you carry all three parts of the last recording
	var c3 := Interactable.make(c, Vector3(0, 1.3, 0.3), Vector3(0.5, 0.5, 0.5), "PLAY THE LAST RECORDING into the transmitter")
	c3.require_flag = "armed"
	c3.locked_text = "Dead. The couplings aren't engaged."
	c3.used.connect(func(_p):
		if not Game.last_recording_complete():
			_p.hud.toast("You'd need all three parts of the last recording. (%d/3)" % Game.LAST_PARTS.filter(func(x): return Game.has_recording(x)).size())
			return
		_choose("last", c))
	b.used.connect(func(_p): _choose("send", key))
	Zone.make(self, O + Vector3(0, 1, 5.5), Vector3(4, 3, 3), {"once": true, "require": "armed", "on_enter": func(_b):
		Sound.pre_echo("whisper_0", level.player.global_position + level.player.global_transform.basis.z * 2.0 + Vector3(0, 1.6, 0), "[your own voice, right behind you: \"Don't.\"]", 0.0)})


func _choose(choice: String, handle: Node3D) -> void:
	if _choice_made or Game.has_flag("chose_break") or Game.has_flag("chose_send") or Game.has_flag("chose_last"):
		return
	_choice_made = true
	var p: Node = level.player
	p.freeze(true)
	if choice == "break":
		var tw := create_tween()
		tw.tween_property(handle, "rotation_degrees:x", 70.0, 0.3)
		Sound.play_at("transmit_surge", O + Vector3(0, 3, 0), 0.0, {"pitch": 1.4})
		await get_tree().create_timer(2.0).timeout
		Sound.play_2d("overload", 2.0)
		level.hud.white_flash()
		p.shake(2.5)
		for l in _emergency:
			l.light_energy = 0.0
		_core_light.light_energy = 0.0
		_core_mat.emission_energy_multiplier = 0.0
		if level.listener.is_active():
			level.listener.model.collapse()
			level.listener.frozen = true
			level.listener._strings.stop()
		for s in _transmitter.find_children("*", "AudioStreamPlayer3D", true, false):
			s.stop()
		Game.set_flag("chose_break")
		Game.set_flag("gate_unchained_hint")
		Sound.override_zone("silence")
		await get_tree().create_timer(4.0).timeout
		Sound.say("[silence. Real silence, for the first time since you landed.]", "aside", 5.0)
		level.ocean.set_level(Ocean.HIGH, 90.0)
	elif choice == "last":
		# Morrow, the Pelagic, Kell: the island hears itself, and stops listening.
		for id in Game.LAST_PARTS:
			Sound.play_at(Story.RECORDINGS[id].sound, O + Vector3(0, 3, 0), 2.0, {"bus": "Voice"})
			Sound.say(Story.RECORDINGS[id].caption, "radio", 4.0)
			await get_tree().create_timer(4.2).timeout
		if level.listener.is_active():
			level.listener.head_target = O + Vector3(0, 3, 0)
			var lt := create_tween()
			lt.tween_property(level.listener, "global_position", O + Vector3(0, 0, 1.8), 4.0)
			await lt.finished
			level.listener.model.collapse()
		await level.horror.silence13()
		_core_light.light_color = Color(0.85, 0.92, 1.0)
		_core_mat.emission = Color(0.85, 0.92, 1.0)
		Game.set_flag("chose_last")
		Sound.override_zone("aftermath_break")
		Sound.say("[the transmitter is playing back the thirteen seconds — to itself]", "aside", 5.0)
	else:
		var tw := create_tween()
		tw.tween_property(handle, "rotation_degrees:z", 90.0, 0.3)
		Sound.play_at("transmit_surge", O + Vector3(0, 3, 0), 4.0)
		level.hud.radio("chamber_send")
		_core_light.light_energy = 9.0
		_core_mat.emission_energy_multiplier = 12.0
		p.shake(1.2)
		Game.set_flag("chose_send")
		get_tree().call_group("beacon", "flare")
		await get_tree().create_timer(3.0).timeout
		if level.listener.is_active():
			# It turns away from you, and walks into the dark.
			level.listener.head_target = null
			var lt := create_tween()
			lt.tween_property(level.listener, "global_position", level.listener.global_position + Vector3(0, 0, -6), 5.0)
			await lt.finished
			level.listener.deactivate()
		Sound.override_zone("aftermath_send")
	level.objective("return_boat")
	Game.save_checkpoint("aftermath")
	p.freeze(false)
	level.hud.toast("Climb back up. Return to the boat.", 4.0)


func on_spawn(cp: String) -> void:
	_update_core()
	if cp == "chamber":
		enter()
	if Game.has_flag("chose_break"):
		for l in _emergency:
			l.light_energy = 0.0
		_core_light.light_energy = 0.0
		_core_mat.emission_energy_multiplier = 0.0
		Sound.override_zone("silence")
	elif Game.has_flag("chose_send"):
		Sound.override_zone("aftermath_send")



## Called whenever the player arrives in the chamber (spawn or hatch).
func enter() -> void:
	level.chapter("ch_chamber")
	if not Game.has_flag("chose_break") and not Game.has_flag("chose_send") and not Game.has_flag("chose_last") and not level.listener.is_active():
		var pts: Array = []
		for i in 6:
			var a := TAU * i / 6.0
			pts.append(O + Vector3(sin(a) * 4.5, 0, cos(a) * 4.5))
		level.listener.activate(O + Vector3(0, 0, -5.0), pts)
		level.listener.hearing = 1.0
		if Game.has_flag("armed"):
			level.listener.frozen = true
			level.listener.hunt_enabled = false
	# first arrival in the chamber
	if not Game.has_flag("chamber_intro"):
		Game.set_flag("chamber_intro")
		await get_tree().create_timer(1.5).timeout
		level.hud.toast("Three couplings. It walks to every sound — even ones that haven't happened yet.", 5.0)
