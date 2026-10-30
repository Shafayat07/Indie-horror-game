extends CanvasLayer
## In-game HUD. Kept sparse: a faint dot, contextual prompt, objective that
## fades after it changes, subtitles/radio text, the recorder readout, a note
## reader and full-screen effects (listen filter, dread vignette, death).

var player: Node
var reading := false
var _prompt: Label
var _dot: ColorRect
var _objective: Label
var _obj_tween: Tween
var _sub_box: VBoxContainer
var _toast: Label
var _toast_tween: Tween
var _rec_panel: PanelContainer
var _rec_list: VBoxContainer
var _rec_status: Label
var _rec_bar: ProgressBar
var _listen_fx: ColorRect
var _dread_fx: ColorRect
var _flash: ColorRect
var _death_label: Label
var _note: Control
var _note_title: Label
var _note_body: Label
var _hint: Label
var _queue: Array = []
var _sub_running := false
var dread := 0.0


func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UITheme.theme()
	add_child(root)

	_listen_fx = _fx_rect(root, """
shader_type canvas_item;
uniform float strength = 0.0;
uniform float t = 0.0;
void fragment(){
	vec2 uv = UV - 0.5;
	float v = smoothstep(0.25, 0.75, length(uv * vec2(1.6, 1.0)));
	float scan = sin(UV.y * 900.0 + TIME * 4.0) * 0.5 + 0.5;
	COLOR = vec4(0.05, 0.12, 0.13, (v * 0.75 + scan * 0.04) * strength);
}""")
	_dread_fx = _fx_rect(root, """
shader_type canvas_item;
uniform float strength = 0.0;
void fragment(){
	vec2 uv = UV - 0.5;
	float v = smoothstep(0.2, 0.8, length(uv * vec2(1.4, 1.0)));
	float pulse = 0.85 + 0.15 * sin(TIME * 7.0);
	COLOR = vec4(0.0, 0.0, 0.0, v * strength * pulse);
}""")

	_dot = ColorRect.new()
	_dot.size = Vector2(3, 3)
	_dot.color = Color(0.9, 0.88, 0.8, 0.35)
	_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE   # the captured cursor sits here; never eat mouse-look
	_dot.set_anchors_preset(Control.PRESET_CENTER)
	_dot.position = Vector2(-1.5, -1.5)
	root.add_child(_dot)

	_prompt = UITheme.lbl("", 20)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.set_anchors_preset(Control.PRESET_CENTER)
	_prompt.position = Vector2(-300, 40)
	_prompt.size = Vector2(600, 30)
	root.add_child(_prompt)

	_objective = UITheme.lbl("", 19, UITheme.BONE, true)
	_objective.position = Vector2(36, 28)
	_objective.size = Vector2(620, 60)
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective.modulate.a = 0.0
	root.add_child(_objective)

	_hint = UITheme.lbl("", 15, UITheme.DIM)
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hint.position = Vector2(36, -60)
	root.add_child(_hint)

	_sub_box = VBoxContainer.new()
	_sub_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_sub_box.position = Vector2(-460, -190)
	_sub_box.size = Vector2(920, 140)
	_sub_box.alignment = BoxContainer.ALIGNMENT_END
	_sub_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_sub_box)

	_toast = UITheme.lbl("", 19, UITheme.AMBER)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.set_anchors_preset(Control.PRESET_CENTER)
	_toast.position = Vector2(-400, 90)
	_toast.size = Vector2(800, 30)
	_toast.modulate.a = 0
	root.add_child(_toast)

	_build_recorder(root)
	_build_note(root)

	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(0, 0, 0, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_flash)
	_death_label = UITheme.lbl("", 34, UITheme.BONE, true)
	_death_label.set_anchors_preset(Control.PRESET_CENTER)
	_death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_death_label.position = Vector2(-500, -20)
	_death_label.size = Vector2(1000, 50)
	_death_label.modulate.a = 0
	root.add_child(_death_label)

	_build_extras(root)
	Game.objective_changed.connect(func(_id): show_objective())
	Game.journal_added.connect(func(_id): toast("Journal updated  [J]", 2.5))
	Sound.caption.connect(_on_caption)
	show_objective()


func _fx_rect(root: Control, code: String) -> ColorRect:
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	r.material = m
	root.add_child(r)
	return r


