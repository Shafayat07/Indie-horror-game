extends Node3D
## Authored horror events shared by every area:
##  - THE LODGER: stand still too long and something comes up behind you and
##    whispers your own future words into your ear. Turn round in time and you see it.
##  - Apparitions that only stand where you aren't looking.
##  - Faces in windows, Listener glimpses in doorways, sudden jumpscares.
##  - The thirteen-second silence: the whole island stops making sound.

const LODGER_DELAY := 25.0
const LODGER_COOLDOWN := 150.0
const WHISPERS := [
	"\"...you already opened it, Elias. You just don't remember yet...\"",
	"\"...don't look at the light. It looks back...\"",
	"\"...you said this already. Tonight. Again...\"",
	"\"...it isn't behind you. I am...\"",
	"\"...three more steps...\"",
	"\"...they cut my ears so I could hear you coming...\"",
	"\"...03:12...\"",
]

var level: Node
var _still := 0.0
var _cooldown := 60.0
var _behind_t := 120.0
var scaring := false   # a face scare is on screen (the HUD helper hides)
var _lodger_running := false
var _whisper_i := 0
var _ghost_script := preload("res://scripts/world/ghost.gd")
var _apparitions: Array = []
var silenced := false

## Suha, between the scares: soft, loving, always asking him to wake up.


func setup(lv: Node) -> void:
	level = lv


func _process(delta: float) -> void:
	if level == null or level.player == null:
		return
	var p: Node3D = level.player
	_cooldown = max(_cooldown - delta, 0.0)
	var idle: bool = p.input_enabled and not p.dead and Vector2(p.velocity.x, p.velocity.z).length() < 0.15 \
		and not level.hud.reading and not get_tree().paused and not level.listener.is_active() and level.space != "chamber"
	_still = _still + delta if idle else 0.0
	if _still > LODGER_DELAY and _cooldown <= 0.0 and not _lodger_running:
		_lodger()
	_update_apparitions(delta)
	_behind_t -= delta
	if _behind_t <= 0.0 and not idle and _cooldown <= 0.0 and not _lodger_running and not p.dead \
			and p.input_enabled and not level.listener.is_active() and level.space in ["surface", "caves", "annex"]:
		_behind_t = randf_range(150.0, 260.0)
		presence_behind()


# ------------------------------------------------------------------ the Lodger
func _lodger() -> void:
	_lodger_running = true
	var p: Node3D = level.player
	var yaw0: float = p.rotation.y
	var breath := AudioStreamPlayer3D.new()
	breath.stream = Sound.get_stream("whisper_2")
	breath.bus = "SFX"
	breath.unit_size = 1.5
	breath.volume_db = -20.0
	add_child(breath)
	var turned := false
	# breathing approaches from behind over a few seconds
	for i in 30:
		if not is_instance_valid(p) or p.dead:
			break
		if Vector2(p.velocity.x, p.velocity.z).length() > 0.6:
			break   # walked away: it loses interest
		var dist: float = lerp(4.0, 0.35, i / 29.0)
		breath.global_position = p.head.global_position + p.global_transform.basis.z * dist + p.global_transform.basis.x * 0.15
		breath.volume_db = lerp(-18.0, -2.0, i / 29.0)
		if i % 10 == 0:
			breath.play()
		level.hud.set_dread(i / 40.0)
		if abs(wrapf(p.rotation.y - yaw0, -PI, PI)) > 2.0 and i > 8:
			turned = true
			break
		await get_tree().create_timer(0.2).timeout
	if is_instance_valid(p) and not p.dead:
		if turned:
			face_scare(1)
		elif Vector2(p.velocity.x, p.velocity.z).length() <= 0.6:
			var wi := _whisper_i % WHISPERS.size()
			var line: String = WHISPERS[wi]
			_whisper_i += 1
			Sound.voice("lodger_%d" % wi, p.head.global_position + p.global_transform.basis.z * 0.25 + p.global_transform.basis.x * 0.2, 2.0)
			Sound.say("[a whisper, right against your ear] " + line, "preecho", 4.5)
			await get_tree().create_timer(1.6).timeout
			level.hud.elias("lodger")
	breath.queue_free()
	level.hud.set_dread(0.0)
	_still = 0.0
	_cooldown = LODGER_COOLDOWN
	_lodger_running = false


