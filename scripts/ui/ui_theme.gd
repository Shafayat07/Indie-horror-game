class_name UITheme
## Shared look for menus and HUD: muted bone text on near-black, thin rules,
## typewriter headings. Avoids default editor-style controls.

const BONE := Color(0.84, 0.81, 0.73)
const DIM := Color(0.55, 0.55, 0.52)
const AMBER := Color(0.93, 0.66, 0.33)
const RED := Color(0.75, 0.16, 0.12)
const ECHO := Color(0.62, 0.8, 0.86)

static var _theme: Theme


static func heading_font() -> Font:
	return load("res://assets/fonts/SpecialElite-Regular.ttf")


static func mono_font() -> Font:
	return load("res://assets/fonts/IBMPlexMono-Regular.ttf")


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = mono_font()
	t.default_font_size = 18
	var empty := StyleBoxEmpty.new()
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.85, 0.8, 0.7, 0.07)
	hover.border_color = Color(0.85, 0.8, 0.7, 0.5)
	hover.border_width_left = 2
	hover.content_margin_left = 14
	hover.content_margin_right = 14
	hover.content_margin_top = 6
	hover.content_margin_bottom = 6
	var normal := hover.duplicate()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.border_color = Color(0, 0, 0, 0)
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", hover)
	t.set_stylebox("focus", "Button", hover)
	t.set_stylebox("disabled", "Button", normal)
	t.set_color("font_color", "Button", BONE)
	t.set_color("font_hover_color", "Button", Color(1, 0.95, 0.85))
	t.set_color("font_focus_color", "Button", Color(1, 0.95, 0.85))
	t.set_color("font_pressed_color", "Button", AMBER)
	t.set_color("font_disabled_color", "Button", Color(0.4, 0.4, 0.4))
	t.set_font("font", "Button", heading_font())
	t.set_font_size("font_size", "Button", 26)
	t.set_color("font_color", "Label", BONE)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.03, 0.035, 0.04, 0.92)
	panel.border_color = Color(0.85, 0.8, 0.7, 0.18)
	panel.set_border_width_all(1)
	panel.set_content_margin_all(24)
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)
	# sliders
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.85, 0.8, 0.7, 0.2)
	track.content_margin_top = 2
	track.content_margin_bottom = 2
	var fill := StyleBoxFlat.new()
	fill.bg_color = AMBER * Color(1, 1, 1, 0.8)
	fill.content_margin_top = 2
	fill.content_margin_bottom = 2
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	var grab := Image.create(14, 14, false, Image.FORMAT_RGBA8)
	grab.fill(BONE)
	var gt := ImageTexture.create_from_image(grab)
	t.set_icon("grabber", "HSlider", gt)
	t.set_icon("grabber_highlight", "HSlider", gt)
	t.set_color("font_color", "CheckBox", BONE)
	t.set_color("font_hover_color", "CheckBox", Color(1, 0.95, 0.85))
	t.set_stylebox("normal", "CheckBox", empty)
	t.set_stylebox("hover", "CheckBox", empty)
	t.set_stylebox("pressed", "CheckBox", empty)
	t.set_stylebox("focus", "CheckBox", empty)
	_theme = t
	return t


static func lbl(text: String, size := 18, color := BONE, heading := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if heading:
		l.add_theme_font_override("font", heading_font())
	return l
