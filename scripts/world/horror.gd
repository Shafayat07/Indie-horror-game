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
			jumpscare(p.head.global_position - p.global_transform.basis.z * 0.9, 1)
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
func apparition(pos: Vector3, yaw: float, opts := {}) -> Node3D:
	var g := make_ghost(pos, yaw, opts.get("kind", "villager"))
	g.set_meta("opts", opts)
	g.set_meta("seen", 0.0)
	g.visible = false
	_apparitions.append(g)
	return g


func _update_apparitions(delta: float) -> void:
	var cam: Camera3D = level.player.camera
	for g in _apparitions.duplicate():
		if not is_instance_valid(g):
			_apparitions.erase(g)
			continue
		var opts: Dictionary = g.get_meta("opts")
		var flag: String = opts.get("flag", "")
		if flag != "" and Game.has_flag(flag):
			g.queue_free()
			_apparitions.erase(g)
			continue
		if opts.has("require") and not Game.has_flag(opts.require):
			g.visible = false
			continue
		var to: Vector3 = g.global_position + Vector3(0, 1.5, 0) - cam.global_position
		var d := to.length()
		if d > opts.get("range", 30.0) or (level.space == "surface") != (g.global_position.y > -100.0):
			g.visible = false
			continue
		var facing := (-cam.global_transform.basis.z).dot(to.normalized())
		if not g.visible:
			# appears only while out of view
			if facing < 0.3 and d > 4.0:
				g.visible = true
		else:
			g.look_at(Vector3(cam.global_position.x, g.global_position.y, cam.global_position.z), Vector3.UP, true)
			if facing > 0.93 or d < 3.0:
				g.set_meta("seen", g.get_meta("seen") + delta)
				if g.get_meta("seen") > 0.35:
					_banish(g, opts)


func _banish(g: Node3D, opts: Dictionary) -> void:
	_apparitions.erase(g)
	if opts.get("scare", false):
		Sound.play_2d("sting_%d" % opts.get("sting", 1), -2.0)
		level.player.shake(0.6)
	else:
		Sound.play_at("whisper_1", g.global_position + Vector3(0, 1.6, 0), -4.0, {"unit_size": 3.0})
	if opts.has("caption"):
		Sound.say(opts.caption, "preecho", 3.5)
	if opts.has("flag") and opts.flag != "":
		Game.set_flag(opts.flag)
	if opts.get("once", true):
		g.vanish()
	else:
		g.visible = false
		g.set_meta("seen", 0.0)
		_apparitions.append(g)


## A face that lunges into view for a moment: loud sting, shake, gone.
func jumpscare(pos: Vector3, sting := 0, kind := "face") -> void:
	var cam: Camera3D = level.player.camera
	var g := make_ghost(pos - Vector3(0, 1.55, 0), 0.0, kind)
	g.look_at(Vector3(cam.global_position.x, g.global_position.y, cam.global_position.z), Vector3.UP, true)
	Sound.play_2d("sting_%d" % sting, 0.0)
	level.player.shake(1.2)
	level.hud.set_dread(1.0)
	await get_tree().create_timer(0.45).timeout
	g.queue_free()
	level.hud.set_dread(0.0)


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
