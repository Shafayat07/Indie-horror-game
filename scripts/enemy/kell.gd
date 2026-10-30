extends Node3D
## TOMAS KELL — the radio operator, Project Morrow's last subject, now a
## bat-like man who hunts by sonar. He sleeps hanging in the Roost and only
## comes out when the bell strikes the hour, for ten in-game minutes.
## Out hunting he sweeps the woods with clicks: if you are MOVING in the open
## when a sweep passes over you, he screeches and dives. Stand still, or get
## under cover, or catch him in your flashlight. Take his tape and he hunts you
## until you light the radio-tower floodlight.

enum S { ROOST, OUT, WARN, DIVE, STUNNED, RETURN, DEAD }

const TERRITORY := Rect2(-100, 14, 72, 70)       # x, z, w, d — Blackwood
const PING_RANGE := 28.0
const HUNT_MINUTES := 10

var level: Node
var forest: Node
var state: int = S.ROOST
var chase := false
var model: Node3D
var _target := Vector3.ZERO
var _vel := Vector3.ZERO
var _ping_t := 2.0
var _state_t := 0.0
var _dive_target := Vector3.ZERO
var _out_until := 0
var _first_ping := true
var _stir := 0


func _ready() -> void:
	add_to_group("hourly")
	add_to_group("kell")
	model = preload("res://scripts/enemy/kell_model.gd").new()
	add_child(model)


func setup(lv: Node, f: Node) -> void:
	level = lv
	forest = f
	if Game.has_flag("kell_dead"):
		_die_instant()
	elif Game.has_flag("kell_chase"):
		chase = true
		_emerge()
	else:
		_go_roost()


# ------------------------------------------------------------------ schedule
func on_hour(_h: int) -> void:
	if state == S.ROOST and not Game.has_flag("kell_dead"):
		if level.space == "roost":
			Sound.play_at("screech", global_position, 2.0)
			level.hud.toast("The bell. He's waking up — he's leaving the cave.", 3.5)
		_emerge()


func _go_roost() -> void:
	state = S.ROOST
	visible = true
	global_position = forest.roost_hang_point()
	model.pose_hang()


func _emerge() -> void:
	state = S.OUT
	_state_t = 0.0
	_out_until = Game.clock_seconds() + HUNT_MINUTES * 60
	global_position = forest.roost_mouth() + Vector3(0, 6, 0)
	model.pose_fly()
	Sound.play_at("screech", global_position, 4.0, {"unit_size": 18.0, "max_distance": 160.0})
	_pick_target()


func _pick_target() -> void:
	var p: Node3D = level.player
	var focus := Vector3(TERRITORY.position.x + randf() * TERRITORY.size.x, 0, TERRITORY.position.y + randf() * TERRITORY.size.y)
	if chase or randf() < 0.5:
		focus = Vector3(clamp(p.global_position.x, TERRITORY.position.x, TERRITORY.end.x), 0, clamp(p.global_position.z, TERRITORY.position.y, TERRITORY.end.y)) + Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
	_target = Vector3(focus.x, Terrain.height(focus.x, focus.z) + randf_range(9.0, 14.0), focus.z)


# ------------------------------------------------------------------ hearing in the Roost
func roost_noise(radius: float) -> void:
	## Called by the roost while you sneak around under him.
	if state != S.ROOST or radius < 3.0:
		return
	_stir += 1
	Sound.play_at("sonar_%d" % (randi() % 3), global_position, -2.0, {"unit_size": 6.0})
	if _stir == 1:
		Sound.say("[clicking from the ceiling — he's stirring. Quiet. Crouch.]", "sfx", 3.5)
		model.twitch()
	else:
		wake_for_chase()


func wake_for_chase() -> void:
	if chase:
		return
	chase = true
	Game.set_flag("kell_chase")
	level.hud.elias("kell_wakes")
	Sound.play_at("screech", global_position, 6.0, {"unit_size": 12.0})
	if level.space == "roost":
		level.horror.jumpscare(level.player.head.global_position - level.player.camera.global_transform.basis.z * 1.0, 2)
	level.player.shake(1.0)
	await get_tree().create_timer(1.0).timeout
	_emerge()


