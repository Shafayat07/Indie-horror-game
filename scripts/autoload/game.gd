extends Node
## Global game state: progression flags, objectives, recordings, checkpoints,
## settings, input map and scene transitions. Everything the world needs to
## rebuild itself after a checkpoint reload lives in `state`.

signal flag_set(flag: String)
signal objective_changed(id: String)
signal recordings_changed
signal settings_changed
signal journal_added(id: String)

const SAVE_PATH := "user://save.json"
const SETTINGS_PATH := "user://settings.cfg"
const GAME_SCENE := "res://scenes/island.tscn"
const MENU_SCENE := "res://scenes/main_menu.tscn"
const ENDING_SCENE := "res://scenes/ending.tscn"

var settings := {
	"mouse_sensitivity": 0.18,
	"master_volume": 0.85,
	"reduced_effects": false,
	"sfx_captions": false,
	"fov": 72.0,
	"volumetric_fog": true,
	"fullscreen": true,
	"invert_y": false,
	"hud_margin": 0.08,   # fraction of the screen kept clear at the edges
}

var state := {}
var debug_ai := false
var ending_choice := ""   # "break" or "send", consumed by the ending scene
var _fade: ColorRect
var _fade_layer: CanvasLayer
var _transitioning := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	debug_ai = "--debug-ai" in OS.get_cmdline_user_args() or "--debug-ai" in OS.get_cmdline_args()
	_setup_input()
	load_settings()
	_apply_window_mode.call_deferred()   # again once the window exists
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	add_child(_fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_layer.add_child(_fade)
	reset_state()


# ------------------------------------------------------------------ input
func _setup_input() -> void:
	var keys := {
		"move_forward": [KEY_W, KEY_UP], "move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"sprint": [KEY_SHIFT], "crouch": [KEY_CTRL, KEY_C], "interact": [KEY_E],
		"flashlight": [KEY_F], "listen": [KEY_Q], "recorder": [KEY_R],
		"pause": [KEY_ESCAPE], "jump": [KEY_SPACE],
		"rec_next": [KEY_TAB],
		"journal": [KEY_J], "watch": [KEY_T],
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
	var mouse := {"rec_use": MOUSE_BUTTON_LEFT, "rec_wheel_up": MOUSE_BUTTON_WHEEL_UP, "rec_wheel_down": MOUSE_BUTTON_WHEEL_DOWN}
	for action in mouse:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var mb := InputEventMouseButton.new()
		mb.button_index = mouse[action]
		InputMap.action_add_event(action, mb)


# ------------------------------------------------------------------ settings
func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		for k in settings:
			settings[k] = cfg.get_value("settings", k, settings[k])
	apply_settings()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for k in settings:
		cfg.set_value("settings", k, settings[k])
	cfg.save(SETTINGS_PATH)
	apply_settings()


func apply_settings() -> void:
	_apply_window_mode()
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(max(settings.master_volume, 0.0001)))
	settings_changed.emit()


# ------------------------------------------------------------------ fullscreen
func _apply_window_mode() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var want := DisplayServer.WINDOW_MODE_FULLSCREEN if settings.get("fullscreen", true) else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != want:
		DisplayServer.window_set_mode(want)


func toggle_fullscreen() -> void:
	settings.fullscreen = not settings.get("fullscreen", true)
	save_settings()


## F11 or Alt+Enter, anywhere in the game (menus and pause included).
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed) or (event.keycode == KEY_KP_ENTER and event.alt_pressed):
			toggle_fullscreen()
			get_viewport().set_input_as_handled()


# ------------------------------------------------------------------ state
func reset_state() -> void:
	state = {
		"flags": {},
		"objective": "leave_boat",
		"checkpoint": "dock_start",
		"recordings": [],      # Array of {id, origin:[x,y,z]}
		"documents": [],       # ids of notes read
		"journal": [],         # ids of Elias's journal entries unlocked
		"clock": 0.0,          # in-game seconds since 23:40
	}