# ------------------------------------------------------------------ ghosts
func make_ghost(pos: Vector3, yaw: float, kind := "villager") -> Node3D:
	if kind == "listener":
		var m: Node3D = preload("res://scripts/world/listener_ghost.gd").new()
		add_child(m)
		m.global_position = pos
		m.rotation.y = yaw
		return m
	var g: Node3D = _ghost_script.new()
	g.kind = kind
	add_child(g)
	g.global_position = pos
	g.rotation.y = yaw
	return g


## A figure that is only there while you are not looking straight at it.
## A haunted spot. Nothing stands there waiting to be seen from afar: when you
## come close, something is suddenly right in front of you, grinning, and
## screams, and is gone. opts: range (trigger distance, capped at 7 m),
## require, flag, once (default true), kind ("listener" = the Listener's cage
## face), caption, sting.
func apparition(pos: Vector3, _yaw: float, opts := {}) -> Node3D:
	var m := Node3D.new()
	add_child(m)
	m.global_position = pos
	m.set_meta("opts", opts)
	m.set_meta("cool", 0.0)
	_apparitions.append(m)
	return m


func _update_apparitions(delta: float) -> void:
	var p: Node3D = level.player
	for m in _apparitions.duplicate():
		if not is_instance_valid(m):
			_apparitions.erase(m)
			continue
		var opts: Dictionary = m.get_meta("opts")
		var flag: String = opts.get("flag", "")
		if flag != "" and Game.has_flag(flag):
			m.queue_free()
			_apparitions.erase(m)
			continue
		m.set_meta("cool", max(float(m.get_meta("cool")) - delta, 0.0))
		if m.get_meta("cool") > 0.0 or (opts.has("require") and not Game.has_flag(opts.require)):
			continue
		if (level.space == "surface") != (m.global_position.y > -100.0):
			continue
		var r: float = min(float(opts.get("range", 6.0)), 7.0)
		if p.global_position.distance_to(m.global_position) > r:
			continue
		if p.dead or not p.input_enabled or level.hud.reading or level.listener.is_active() or _lodger_running:
			continue
		if opts.has("caption"):
			Sound.say(opts.caption, "preecho", 3.5)
		face_scare(int(opts.get("sting", 1)), "listener" if opts.get("kind", "") == "listener" else "smile")
		if flag != "":
			Game.set_flag(flag)
		if opts.get("once", true):
			_apparitions.erase(m)
			m.queue_free()
		else:
			m.set_meta("cool", 120.0)


## Turn round, or walk into the wrong place, and it is right there in front of
## your eyes: grinning, staring, then screaming at you, then gone.
func face_scare(sting := 1, kind := "smile") -> void:
	var p: Node3D = level.player
	var cam: Camera3D = p.camera
	var fwd: Vector3 = -cam.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var g: Node3D
	if kind == "listener":
		g = make_ghost(cam.global_position + fwd * 1.1 - Vector3(0, 2.3, 0), atan2(-fwd.x, -fwd.z), "listener")
	else:
		g = make_ghost(cam.global_position + fwd * 0.95 - Vector3(0, 1.57, 0), 0.0, kind)
		g.look_at(Vector3(cam.global_position.x, g.global_position.y, cam.global_position.z), Vector3.UP, true)
	_cooldown = max(_cooldown, 40.0)
	scaring = true
	Sound.play_2d("face_scare", 2.0)
	Sound.play_2d("sting_%d" % sting, -6.0)
	p.shake(1.0)
	level.hud.set_dread(1.0)
	var tw := g.create_tween().set_parallel()
	tw.tween_property(g, "global_position", g.global_position + (cam.global_position - g.global_position) * Vector3(1, 0, 1) * 0.3, 0.6).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.tween_property(g, "rotation:z", 0.05, 0.6)   # the head tilts as it grins at you
	await get_tree().create_timer(0.8).timeout
	if is_instance_valid(g):
		if g.has_method("vanish"):
			g.vanish()
		else:
			g.queue_free()
	level.hud.set_dread(0.0)
	scaring = false


