extends Node
## Audio hub: bus layout, a cached sound library, positional one-shots,
## the zone-based ambience mixer, the recorder's Listen filter, and the
## PRE-ECHO system. Every gameplay sound that The Listener can react to is
## routed through emit_noise() so hearing is consistent across the game.

signal caption(text: String, kind: String, duration: float)
signal noise_emitted(pos: Vector3, radius: float, kind: String)

const AUDIO_DIR := "res://assets/audio/"
const LOOPS := ["amb_sea", "amb_wind", "amb_interior", "amb_cave", "amb_drone", "amb_signal",
	"amb_generator", "amb_static", "amb_tape", "listener_strings", "calibration_tape"]

## Ambience presets: layer -> volume dB. Layers not listed fade out.
const ZONES := {
	"boat": {"amb_sea": -4.0, "amb_wind": -10.0, "amb_signal": -34.0},
	"dock": {"amb_sea": -6.0, "amb_wind": -9.0, "amb_drone": -30.0, "amb_signal": -32.0},
	"settlement": {"amb_sea": -16.0, "amb_wind": -8.0, "amb_drone": -24.0, "amb_signal": -30.0},
	"interior": {"amb_sea": -26.0, "amb_wind": -20.0, "amb_interior": -8.0, "amb_drone": -26.0},
	"station": {"amb_sea": -22.0, "amb_wind": -10.0, "amb_drone": -22.0, "amb_signal": -26.0},
	"station_in": {"amb_sea": -30.0, "amb_wind": -22.0, "amb_interior": -10.0, "amb_drone": -20.0},
	"cliffs": {"amb_sea": -5.0, "amb_wind": -6.0, "amb_drone": -26.0, "amb_signal": -24.0},
	"caves": {"amb_cave": -4.0, "amb_drone": -16.0, "amb_sea": -28.0},
	"lighthouse": {"amb_wind": -12.0, "amb_interior": -12.0, "amb_drone": -18.0, "amb_signal": -16.0},
	"chamber": {"amb_drone": -10.0, "amb_signal": -8.0, "amb_cave": -18.0},
	"silence": {},
	"aftermath_break": {"amb_sea": -10.0, "amb_wind": -14.0},
	"aftermath_send": {"amb_sea": -12.0, "amb_wind": -10.0, "amb_signal": -6.0, "amb_static": -24.0, "amb_drone": -14.0},
	"menu": {"amb_sea": -12.0, "amb_wind": -14.0, "amb_drone": -28.0},
}

var _cache := {}
var _layers := {}
var _zone := ""
var _zone_override := ""
var listening := false
var _ambience_lowpass: AudioEffectLowPassFilter


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	for name in ["amb_sea", "amb_wind", "amb_interior", "amb_cave", "amb_drone", "amb_signal", "amb_static"]:
		var p := AudioStreamPlayer.new()
		p.stream = get_stream(name)
		p.bus = "Ambience"
		p.volume_db = -80.0
		add_child(p)
		_layers[name] = p


func _setup_buses() -> void:
	for b in ["Ambience", "SFX", "PreEcho", "Voice", "ListenOnly", "UI"]:
		if AudioServer.get_bus_index(b) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, b)
			AudioServer.set_bus_send(i, "Master")
	_ambience_lowpass = AudioEffectLowPassFilter.new()
	_ambience_lowpass.cutoff_hz = 20000
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Ambience"), _ambience_lowpass)
	# Pre-echoes get a long, slightly dark tail: their recognisable signature.
	var rv := AudioEffectReverb.new()
	rv.room_size = 0.85
	rv.damping = 0.6
	rv.wet = 0.45
	rv.dry = 0.8
	rv.predelay_msec = 60
	AudioServer.add_bus_effect(AudioServer.get_bus_index("PreEcho"), rv)
	var cave_rv := AudioEffectReverb.new()
	cave_rv.room_size = 0.6
	cave_rv.wet = 0.0
	cave_rv.dry = 1.0
	AudioServer.add_bus_effect(AudioServer.get_bus_index("SFX"), cave_rv)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("ListenOnly"), -60.0)


func set_reverb_space(wet: float) -> void:
	var fx := AudioServer.get_bus_effect(AudioServer.get_bus_index("SFX"), 0) as AudioEffectReverb
	fx.wet = wet
	fx.dry = 1.0 - wet * 0.3


# ------------------------------------------------------------------ library
func get_stream(name: String) -> AudioStream:
	if _cache.has(name):
		return _cache[name]
	var path := AUDIO_DIR + name + ".wav"
	if not ResourceLoader.exists(path):
		push_warning("Missing sound: " + name)
		return null
	var s: AudioStream = load(path)
	if s is AudioStreamWAV and name in LOOPS:
		s = s.duplicate()
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = int(round(s.get_length() * s.mix_rate))
	_cache[name] = s
	return s


func _scene_root() -> Node:
	var r := get_tree().current_scene
	return r if r else self


func play_2d(name: String, volume_db := 0.0, bus := "SFX", pitch := 1.0) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = get_stream(name)
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.bus = bus
	_scene_root().add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
	return p