# ------------------------------------------------------------------ flight & hunting
func _process(delta: float) -> void:
	if level == null or state == S.ROOST or state == S.DEAD:
		if model and state == S.ROOST:
			model.animate(delta, 0.0)
		return
	_state_t += delta
	var p: Node3D = level.player
	match state:
		S.OUT:
			_fly_to(_target, 9.0 if not chase else 12.0, delta)
			if global_position.distance_to(_target) < 3.0:
				_pick_target()
			_ping_t -= delta
			if _ping_t <= 0.0:
				_ping_t = 2.6 if chase else 3.6
				_ping(p)
			if not chase and Game.clock_seconds() >= _out_until and Game.clock_seconds() - _out_until < 3600:
				state = S.RETURN
		S.WARN:
			_fly_to(global_position + Vector3(0, 0.5, 0), 3.0, delta)
			model.look_toward(p.global_position)
			if _state_t > 1.25:
				state = S.DIVE
				_state_t = 0.0
		S.DIVE:
			# he tracks you on the way down and commits only in the last few metres:
			# after the screech, light or a roof saves you, walking on does not
			if _state_t < 0.05 or global_position.distance_to(p.global_position + Vector3(0, 1.0, 0)) > 5.0:
				_dive_target = p.global_position + Vector3(0, 1.0, 0)
			_fly_to(_dive_target, 22.0, delta)
			model.pose_dive()
			if _flashlight_on_me(p):
				_stunned()
			elif global_position.distance_to(_dive_target) < 1.2 or _state_t > 3.0:
				_impact(p)
		S.STUNNED:
			_fly_to(global_position + Vector3(0, 6, 0) - (p.global_position - global_position).normalized() * 4.0, 8.0, delta)
			if _state_t > 3.5:
				state = S.OUT
				model.pose_fly()
				_pick_target()
		S.RETURN:
			var mouth: Vector3 = forest.roost_mouth() + Vector3(0, 2, 0)
			_fly_to(mouth, 10.0, delta)
			if global_position.distance_to(mouth) < 2.5:
				_go_roost()
	model.animate(delta, _vel.length())
	if chase and forest.floodlight_on and global_position.distance_to(forest.floodlight_target()) < 16.0:
		_die()


func _fly_to(t: Vector3, speed: float, delta: float) -> void:
	var to := t - global_position
	var want := to.normalized() * speed if to.length() > 0.1 else Vector3.ZERO
	_vel = _vel.lerp(want, clamp(delta * 2.5, 0, 1))
	global_position += _vel * delta
	var ground := Terrain.height(global_position.x, global_position.z)
	if state != S.DIVE:
		global_position.y = max(global_position.y, ground + 4.0)
	if Vector2(_vel.x, _vel.z).length() > 0.5:
		rotation.y = lerp_angle(rotation.y, atan2(_vel.x, _vel.z), clamp(delta * 4.0, 0, 1))


func _covered(p: Node3D) -> bool:
	var q := PhysicsRayQueryParameters3D.create(p.head.global_position, p.head.global_position + Vector3(0, 8, 0), B.LAYER_WORLD)
	return not get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _ping(p: Node3D) -> void:
	Sound.play_at("sonar_%d" % (randi() % 3), global_position, 2.0, {"unit_size": 14.0, "max_distance": 120.0})
	if level.space != "surface" or p.dead:
		return
	var flat := Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z).length()
	if flat > (40.0 if chase else PING_RANGE):
		return
	if _first_ping:
		_first_ping = false
		Sound.say("[clicks sweep over you from above — STAND STILL]", "hint", 4.0)
	var moving: bool = Vector2(p.velocity.x, p.velocity.z).length() > 0.6
	if Game.debug_ai:
		print("[debug] kell ping flat=%.1f moving=%s covered=%s safe=%s" % [flat, moving, _covered(p), p.is_safe()])
	if moving and not _covered(p) and not p.is_safe():
		state = S.WARN
		_state_t = 0.0
		Sound.play_at("screech", global_position, 4.0, {"unit_size": 14.0})
		Sound.say("[a screech — it's coming down at you]", "sfx", 2.0)


func _flashlight_on_me(p: Node3D) -> bool:
	if not p.flashlight_on:
		return false
	var to: Vector3 = global_position - p.camera.global_position
	return to.length() < 13.0 and (-p.camera.global_transform.basis.z).dot(to.normalized()) > 0.88


func _stunned() -> void:
	state = S.STUNNED
	_state_t = 0.0
	Sound.play_at("screech", global_position, 6.0, {"unit_size": 10.0, "pitch": 1.3})
	Sound.say("[the light hits him — he shrieks and veers away]", "sfx", 3.0)
	model.pose_fly()


func _impact(p: Node3D) -> void:
	if p.global_position.distance_to(global_position) < 2.6 and not _covered(p) and not p.dead and level.space == "surface":
		state = S.OUT
		p.caught(self)
		return
	Sound.play_2d("wingbeat", 0.0)
	state = S.OUT
	_state_t = 0.0
	model.pose_fly()
	_pick_target()


func _die() -> void:
	state = S.DEAD
	Game.set_flag("kell_dead")
	Sound.play_at("screech", global_position, 8.0, {"unit_size": 16.0, "pitch": 0.7})
	level.player.shake(1.0)
	model.pose_dive()
	var ground := Terrain.height(global_position.x, global_position.z)
	var tw := create_tween()
	tw.tween_property(self, "global_position:y", ground + 0.4, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	model.pose_dead()
	Sound.play_at("door_slam", global_position, 0.0)
	level.hud.elias("kell_dead", 1.5)
	level.checkpoint("forest")


func _die_instant() -> void:
	state = S.DEAD
	var p: Vector3 = forest.floodlight_target() + Vector3(3, 0, 2)
	global_position = Vector3(p.x, Terrain.height(p.x, p.z) + 0.4, p.z)
	model.pose_dead()
