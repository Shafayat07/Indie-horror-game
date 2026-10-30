extends Node
## The battered field recorder: the game's central tool.
##  LISTEN (Q)  — filters the ambience and opens the ListenOnly bus, so
##                pre-echoes and hidden sources become audible.
##  RECORD      — capture a nearby recordable source (some only exist while listening).
##  REPLAY      — play a recording through the small speaker. On Vey Isle the
##                sound then RETURNS to the place it was recorded, loudly. That
##                echo is how you lure The Listener away — but the speaker itself
##                is audible too, so careless replay gives you away.

signal listen_toggled(on: bool)
signal recorded(id: String)
signal replayed(id: String, origin: Vector3)

const RECORD_TIME := 2.4
const REPLAY_COOLDOWN := 5.0

var player: Node3D
var has_recorder := false
var listening := false
var panel_open := false
var selected := 0             # 0 = "record new", 1.. = recordings
var recording_progress := -1.0
var cooldown := 0.0
var _hiss: AudioStreamPlayer
var _model: Node3D
var _led: MeshInstance3D
var _rec_target: Node3D


func setup(p: Node3D) -> void:
	player = p
	has_recorder = Game.has_flag("has_recorder")
	_hiss = AudioStreamPlayer.new()
	_hiss.stream = Sound.get_stream("amb_tape")
	_hiss.bus = "UI"
	_hiss.volume_db = -80.0
	add_child(_hiss)
	_build_model()


func _build_model() -> void:
	_model = Node3D.new()
	player.camera.add_child(_model)
	_model.position = Vector3(0.24, -0.26, -0.42)
	_model.rotation_degrees = Vector3(8, -14, 0)
	var body_m := B.mat("metal_green", Color(0.75, 0.8, 0.75), 2.0, {"world": false})
	var dark := B.flat(Color(0.05, 0.05, 0.05), 0.5)
	B.box(_model, Vector3.ZERO, Vector3(0.11, 0.19, 0.045), body_m, {"collide": false, "shadow": false})
	B.box(_model, Vector3(0, 0.04, 0.024), Vector3(0.08, 0.06, 0.005), B.glow(Color(0.35, 0.55, 0.4), 0.6), {"collide": false})
	B.box(_model, Vector3(0, -0.05, 0.024), Vector3(0.085, 0.06, 0.006), dark, {"collide": false})  # speaker grille
	for i in 4:
		B.box(_model, Vector3(-0.035 + i * 0.023, 0.1, 0.0), Vector3(0.016, 0.012, 0.03), dark, {"collide": false})
	B.cyl(_model, Vector3(0.035, 0.12, 0), 0.006, 0.08, dark, {"collide": false})  # antenna
	_led = B.box(_model, Vector3(-0.04, 0.085, 0.024), Vector3(0.01, 0.01, 0.006), B.glow(Color(1, 0.1, 0.05), 3.0, true), {"collide": false})
	_led.visible = false
	for c in _model.get_children():
		if c is GeometryInstance3D:
			c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_model.visible = false


func give() -> void:
	has_recorder = true
	Game.set_flag("has_recorder")


func _unhandled_input(event: InputEvent) -> void:
	if not has_recorder or not player.input_enabled or player.dead:
		return
	if event.is_action_pressed("listen"):
		set_listening(not listening)
	elif event.is_action_pressed("recorder"):
		set_panel(not panel_open)
	elif panel_open and (event.is_action_pressed("rec_wheel_down") or event.is_action_pressed("rec_next")):
		_cycle(1)
	elif panel_open and event.is_action_pressed("rec_wheel_up"):
		_cycle(-1)
	elif panel_open and event.is_action_pressed("rec_use"):
		_use()
	elif event is InputEventKey and event.pressed and panel_open and event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_9:
		selected = clamp(event.physical_keycode - KEY_1, 0, Game.state.recordings.size())
		_refresh()


func set_listening(on: bool) -> void:
	if listening == on:
		return
	listening = on
	Sound.set_listen(on)
	Sound.play_2d("rec_button", -6.0, "UI")
	var tw := create_tween()
	tw.tween_property(_hiss, "volume_db", -32.0 if on else -80.0, 0.4)
	_update_model()
	if player.hud:
		player.hud.set_listen(on)
	listen_toggled.emit(on)


func set_panel(on: bool) -> void:
	panel_open = on
	Sound.play_2d("rec_button", -8.0, "UI")
	if not on:
		recording_progress = -1.0
	_update_model()
	_refresh()


func _update_model() -> void:
	_model.visible = listening or panel_open
	_led.visible = listening or recording_progress >= 0.0


func _cycle(d: int) -> void:
	var n: int = Game.state.recordings.size() + 1
	selected = (selected + d + n) % n
	Sound.play_2d("ui_click", -14.0, "UI")
	_refresh()