func _build_recorder(root: Control) -> void:
	_rec_panel = PanelContainer.new()
	_rec_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_rec_panel.position = Vector2(-370, -300)
	_rec_panel.custom_minimum_size = Vector2(340, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.07, 0.06, 0.88)
	sb.border_color = Color(0.4, 0.6, 0.5, 0.4)
	sb.set_border_width_all(1)
	sb.set_content_margin_all(14)
	_rec_panel.add_theme_stylebox_override("panel", sb)
	root.add_child(_rec_panel)
	var v := VBoxContainer.new()
	_rec_panel.add_child(v)
	var title := UITheme.lbl("FIELD RECORDER  ·  MK II", 14, Color(0.55, 0.75, 0.62))
	v.add_child(title)
	_rec_status = UITheme.lbl("", 14, Color(0.55, 0.75, 0.62))
	v.add_child(_rec_status)
	_rec_bar = ProgressBar.new()
	_rec_bar.custom_minimum_size = Vector2(0, 6)
	_rec_bar.show_percentage = false
	_rec_bar.max_value = 1.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.85, 0.2, 0.15)
	_rec_bar.add_theme_stylebox_override("fill", fill)
	v.add_child(_rec_bar)
	_rec_list = VBoxContainer.new()
	v.add_child(_rec_list)
	var help := UITheme.lbl("Wheel / Tab: select    LMB: use    R: close", 12, UITheme.DIM)
	v.add_child(help)
	_rec_panel.visible = false


func _build_note(root: Control) -> void:
	_note = ColorRect.new()
	(_note as ColorRect).color = Color(0, 0, 0, 0.75)
	_note.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(_note)
	var paper := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.78, 0.75, 0.66)
	sb.set_content_margin_all(40)
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 20
	paper.add_theme_stylebox_override("panel", sb)
	paper.set_anchors_preset(Control.PRESET_CENTER)
	paper.custom_minimum_size = Vector2(640, 0)
	paper.position = Vector2(-320, -260)
	_note.add_child(paper)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	paper.add_child(v)
	_note_title = UITheme.lbl("", 22, Color(0.15, 0.12, 0.1), true)
	_note_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note_title.custom_minimum_size = Vector2(560, 0)
	v.add_child(_note_title)
	_note_body = UITheme.lbl("", 18, Color(0.18, 0.15, 0.12), true)
	_note_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note_body.custom_minimum_size = Vector2(560, 0)
	v.add_child(_note_body)
	var close := UITheme.lbl("[E] close", 14, Color(0.35, 0.3, 0.25))
	close.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(close)
	_note.visible = false


# ------------------------------------------------------------------ API
func set_prompt(text: String) -> void:
	_prompt.text = text
	_dot.color.a = 0.8 if text != "" else 0.35


func show_objective() -> void:
	var text := Game.objective_text()
	if text == "":
		return
	_objective.text = text
	if _obj_tween:
		_obj_tween.kill()
	_obj_tween = create_tween()
	_obj_tween.tween_property(_objective, "modulate:a", 1.0, 0.8)
	_obj_tween.tween_interval(7.0)
	_obj_tween.tween_property(_objective, "modulate:a", 0.0, 2.0)


func peek_objective() -> void:
	show_objective()


func toast(text: String, time := 2.6) -> void:
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.15)
	_toast_tween.tween_interval(time)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.8)


func hint(text: String) -> void:
	_hint.text = text


func set_listen(on: bool) -> void:
	var m := _listen_fx.material as ShaderMaterial
	var tw := create_tween()
	tw.tween_method(func(v): m.set_shader_parameter("strength", v), 1.0 - float(on), float(on), 0.5)
	update_recorder(player.recorder.panel_open, player.recorder.selected, player.recorder.recording_progress, player.recorder.cooldown, on)


func update_recorder(open: bool, selected: int, progress: float, cooldown: float, listening: bool) -> void:
	_rec_panel.visible = open
	if not open:
		return
	var status := "● LISTENING" if listening else "○ listen off  [Q]"
	if progress >= 0.0:
		status = "● REC  — hold still"
	elif cooldown > 0.0:
		status = "rewinding… %.0f" % ceil(cooldown)
	_rec_status.text = status
	_rec_bar.value = max(progress, 0.0)
	_rec_bar.visible = progress >= 0.0
	for c in _rec_list.get_children():
		c.queue_free()
	var rows := ["◉  RECORD NEW"]
	for r in Game.state.recordings:
		rows.append("▶  " + Story.RECORDINGS[r.id].name)
	for i in rows.size():
		var l := UITheme.lbl(("› " if i == selected else "   ") + rows[i], 15,
			Color(0.9, 0.95, 0.85) if i == selected else Color(0.5, 0.62, 0.55))
		_rec_list.add_child(l)
	if rows.size() == 1:
		_rec_list.add_child(UITheme.lbl("   (no recordings)", 13, UITheme.DIM))


func set_dread(v: float) -> void:
	dread = v
	(_dread_fx.material as ShaderMaterial).set_shader_parameter("strength", clamp(v, 0.0, 1.0) * (0.5 if Game.settings.reduced_effects else 0.85))


func open_note(doc_id: String) -> void:
	var d: Array = Story.DOCS[doc_id]
	_note_title.text = d[0]
	_note_body.text = d[1]
	_note.visible = true
	reading = true
	Game.mark_document(doc_id)
	Sound.play_2d("paper", -6.0, "UI")
	player.freeze(true)


