class_name Recordable
extends Node3D
## A sound source the field recorder can capture. `listen_only` sources play
## on the ListenOnly bus, so they are inaudible until the player listens.

var id := ""
var radius := 6.0
var listen_only := false
var active_flag := ""        # only recordable once this flag is set
var inactive_flag := ""      # stops being recordable once this flag is set
var player: AudioStreamPlayer3D


static func make(parent: Node3D, pos: Vector3, rec_id: String, sound: String, opts := {}) -> Recordable:
	var r := Recordable.new()
	r.id = rec_id
	r.radius = opts.get("radius", 6.0)
	r.listen_only = opts.get("listen_only", false)
	r.active_flag = opts.get("active_flag", "")
	r.inactive_flag = opts.get("inactive_flag", "")
	parent.add_child(r)
	r.position = pos
	r.add_to_group("recordable")
	if sound != "":
		r.player = Sound.attach_loop(r, sound, opts.get("volume", 0.0), {
			"bus": "ListenOnly" if r.listen_only else "SFX",
			"unit_size": opts.get("unit_size", 3.0), "max_distance": opts.get("max_distance", 25.0),
			"autoplay": false})
		if opts.has("interval"):
			# one-shot sound repeated on an interval rather than a seamless loop
			var t := Timer.new()
			t.wait_time = opts.interval
			t.autostart = true
			r.add_child(t)
			t.timeout.connect(func(): if r.is_active(): r.player.play())
		else:
			r.player.ready.connect(func(): r._update_play())
	return r


func _ready() -> void:
	Game.flag_set.connect(func(_f): _update_play())


func is_active() -> bool:
	if active_flag != "" and not Game.has_flag(active_flag):
		return false
	if inactive_flag != "" and Game.has_flag(inactive_flag):
		return false
	return true


func _update_play() -> void:
	if player == null or not player.is_inside_tree():
		return
	var stream := player.stream as AudioStreamWAV
	if stream and stream.loop_mode != AudioStreamWAV.LOOP_DISABLED:
		if is_active() and not player.playing:
			player.play()
		elif not is_active() and player.playing:
			player.stop()