## A face that lunges into view for a moment: loud sting, shake, gone.
## Something is right there: it lunges at you screaming, then is gone.
func jumpscare(pos: Vector3, sting := 0, kind := "face") -> void:
	var cam: Camera3D = level.player.camera
	var g := make_ghost(pos - Vector3(0, 1.55, 0), 0.0, kind)
	g.look_at(Vector3(cam.global_position.x, g.global_position.y, cam.global_position.z), Vector3.UP, true)
	Sound.play_at("ghost_scream", pos, 4.0, {"unit_size": 3.0})
	Sound.play_2d("sting_%d" % sting, -3.0)
	level.player.shake(1.2)
	level.hud.set_dread(1.0)
	var toward: Vector3 = (cam.global_position - pos)
	toward.y = 0.0
	var tw := g.create_tween().set_parallel()
	tw.tween_property(g, "global_position", g.global_position + toward.normalized() * 0.45, 0.22).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(g, "scale", Vector3.ONE * 1.12, 0.22)
	await get_tree().create_timer(0.75).timeout
	if is_instance_valid(g):
		g.vanish()
	level.hud.set_dread(0.0)


## Something follows you, breathing, close behind. Turn round in time and it is
## right there, screaming; keep walking and it falls away.
func presence_behind() -> void:
	var p: Node3D = level.player
	_lodger_running = true
	var breath := AudioStreamPlayer3D.new()
	breath.stream = Sound.get_stream("whisper_2")
	breath.bus = "SFX"
	breath.unit_size = 1.5
	breath.volume_db = -8.0
	add_child(breath)
	breath.play()
	var yaw0: float = p.rotation.y
	var turned := false
	for i in 30:
		if not is_instance_valid(p) or p.dead or level.listener.is_active():
			break
		breath.global_position = p.head.global_position + p.global_transform.basis.z * 0.8
		level.hud.set_dread(0.35)
		if abs(wrapf(p.rotation.y - yaw0, -PI, PI)) > 2.0:
			turned = true
			break
		yaw0 = lerp_angle(yaw0, p.rotation.y, 0.15)   # slow walking turns don't count; a look back does
		await get_tree().create_timer(0.15).timeout
	breath.queue_free()
	level.hud.set_dread(0.0)
	if turned and is_instance_valid(p) and not p.dead:
		face_scare(2)
	_cooldown = LODGER_COOLDOWN
	_lodger_running = false


## The Listener stands in a doorway or at the end of a corridor — until the lights blink.
func listener_glimpse(pos: Vector3, yaw: float, lamp: Light3D = null, time := 1.6) -> void:
	var m: Node3D = preload("res://scripts/enemy/listener_model.gd").new()
	add_child(m)
	m.global_position = pos
	m.rotation.y = yaw
	m.animate(0.016, 0.0, level.player.head.global_position)
	Sound.play_at("listener_strings", pos + Vector3(0, 2, 0), -4.0, {"unit_size": 4.0})
	await get_tree().create_timer(time).timeout
	if lamp:
		var e := lamp.light_energy
		lamp.light_energy = 0.0
		m.queue_free()
		await get_tree().create_timer(0.35).timeout
		lamp.light_energy = e
	else:
		m.queue_free()


## THE THIRTEEN SECONDS. Every sound on the island stops. Then it comes back.
func silence13(on_return: Callable = Callable()) -> void:
	if silenced:
		return
	silenced = true
	level.hud.elias("silence")
	var master := AudioServer.get_bus_index("Master")
	var vol := AudioServer.get_bus_volume_db(master)
	var tw := create_tween()
	tw.tween_method(func(v): AudioServer.set_bus_volume_db(master, v), vol, -80.0, 0.6)
	Sound.say("[silence — the sea, the wind, your own footsteps: nothing]", "aside", 5.0)
	for i in 13:
		await get_tree().create_timer(1.0).timeout
		level.hud.set_dread(i / 14.0)
	AudioServer.set_bus_volume_db(master, vol)
	level.hud.set_dread(0.0)
	silenced = false
	if on_return.is_valid():
		on_return.call()
