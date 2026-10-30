extends PanelContainer
## Options: mouse sensitivity, master volume, FOV, invert Y, subtitles,
## reduced screen effects, volumetric fog. Saved on close.

signal closed


func _ready() -> void:
	theme = UITheme.theme()
	custom_minimum_size = Vector2(560, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	add_child(v)
	v.add_child(UITheme.lbl("OPTIONS", 30, UITheme.BONE, true))
	_slider(v, "Mouse sensitivity", "mouse_sensitivity", 0.03, 0.6, 0.01)
	_slider(v, "Master volume", "master_volume", 0.0, 1.0, 0.01)
	_slider(v, "Field of view", "fov", 60.0, 95.0, 1.0)
	_check(v, "Invert mouse Y", "invert_y")
	_check(v, "Captions for sound effects (speech is always subtitled)", "sfx_captions")
	_check(v, "Reduced screen effects (less shake, bob and flashes)", "reduced_effects")
	_check(v, "Volumetric fog (turn off for performance)", "volumetric_fog")
	_check(v, "Fullscreen  (F11 or Alt+Enter)", "fullscreen")
	v.add_child(HSeparator.new())
	v.add_child(UITheme.lbl("CONTROLS", 22, UITheme.BONE, true))
	var c := UITheme.lbl(
		"WASD  move          Mouse  look\n" +
		"Shift  sprint (loud)    Ctrl  crouch (quiet)\n" +
		"E  interact / read     F  flashlight\n" +
		"Q  recorder: listen    R  recorder: open\n" +
		"Left mouse  record / replay (recorder open)\n" +
		"Wheel / Tab  choose recording    Esc  pause", 15, UITheme.DIM)
	v.add_child(c)
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(func():
		Sound.play_ui()
		Game.save_settings()
		closed.emit())
	v.add_child(back)
	back.call_deferred("grab_focus")


func _slider(parent: Control, text: String, key: String, lo: float, hi: float, step: float) -> void:
	var h := HBoxContainer.new()
	var l := UITheme.lbl(text, 17)
	l.custom_minimum_size = Vector2(230, 0)
	h.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = float(Game.settings.get(key, lo))
	s.custom_minimum_size = Vector2(260, 24)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.value_changed.connect(func(val):
		Game.settings[key] = val
		Game.apply_settings())
	h.add_child(s)
	parent.add_child(h)


func _check(parent: Control, text: String, key: String) -> void:
	var cb := CheckBox.new()
	cb.text = text
	cb.button_pressed = bool(Game.settings.get(key, false))
	cb.add_theme_font_size_override("font_size", 16)
	cb.toggled.connect(func(on):
		Game.settings[key] = on
		Game.apply_settings())
	parent.add_child(cb)