func close_note() -> void:
	if not reading:
		return
	_note.visible = false
	reading = false
	Sound.play_2d("paper", -10.0, "UI")
	player.freeze(false)


func _unhandled_input(event: InputEvent) -> void:
	if reading and (event.is_action_pressed("interact") or event.is_action_pressed("pause") or event.is_action_pressed("rec_use")):
		get_viewport().set_input_as_handled()
		close_note()
	elif _journal.visible and (event.is_action_pressed("journal") or event.is_action_pressed("pause") or event.is_action_pressed("interact")):
		get_viewport().set_input_as_handled()
		_journal.visible = false
		player.freeze(false)
	elif event.is_action_pressed("journal") and not reading and player.input_enabled:
		get_viewport().set_input_as_handled()
		open_journal()
	elif event.is_action_pressed("watch") and player.input_enabled:
		show_watch()


func _on_caption(text: String, kind: String, duration: float) -> void:
	# sound-effect and pre-echo captions are optional (off by default); speech and hints always show
	if not Game.settings.get("sfx_captions", false) and kind in ["sfx", "preecho"]:
		return
	_queue.append([text, kind, duration])
	if not _sub_running:
		_run_subs()


## Radio/tape sequences: lines with speaker names, typed out over static.
func radio(seq_id: String, _sound := "") -> void:
	var i := 0
	for line in Story.RADIO[seq_id]:
		var speaker: String = line[0]
		var txt: String = line[1]
		var kind := "radio" if speaker != "" else "aside"
		if speaker.contains("SUHA") or speaker.contains("HER VOICE"):
			kind = "suha"
		_queue.append([(speaker + ":  " if speaker != "" else "") + txt, kind, line[2], "%s_%d" % [seq_id, i]])
		i += 1
	if not _sub_running:
		_run_subs()


func is_busy() -> bool:
	return _sub_running


func _run_subs() -> void:
	_sub_running = true
	while _queue.size() > 0:
		var item: Array = _queue.pop_front()
		var color := UITheme.BONE
		match item[1]:
			"preecho": color = UITheme.ECHO
			"radio": color = Color(0.72, 0.86, 0.72)
			"aside": color = UITheme.DIM
			"elias": color = Color(0.95, 0.86, 0.62)
			"suha": color = Color(1.0, 0.72, 0.78)
			"hint": color = UITheme.AMBER
		var l := UITheme.lbl("", 20, color, item[1] == "radio")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(920, 0)
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0, 0, 0, 0.45)
		bg.set_content_margin_all(6)
		l.add_theme_stylebox_override("normal", bg)
		_sub_box.add_child(l)
		var text: String = item[0]
		if item[1] == "radio":
			l.text = text
			l.visible_ratio = 0.0
			var tw := create_tween()
			tw.tween_property(l, "visible_ratio", 1.0, min(text.length() * 0.03, 2.0))
		else:
			l.text = text
		var hold: float = item[2]
		if item.size() > 3:
			var spoken := Sound.voice(item[3])
			if spoken > 0.0:
				hold = spoken + 0.5
		_fade_out_later(l, hold + 0.5)
		# spoken/radio lines are sequential; captions can overlap slightly
		await get_tree().create_timer(hold if item[1] in ["radio", "aside", "suha"] else 0.4).timeout
		if not is_inside_tree():
			return
	_sub_running = false


func _fade_out_later(l: Label, t: float) -> void:
	await get_tree().create_timer(t).timeout
	if not is_instance_valid(l):
		return
	var tw := create_tween()
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)


func hide_overlays() -> void:
	_rec_panel.visible = false
	_prompt.text = ""
	if reading:
		close_note()


func death_flash() -> void:
	var tw := create_tween()
	_flash.color = Color(0.25, 0.02, 0.0, 0.0)
	tw.tween_property(_flash, "color:a", 0.85, 0.08)
	tw.tween_property(_flash, "color", Color(0, 0, 0, 1), 1.6)


func show_death_text() -> void:
	_death_label.text = "The island heard you before you moved."
	var tw := create_tween()
	tw.tween_property(_death_label, "modulate:a", 1.0, 0.8)


func fade_black(on: bool, time := 0.8) -> void:
	var tw := create_tween()
	tw.tween_property(_flash, "color", Color(0, 0, 0, 1.0 if on else 0.0), time)
	await tw.finished


func white_flash() -> void:
	_flash.color = Color(1, 1, 1, 0.0)
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 1.0, 0.1)
	tw.tween_property(_flash, "color:a", 0.0, 2.5)



# ------------------------------------------------------------------ story presentation
var _journal: Control
var _journal_text: RichTextLabel
var _chapter: Label
var _chapter_sub: Label
var _watch: Label


