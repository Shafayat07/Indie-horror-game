extends Control
## Ending card + credits after the final boat scene. Text differs per choice.

const TEXT := {
	"last": [
		"ENDING — THE LAST RECORDING",
		"At 03:12 the Vey transmitter played Morrow's tape, the Pelagic's mayday\nand Tomas Kell's last message into itself — and listened.\n\nThe Listener was found at dawn: a heap of wet rope and old net\nbeside the transmitter, facing it.\n\nThe island has been silent since. Not the thirteen seconds.\nJust ordinary silence.\n\nElias Vale's recorder still holds one file. It is thirteen seconds long.\nHe has never played it.",
	],
	"break": [
		"ENDING — BREAK THE SIGNAL",
		"Vey Isle went silent at 03:12.\nThe tide came back before dawn and covered the caves again.\n\nNorthern Maritime Services logged the distress carrier as ended.\nThe report was never received.\n\nFor eleven days, nothing on the island made a sound before it happened.\n\nOn the twelfth, a fishing boat passing the headland\nheard a man's footsteps on an empty dock.\nThree of them.",
	],
	"send": [
		"ENDING — SEND THE WARNING",
		"The mainland received the Vey Isle report at 03:12.\nIt warned of a storm that had not yet formed\nand a ferry that had not yet left port.\nThe ferry stayed in harbour. The storm came exactly as described.\n\nThe lighthouse on Vey Isle is still transmitting.\n\nSince that night, radio operators along the northern coast\nhave reported hearing their own voices on 2.182 MHz,\nreading messages they have not written yet.",
	],
}


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	theme = UITheme.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.012, 0.015)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	Sound.set_zone("aftermath_send" if Game.ending_choice == "send" else "aftermath_break")
	var data: Array = TEXT.get(Game.ending_choice, TEXT["break"])
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 30)
	center.add_child(v)
	var title := UITheme.lbl(data[0], 34, UITheme.BONE, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var body := UITheme.lbl(data[1], 18, UITheme.DIM)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(body)
	var cred := UITheme.lbl("THE TIDE REMEMBERS\nThank you for playing.", 16, UITheme.DIM)
	cred.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cred)
	var b := Button.new()
	b.text = "Return to main menu"
	b.pressed.connect(func():
		Sound.play_ui()
		Game.to_menu())
	v.add_child(b)
	for n in [title, body, cred, b]:
		n.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(title, "modulate:a", 1.0, 2.0)
	tw.tween_property(body, "modulate:a", 1.0, 3.0)
	tw.tween_interval(6.0)
	tw.tween_property(cred, "modulate:a", 1.0, 2.0)
	tw.tween_property(b, "modulate:a", 1.0, 1.0)
	tw.tween_callback(b.grab_focus)
	if Game.ending_choice == "send":
		# the radio keeps talking under the credits
		Sound.play_2d("radio_voice_elias", -18.0, "Voice")
