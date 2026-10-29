extends CanvasLayer
## Pause menu: resume, objective reminder, options, restart from checkpoint,
## main menu. Releases the mouse while open.

var level: Node
var _root: Control
var _menu: VBoxContainer
var _options: Control
var _objective: Label
var is_open := false


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = ColorRect.new()
	(_root as ColorRect).color = Color(0.01, 0.012, 0.015, 0.82)
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UITheme.theme()
	add_child(_root)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 8)
	center.add_child(_menu)
	_menu.add_child(UITheme.lbl("PAUSED", 40, UITheme.BONE, true))
	_objective = UITheme.lbl("", 16, UITheme.DIM)
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective.custom_minimum_size = Vector2(480, 0)
	_menu.add_child(_objective)
	_menu.add_child(Control.new())
	_button("Resume", toggle)
	_button("Options", _show_options)
	_button("Restart from checkpoint", func():
		toggle()
		Game.restart_from_checkpoint())
	_button("Quit to main menu", func():
		get_tree().paused = false
		Game.to_menu())
	_root.visible = false


func _button(text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(func():
		Sound.play_ui()
		cb.call())
	_menu.add_child(b)


func toggle() -> void:
	if _options:
		_close_options()
		return
	is_open = not is_open
	_root.visible = is_open
	get_tree().paused = is_open
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if is_open else Input.MOUSE_MODE_CAPTURED
	if is_open:
		_objective.text = "Objective:  " + Game.objective_text()
		(_menu.get_child(3) as Button).grab_focus()
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), is_open)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("PreEcho"), is_open)


func _show_options() -> void:
	_menu.visible = false
	_options = preload("res://scripts/ui/options_panel.gd").new()
	(_root.get_child(0) as CenterContainer).add_child(_options)
	_options.closed.connect(_close_options)


func _close_options() -> void:
	if _options:
		_options.queue_free()
		_options = null
	_menu.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if is_open and event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()