# ------------------------------------------------------------------ clock & journal
const CLOCK_START := 23 * 3600 + 40 * 60
const CLOCK_SPEED := 6.0   # in-game seconds per real second (an hour every 10 minutes)


func clock_seconds() -> int:
	return int(CLOCK_START + float(state.get("clock", 0.0))) % 86400


func clock_text() -> String:
	var s := clock_seconds()
	return "%02d:%02d" % [s / 3600, (s / 60) % 60]


func minute_of_hour() -> int:
	return (clock_seconds() / 60) % 60


func add_journal(id: String) -> void:
	if not state.has("journal"):
		state.journal = []
	if id in state.journal:
		return
	state.journal.append(id)
	journal_added.emit(id)


## The three parts of the last recording (optional): unlocks the third ending.
const LAST_PARTS := ["morrow_tape", "mayday", "kell_tape"]


func last_recording_complete() -> bool:
	for p in LAST_PARTS:
		if not has_recording(p):
			return false
	return true


func has_flag(f: String) -> bool:
	return state.flags.has(f)


func set_flag(f: String) -> void:
	if state.flags.has(f):
		return
	state.flags[f] = true
	flag_set.emit(f)


func set_objective(id: String) -> void:
	if state.objective == id:
		return
	state.objective = id
	objective_changed.emit(id)


func objective_text() -> String:
	var t: String = Story.OBJECTIVES.get(state.objective, "")
	if state.objective == "arm_transmitter":
		var n := 0
		for i in 3:
			if has_flag("coupling_%d" % i):
				n += 1
		t += "  (%d/3)" % n
	return t


func add_recording(id: String, origin: Vector3) -> bool:
	for r in state.recordings:
		if r.id == id:
			return false
	state.recordings.append({"id": id, "origin": [origin.x, origin.y, origin.z]})
	recordings_changed.emit()
	return true


func has_recording(id: String) -> bool:
	for r in state.recordings:
		if r.id == id:
			return true
	return false


func mark_document(id: String) -> void:
	if not id in state.documents:
		state.documents.append(id)
	set_flag("read_" + id)


# ------------------------------------------------------------------ save / checkpoints
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_checkpoint(id: String) -> void:
	state.checkpoint = id
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(state))
	_checkpoint_snapshot = state.duplicate(true)


var _checkpoint_snapshot := {}


func load_save() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY or not data.has("flags"):
		return false
	reset_state()
	for k in data:
		state[k] = data[k]
	_checkpoint_snapshot = state.duplicate(true)
	return true


func new_game() -> void:
	reset_state()
	_checkpoint_snapshot = {}
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	save_checkpoint("dock_start")
	change_scene(GAME_SCENE)


func continue_game() -> void:
	if load_save():
		change_scene(GAME_SCENE)
	else:
		new_game()


## Called when the player is caught: roll state back to the last checkpoint.
func restart_from_checkpoint() -> void:
	if _checkpoint_snapshot.is_empty():
		load_save()
	else:
		state = _checkpoint_snapshot.duplicate(true)
	change_scene(GAME_SCENE, 1.2)


func finish_game(choice: String) -> void:
	ending_choice = choice
	# A finished save would just replay the ending; clear it so Continue hides.
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	change_scene(ENDING_SCENE, 2.0)


func to_menu() -> void:
	change_scene(MENU_SCENE)


# ------------------------------------------------------------------ transitions
func fade_to(alpha: float, time: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", alpha, time)
	await tw.finished


func change_scene(path: String, fade_time := 0.6) -> void:
	if _transitioning:
		return
	_transitioning = true
	await fade_to(1.0, fade_time)
	get_tree().paused = false
	Sound.stop_all()
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	_transitioning = false
	fade_to(0.0, 0.8)


func is_transitioning() -> bool:
	return _transitioning
