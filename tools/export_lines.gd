extends SceneTree
## Dumps every spoken line in scripts/data/story.gd (and the horror whispers)
## to assets/audio/voice/lines.json for tools/gen_voice.py.
## Run: godot --headless --path . --script res://tools/export_lines.gd
func _init() -> void:
	var out := []
	for seq in Story.RADIO:
		var i := 0
		for line in Story.RADIO[seq]:
			out.append({"id": "%s_%d" % [seq, i], "speaker": line[0], "text": line[1]})
			i += 1
	for id in Story.ELIAS:
		out.append({"id": "elias_" + id, "speaker": "ELIAS", "text": Story.ELIAS[id]})
	var horror = load("res://scripts/world/horror.gd")
	var i := 0
	for l in horror.SUHA_LINES:
		out.append({"id": "suha_line_%d" % i, "speaker": "SUHA", "text": l})
		i += 1
	i = 0
	for l in horror.WHISPERS:
		out.append({"id": "lodger_%d" % i, "speaker": "WHISPER", "text": l})
		i += 1
	for id in ["morrow_tape", "mayday", "kell_tape"]:
		out.append({"id": "rec_" + id, "speaker": "REC_" + id, "text": Story.RECORDINGS[id].caption})
	out.append({"id": "dock_whisper", "speaker": "WHISPER", "text": "...don't let it hear you twice..."})
	var f := FileAccess.open("res://assets/audio/voice/lines.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "\t"))
	print("exported ", out.size(), " lines")
	quit()