func play_ui(name := "ui_click") -> void:
	var p := AudioStreamPlayer.new()
	p.stream = get_stream(name)
	p.bus = "UI"
	p.volume_db = -8
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


func play_at(name: String, pos: Vector3, volume_db := 0.0, opts := {}) -> AudioStreamPlayer3D:
	var stream := get_stream(name)
	if stream == null:
		return null
	var p := AudioStreamPlayer3D.new()
	p.stream = stream
	p.volume_db = volume_db
	p.unit_size = opts.get("unit_size", 6.0)
	p.max_distance = opts.get("max_distance", 80.0)
	p.pitch_scale = opts.get("pitch", 1.0)
	p.bus = opts.get("bus", "SFX")
	p.attenuation_filter_cutoff_hz = opts.get("filter", 6000.0)
	p.attenuation_filter_db = -18.0
	_scene_root().add_child(p)
	p.global_position = pos
	p.play()
	p.finished.connect(p.queue_free)
	return p


## A looping positional source attached to `parent` (e.g. a radio, generator).
func attach_loop(parent: Node3D, name: String, volume_db := 0.0, opts := {}) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.stream = get_stream(name)
	p.volume_db = volume_db
	p.unit_size = opts.get("unit_size", 4.0)
	p.max_distance = opts.get("max_distance", 40.0)
	p.bus = opts.get("bus", "SFX")
	p.autoplay = opts.get("autoplay", true)
	parent.add_child(p)
	p.position = opts.get("offset", Vector3.ZERO)
	return p


# ------------------------------------------------------------------ noise & pre-echo
## Any sound The Listener could hear. radius = metres at which it is audible to it.
func emit_noise(pos: Vector3, radius: float, kind := "noise") -> void:
	noise_emitted.emit(pos, radius, kind)
	get_tree().call_group("listener_ai", "hear", pos, radius, kind)


## Play a sound that arrives BEFORE its cause. Every pre-echo has the same
## signature: a faint reversed swell, then the sound on the PreEcho bus with a
## long tail, plus a tinted caption. The Listener hears pre-echoes too.
func pre_echo(name: String, pos: Vector3, caption_text := "", volume_db := 0.0, noise_radius := 0.0, opts := {}) -> void:
	var swell := play_at("whisper_0", pos, volume_db - 22.0, {"bus": "PreEcho", "pitch": 0.6, "unit_size": 8.0})
	if swell:
		get_tree().create_timer(1.2).timeout.connect(func(): if is_instance_valid(swell): swell.stop(); swell.queue_free())
	await get_tree().create_timer(0.35).timeout
	var o := opts.duplicate()
	o["bus"] = "PreEcho"
	o["unit_size"] = opts.get("unit_size", 9.0)
	play_at(name, pos, volume_db, o)
	if caption_text != "":
		say(caption_text, "preecho", opts.get("caption_time", 4.0))
	if noise_radius > 0.0:
		get_tree().call_group("listener_ai", "hear", pos, noise_radius, "pre_echo")


func say(text: String, kind := "sfx", duration := 3.5) -> void:
	caption.emit(text, kind, duration)


# ------------------------------------------------------------------ ambience
func set_zone(zone: String) -> void:
	_zone = zone
	_apply_zone()


## Endings and set-pieces can pin an ambience regardless of the zone the player walks into.
func override_zone(zone: String) -> void:
	_zone_override = zone
	_apply_zone()


func _apply_zone() -> void:
	var z := _zone_override if _zone_override != "" else _zone
	var preset: Dictionary = ZONES.get(z, {})
	for name in _layers:
		var p: AudioStreamPlayer = _layers[name]
		var target: float = preset.get(name, -80.0)
		if not p.playing and target > -79.0:
			p.play(randf() * 4.0)
		var tw := create_tween()
		tw.tween_property(p, "volume_db", target, 2.5)


func set_listen(on: bool) -> void:
	listening = on
	var tw := create_tween().set_parallel()
	tw.tween_property(_ambience_lowpass, "cutoff_hz", 700.0 if on else 20000.0, 0.6)
	tw.tween_method(func(v): AudioServer.set_bus_volume_db(AudioServer.get_bus_index("ListenOnly"), v),
		AudioServer.get_bus_volume_db(AudioServer.get_bus_index("ListenOnly")), 2.0 if on else -60.0, 0.6)
	tw.tween_method(func(v): AudioServer.set_bus_volume_db(AudioServer.get_bus_index("PreEcho"), v),
		AudioServer.get_bus_volume_db(AudioServer.get_bus_index("PreEcho")), 5.0 if on else 0.0, 0.6)
	tw.tween_method(func(v): AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambience"), v),
		AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Ambience")), -7.0 if on else 0.0, 0.6)


func stop_all() -> void:
	_zone_override = ""
	if listening:
		set_listen(false)
	for name in _layers:
		var tw := create_tween()
		tw.tween_property(_layers[name], "volume_db", -80.0, 0.5)
	set_reverb_space(0.0)
