extends Node3D
## Main menu over a live shot of the lighthouse across black water.

const CREDITS := """THE TIDE REMEMBERS

Design, code, models, textures and sound
Generated procedurally for this project
(Godot 4 · GDScript · Python/numpy)

Engine
Godot Engine 4.3 — MIT License, godotengine.org

Fonts
Special Elite by Astigmatic — Apache License 2.0
IBM Plex Mono by IBM — SIL Open Font License 1.1

All textures and sounds are original and procedurally
synthesised (tools/gen_textures.py, tools/gen_audio.py).
See docs/ASSET_MANIFEST.md for the full list.

Thank you for listening."""

var _menu: VBoxContainer
var _panel_holder: CenterContainer
var _sub: Control
var _beam: Node3D
var _continue: Button


func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_scene()
	_build_ui()
	Sound.set_zone("menu")
	if "--autostart" in OS.get_cmdline_user_args():
		Game.new_game.call_deferred()   # used to smoke-test exported builds


func _build_scene() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.04, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.12, 0.14, 0.17)
	env.fog_enabled = true
	env.fog_light_color = Color(0.06, 0.075, 0.09)
	env.fog_density = 0.012
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 2.2, 0)
	cam.rotation_degrees = Vector3(2, 0, 0)
	cam.fov = 55
	add_child(cam)
	var ocean := Ocean.new()
	add_child(ocean)
	ocean.build()
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.5, 0.6, 0.8)
	moon.light_energy = 0.3
	moon.rotation_degrees = Vector3(-30, 160, 0)
	add_child(moon)
	# distant headland and lighthouse
	var lh := Node3D.new()
	add_child(lh)
	lh.position = Vector3(18, 0, -140)
	B.rock(lh, Vector3(0, -2, 0), Vector3(40, 14, 22), 1, B.mat("cliff", Color.WHITE, 0.1), false)
	B.rock(lh, Vector3(-30, -3, 8), Vector3(25, 8, 15), 3, B.mat("cliff", Color.WHITE, 0.1), false)
	B.cyl(lh, Vector3(0, 18, 0), 2.2, 16, B.mat("plaster_white", Color(0.8, 0.8, 0.78)), {"collide": false, "top": 1.7})
	B.box(lh, Vector3(0, 26.5, 0), Vector3(3.2, 1.2, 3.2), B.flat(Color(0.05, 0.05, 0.05)), {"collide": false})
	B.sphere(lh, Vector3(0, 27.8, 0), 1.0, B.glow(Color(1, 0.8, 0.5), 6.0, true))
	_beam = Node3D.new()
	lh.add_child(_beam)
	_beam.position = Vector3(0, 27.8, 0)
	var beam := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.6
	cm.bottom_radius = 7.0
	cm.height = 90
	beam.mesh = cm
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	bm.albedo_color = Color(1, 0.85, 0.6, 0.05)
	bm.cull_mode = BaseMaterial3D.CULL_DISABLED
	beam.material_override = bm
	_beam.add_child(beam)
	beam.rotation_degrees = Vector3(90, 0, 0)
	beam.position = Vector3(0, 0, 45)


func _process(delta: float) -> void:
	if _beam:
		_beam.rotation.y += delta * 0.5


func _build_ui() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UITheme.theme()
	cl.add_child(root)
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = "shader_type canvas_item; void fragment(){ COLOR = vec4(0.0,0.0,0.0, smoothstep(0.65, 0.05, UV.x) * 0.85); }"
	var m := ShaderMaterial.new()
	m.shader = sh
	shade.material = m
	root.add_child(shade)
	_menu = VBoxContainer.new()
	_menu.position = Vector2(90, 150)
	_menu.add_theme_constant_override("separation", 6)
	root.add_child(_menu)
	var title := UITheme.lbl("THE TIDE\nREMEMBERS", 64, UITheme.BONE, true)
	_menu.add_child(title)
	_menu.add_child(UITheme.lbl("The sea never forgets the people it takes.", 17, UITheme.DIM))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	_menu.add_child(spacer)
	_continue = _button("Continue", func(): Game.continue_game())
	_continue.visible = Game.has_save()
	_button("New Game", func(): Game.new_game())
	_button("Options", func(): _show(preload("res://scripts/ui/options_panel.gd").new()))
	_button("Credits", _show_credits)
	_button("Quit", func(): get_tree().quit())
	_panel_holder = CenterContainer.new()
	_panel_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_panel_holder)
	var hint := UITheme.lbl("Headphones recommended. Sound is how you survive.", 14, UITheme.DIM)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint.position = Vector2(90, -50)
	root.add_child(hint)
	(_continue if _continue.visible else _menu.get_child(4)).call_deferred("grab_focus")


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(func():
		if Game.is_transitioning():
			return
		Sound.play_ui()
		cb.call())
	b.mouse_entered.connect(func(): b.grab_focus())
	_menu.add_child(b)
	return b


func _show(panel: Control) -> void:
	_menu.visible = false
	_sub = panel
	_panel_holder.add_child(panel)
	if panel.has_signal("closed"):
		panel.closed.connect(_close_sub)


func _close_sub() -> void:
	if _sub:
		_sub.queue_free()
		_sub = null
	_menu.visible = true


func _show_credits() -> void:
	var p := PanelContainer.new()
	p.add_user_signal("closed")
	var v := VBoxContainer.new()
	p.add_child(v)
	var l := UITheme.lbl(CREDITS, 16)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(func():
		Sound.play_ui()
		_close_sub())
	v.add_child(back)
	_show(p)
	back.call_deferred("grab_focus")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and _sub:
		_close_sub()