func _refresh() -> void:
	if player.hud:
		player.hud.update_recorder(panel_open, selected, recording_progress, cooldown, listening)


func _process(delta: float) -> void:
	if cooldown > 0.0:
		cooldown = max(cooldown - delta, 0.0)
		_refresh()
	if recording_progress >= 0.0:
		if _rec_target == null or not is_instance_valid(_rec_target) or player.global_position.distance_to(_rec_target.global_position) > _rec_target.radius + 1.5 \
				or (_rec_target.listen_only and not listening):
			recording_progress = -1.0
			Sound.play_2d("tape_stop", -6.0, "UI")
			player.hud.toast("Recording lost.")
			_update_model()
		else:
			recording_progress += delta / RECORD_TIME
			if recording_progress >= 1.0:
				_finish_recording()
		_refresh()


func _find_source() -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for s in get_tree().get_nodes_in_group("recordable"):
		if not s.is_active():
			continue
		var d: float = player.global_position.distance_to(s.global_position)
		if d <= s.radius and d < best_d:
			if s.listen_only and not listening:
				continue
			best = s
			best_d = d
	return best


func nearby_hint() -> String:
	## Used by the HUD: is there something here worth recording?
	var s := _find_source()
	if s and not Game.has_recording(s.id):
		return "Something here can be recorded."
	return ""


func _use() -> void:
	if selected == 0:
		if recording_progress >= 0.0:
			return
		var s := _find_source()
		if s == null:
			Sound.play_2d("rec_button", -8.0, "UI")
			var any_hidden := false
			for r in get_tree().get_nodes_in_group("recordable"):
				if r.listen_only and r.is_active() and player.global_position.distance_to(r.global_position) <= r.radius:
					any_hidden = true
			player.hud.toast("Only hiss. Try listening first. [Q]" if any_hidden else "Only hiss. Nothing worth recording here.")
			return
		if Game.has_recording(s.id):
			player.hud.toast("Already recorded: " + Story.RECORDINGS[s.id].name)
			return
		_rec_target = s
		recording_progress = 0.0
		Sound.play_2d("tape_start", -6.0, "UI")
		_update_model()
	else:
		_replay(selected - 1)


func _finish_recording() -> void:
	recording_progress = -1.0
	var id: String = _rec_target.id
	Game.add_recording(id, _rec_target.global_position)
	Sound.play_2d("tape_stop", -6.0, "UI")
	player.hud.toast("Recorded:  " + Story.RECORDINGS[id].name)
	selected = Game.state.recordings.size()
	_update_model()
	_refresh()
	recorded.emit(id)


func _replay(index: int) -> void:
	if index < 0 or index >= Game.state.recordings.size():
		return
	if cooldown > 0.0:
		player.hud.toast("The tape is still rewinding.")
		return
	var rec: Dictionary = Game.state.recordings[index]
	var info: Dictionary = Story.RECORDINGS[rec.id]
	var origin := Vector3(rec.origin[0], rec.origin[1], rec.origin[2])
	cooldown = REPLAY_COOLDOWN
	Sound.play_2d("tape_start", -8.0, "UI")
	# The small speaker: quiet, but The Listener can still hear it nearby.
	var here: Vector3 = player.global_position
	Sound.play_at(info.sound, here + Vector3(0, 1.2, 0), -10.0, {"unit_size": 2.0})
	Sound.emit_noise(here, 8.0, "replay")
	Sound.say(info.caption + "  (recorder speaker)", "sfx", 3.0)
	get_tree().call_group("replay_receivers", "on_replay", rec.id, here)
	replayed.emit(rec.id, origin)
	# ...and then the island gives the sound back where it belongs.
	await get_tree().create_timer(0.9).timeout
	Sound.play_at(info.sound, origin + Vector3(0, 1.0, 0), 6.0, {"unit_size": 14.0, "max_distance": 160.0, "bus": "PreEcho"})
	Sound.emit_noise(origin, 60.0, "replay_echo")
	var dist := here.distance_to(origin)
	if dist > 6.0:
		Sound.say("[the same sound answers — from where it was recorded, %s]" % _direction_word(origin), "preecho", 4.0)


func _direction_word(origin: Vector3) -> String:
	var to := origin - player.global_position
	var fwd: Vector3 = -player.global_transform.basis.z
	var right: Vector3 = player.global_transform.basis.x
	var a := atan2(to.dot(right), to.dot(fwd))
	var word := "ahead"
	if abs(a) > 2.3:
		word = "behind you"
	elif a > 0.6:
		word = "to your right"
	elif a < -0.6:
		word = "to your left"
	return ("far away, " + word) if to.length() > 50.0 else word