func _build_extras(root: Control) -> void:
	_chapter = UITheme.lbl("", 40, UITheme.BONE, true)
	_chapter.set_anchors_preset(Control.PRESET_CENTER)
	_chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chapter.position = Vector2(-600, -110)
	_chapter.size = Vector2(1200, 60)
	_chapter.modulate.a = 0
	root.add_child(_chapter)
	_chapter_sub = UITheme.lbl("", 18, UITheme.DIM)
	_chapter_sub.set_anchors_preset(Control.PRESET_CENTER)
	_chapter_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chapter_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_chapter_sub.position = Vector2(-450, -40)
	_chapter_sub.size = Vector2(900, 60)
	_chapter_sub.modulate.a = 0
	root.add_child(_chapter_sub)
	_watch = UITheme.lbl("", 26, UITheme.AMBER, true)
	_watch.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_watch.position = Vector2(-220, 28)
	_watch.size = Vector2(190, 40)
	_watch.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_watch.modulate.a = 0
	root.add_child(_watch)
	_journal = ColorRect.new()
	(_journal as ColorRect).color = Color(0, 0, 0, 0.82)
	_journal.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(_journal)
	var paper := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.76, 0.73, 0.64)
	sb.set_content_margin_all(36)
	paper.add_theme_stylebox_override("panel", sb)
	paper.set_anchors_preset(Control.PRESET_CENTER)
	paper.custom_minimum_size = Vector2(760, 560)
	paper.position = Vector2(-380, -290)
	_journal.add_child(paper)
	_journal_text = RichTextLabel.new()
	_journal_text.bbcode_enabled = true
	_journal_text.scroll_following = false
	_journal_text.add_theme_font_override("normal_font", UITheme.heading_font())
	_journal_text.add_theme_font_override("bold_font", UITheme.heading_font())
	_journal_text.add_theme_font_size_override("normal_font_size", 17)
	_journal_text.add_theme_font_size_override("bold_font_size", 20)
	_journal_text.add_theme_color_override("default_color", Color(0.17, 0.14, 0.11))
	paper.add_child(_journal_text)
	_journal.visible = false


func open_journal() -> void:
	var t := "[b]ELIAS VALE — NOTEBOOK[/b]          %s\n\n[b]Now:[/b] %s\n\n" % [Game.clock_text(), Game.objective_text()]
	for e in Story.JOURNAL:
		if e[0] in Game.state.get("journal", []):
			t += "[b]%s[/b]\n%s\n\n" % [e[1], e[2]]
	t += "[color=#5a4f45](J / E to close)[/color]"
	_journal_text.text = t
	_journal.visible = true
	Sound.play_2d("paper", -6.0, "UI")
	player.freeze(true)


func show_watch() -> void:
	_watch.text = "◷ " + Game.clock_text()
	var tw := create_tween()
	tw.tween_property(_watch, "modulate:a", 1.0, 0.2)
	tw.tween_interval(3.0)
	tw.tween_property(_watch, "modulate:a", 0.0, 0.8)


func chapter(numeral: String, title: String, premise: String) -> void:
	_chapter.text = "%s  ·  %s" % [numeral, title]
	_chapter_sub.text = premise
	var tw := create_tween()
	tw.tween_property(_chapter, "modulate:a", 1.0, 1.2)
	tw.parallel().tween_property(_chapter_sub, "modulate:a", 1.0, 1.6)
	tw.tween_interval(4.0)
	tw.tween_property(_chapter, "modulate:a", 0.0, 1.5)
	tw.parallel().tween_property(_chapter_sub, "modulate:a", 0.0, 1.5)


func elias(id: String, delay := 0.0) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if Story.ELIAS.has(id):
		# Elias's thoughts are subtitles only; hold long enough to read
		var text: String = Story.ELIAS[id]
		_on_caption("ELIAS:  " + text, "elias", clampf(text.length() * 0.065, 3.5, 9.0))


## Opening briefing: black cards that tell you who you are and why you're here.
func intro() -> void:
	player.freeze(true)
	_flash.color = Color(0, 0, 0, 1)
	var cards := [
		"Vey Isle. North Atlantic.\nRemoved from the charts in 1972.",
		"For six years a dead weather station on the island\nhas been transmitting a distress call.\nIt has no power.",
		"You are Elias Vale, maintenance technician.\nRestore the station. Send its final report. Leave before dawn.",
		"Arrival: 23:40.",
	]
	for c in cards:
		_death_label.text = c
		_death_label.position = Vector2(-500, -60)
		var tw := create_tween()
		tw.tween_property(_death_label, "modulate:a", 1.0, 0.8)
		tw.tween_interval(3.2)
		tw.tween_property(_death_label, "modulate:a", 0.0, 0.6)
		await tw.finished
	_death_label.position = Vector2(-500, -20)
	await fade_black(false, 1.5)
	player.freeze(false)
