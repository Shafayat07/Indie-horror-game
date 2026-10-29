extends CharacterBody3D
## THE LISTENER. Hears noise (and pre-echoes: sounds that have not happened
## yet), sees only at short range, never passes a doorway or a ringed safe
## room, and gives up a chase it cannot sustain.
##
## States: DORMANT, ROAMING, INVESTIGATING, SEARCHING, HUNTING, RETURNING.

enum S { DORMANT, ROAMING, INVESTIGATING, SEARCHING, HUNTING, RETURNING }
const NAMES := ["DORMANT", "ROAMING", "INVESTIGATING", "SEARCHING", "HUNTING", "RETURNING"]
const SPEED := {S.ROAMING: 1.25, S.INVESTIGATING: 2.2, S.SEARCHING: 1.0, S.HUNTING: 3.6, S.RETURNING: 1.5}
const CATCH_DIST := 1.45
const HUNT_MAX := 22.0
const LOSE_TIME := 4.5
const GRAVITY := 18.0

var level: Node
var state: int = S.DORMANT
var patrol: Array = []
var patrol_i := 0
var hearing := 1.0
var sight := 1.0
var suspicion := 0.0
var target := Vector3.ZERO
var head_target: Variant = null
var last_seen := Vector3.ZERO
var lost_time := 0.0
var state_time := 0.0
var wait := 0.0
var search_center := Vector3.ZERO
var hunt_enabled := true
var silent := false
var frozen := false        # finale: it stops to listen for the choice

var agent: NavigationAgent3D
var model: Node3D
var _strings: AudioStreamPlayer3D
var _steps: AudioStreamPlayer3D
var _debug: Label3D
var _sight_timer := 0.0
var _stuck_timer := 0.0
var _stuck_pos := Vector3.ZERO
var _step_phase := 0.0
var _player: Node3D


func _ready() -> void:
	add_to_group("listener_ai")
	collision_layer = 4
	collision_mask = B.LAYER_WORLD | B.LAYER_DOOR
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.42
	cap.height = 2.4
	cs.shape = cap
	cs.position.y = 1.2
	add_child(cs)
	agent = NavigationAgent3D.new()
	agent.path_desired_distance = 0.7
	agent.target_desired_distance = 0.9
	agent.path_max_distance = 3.0
	agent.radius = 0.5
	agent.height = 2.4
	add_child(agent)
	model = preload("res://scripts/enemy/listener_model.gd").new()
	add_child(model)
	_strings = Sound.attach_loop(self, "listener_strings", -6.0, {"unit_size": 2.2, "max_distance": 16.0, "offset": Vector3(0, 2.0, 0)})
	_steps = AudioStreamPlayer3D.new()
	_steps.bus = "SFX"
	_steps.unit_size = 7.0
	_steps.max_distance = 60.0
	add_child(_steps)
	if Game.debug_ai:
		_debug = Label3D.new()
		_debug.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_debug.position.y = 3.0
		_debug.font_size = 48
		_debug.no_depth_test = true
		add_child(_debug)
	_set_dormant()


func _set_dormant() -> void:
	state = S.DORMANT
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	_strings.stop()
	global_position = Vector3(0, -500, 0)
	if level and level.hud:
		level.hud.set_dread(0.0)


## Bring The Listener into an area at `pos`, patrolling `points`.
func activate(pos: Vector3, points: Array, start_state := S.ROAMING) -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true
	frozen = false
	global_position = pos
	velocity = Vector3.ZERO
	patrol = points
	patrol_i = 0
	suspicion = 0.0
	_strings.play()
	_change(start_state)
	if start_state == S.ROAMING and points.size() > 0:
		_go(points[0])


func deactivate() -> void:
	_set_dormant()


func is_active() -> bool:
	return state != S.DORMANT


func _change(s: int) -> void:
	state = s
	state_time = 0.0
	wait = 0.0
	_stuck_timer = 0.0
	silent = s == S.SEARCHING


func _go(p: Vector3) -> void:
	var map := get_world_3d().navigation_map
	target = p if NavigationServer3D.map_get_iteration_id(map) == 0 else NavigationServer3D.map_get_closest_point(map, p)
	agent.target_position = target


# ------------------------------------------------------------------ senses
func hear(pos: Vector3, radius: float, kind: String) -> void:
	if state == S.DORMANT or frozen:
		return
	if abs(pos.y - global_position.y) > 14.0:
		return   # different space (caves vs. surface)
	var d := global_position.distance_to(pos)
	if d > radius * hearing:
		return
	if state == S.HUNTING:
		# A lure only works once it has lost sight of you.
		if kind == "replay_echo" and lost_time > 1.0:
			_investigate(pos)
		return
	_investigate(pos)


func _investigate(pos: Vector3) -> void:
	head_target = pos + Vector3(0, 1.0, 0)
	_change(S.INVESTIGATING)
	wait = 0.7  # the head turns first; the body follows a moment later
	_go(pos)


func _player_node() -> Node3D:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	return _player


func _can_see_player(p: Node3D) -> bool:
	if p.dead or p.is_safe():
		return false
	var eye: Vector3 = model.head.global_position
	var to: Vector3 = p.head.global_position - eye
	var d := to.length()
	var rng: float = 10.0 * sight * p.visibility_factor()
	if d > rng:
		return false
	if d > 2.2:
		var fwd: Vector3 = model.head.global_transform.basis.z
		if fwd.angle_to(to) > deg_to_rad(70):
			return false
	var q := PhysicsRayQueryParameters3D.create(eye, p.head.global_position, B.LAYER_WORLD | B.LAYER_DOOR)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return hit.is_empty()


# ------------------------------------------------------------------ brain
func _physics_process(delta: float) -> void:
	if state == S.DORMANT:
		return
	var p := _player_node()
	state_time += delta
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -1.0

	_sight_timer -= delta
	if _sight_timer <= 0.0 and p and not frozen:
		_sight_timer = 0.15
		var seen := _can_see_player(p)
		if seen:
			last_seen = p.global_position
			lost_time = 0.0
			if state != S.HUNTING:
				var close := global_position.distance_to(p.global_position) < 4.0
				suspicion += 0.15 * (3.0 if close else 1.3)
				head_target = p.head.global_position
				if suspicion >= 1.0 and hunt_enabled:
					_start_hunt()
		else:
			suspicion = max(suspicion - 0.04, 0.0)
			if state == S.HUNTING:
				lost_time += 0.15

	var speed := 0.0
	match state:
		S.ROAMING:
			if wait > 0.0:
				wait -= delta
				head_target = null
			elif agent.is_navigation_finished():
				wait = randf_range(2.0, 5.0)
				patrol_i = (patrol_i + 1) % max(patrol.size(), 1)
				if patrol.size() > 0:
					_go(patrol[patrol_i])
			else:
				speed = SPEED[S.ROAMING]
		S.INVESTIGATING:
			if wait > 0.0:
				wait -= delta
			elif agent.is_navigation_finished() or state_time > 25.0:
				search_center = global_position
				_change(S.SEARCHING)
			else:
				speed = SPEED[S.INVESTIGATING]
		S.SEARCHING:
			if state_time > 9.0:
				_return()
			elif wait > 0.0:
				wait -= delta
			elif agent.is_navigation_finished():
				wait = randf_range(1.0, 2.5)
				var off := Vector3(randf_range(-6, 6), 0, randf_range(-6, 6))
				_go(search_center + off)
				head_target = search_center + off + Vector3(0, 1.0, 0)
			else:
				speed = SPEED[S.SEARCHING]
		S.HUNTING:
			if p == null or p.is_safe() or lost_time > LOSE_TIME or state_time > HUNT_MAX:
				search_center = last_seen
				_change(S.SEARCHING)
				_go(last_seen)
			else:
				_go(p.global_position if lost_time <= 0.0 else last_seen)
				head_target = p.head.global_position
				speed = SPEED[S.HUNTING]
				if global_position.distance_to(p.global_position) < CATCH_DIST and lost_time <= 0.3 and not p.dead:
					_catch(p)
					return
		S.RETURNING:
			if agent.is_navigation_finished():
				_change(S.ROAMING)
				wait = 1.0
			else:
				speed = SPEED[S.RETURNING]

	if frozen:
		speed = 0.0
	var hv := Vector3.ZERO
	if speed > 0.0 and not agent.is_navigation_finished():
		var next := agent.get_next_path_position()
		var dir := next - global_position
		dir.y = 0
		if dir.length() > 0.05:
			dir = dir.normalized()
			hv = dir * speed
			var yaw := atan2(dir.x, dir.z)
			rotation.y = lerp_angle(rotation.y, yaw, clamp(delta * 5.0, 0, 1))
		_check_stuck(delta)
	velocity.x = hv.x
	velocity.z = hv.z
	move_and_slide()
	_feedback(delta, Vector2(velocity.x, velocity.z).length(), p)


func _check_stuck(delta: float) -> void:
	_stuck_timer += delta
	if _stuck_timer > 3.0:
		if global_position.distance_to(_stuck_pos) < 0.4:
			# cannot progress: abandon the current goal instead of grinding into a wall
			if state == S.HUNTING:
				search_center = last_seen
				_change(S.SEARCHING)
			elif state == S.ROAMING:
				patrol_i = (patrol_i + 1) % max(patrol.size(), 1)
				if patrol.size() > 0:
					_go(patrol[patrol_i])
			else:
				_return()
		_stuck_timer = 0.0
		_stuck_pos = global_position


func _start_hunt() -> void:
	_change(S.HUNTING)
	suspicion = 0.0
	lost_time = 0.0
	Sound.play_at("listener_cry", global_position + Vector3(0, 2.2, 0), 2.0, {"unit_size": 10.0, "max_distance": 90.0})
	Sound.say("[a sound like rope pulled taut to breaking]", "sfx", 3.0)


func _return() -> void:
	_change(S.RETURNING)
	head_target = null
	if patrol.is_empty():
		_go(global_position)
		return
	var best := 0
	for i in patrol.size():
		if global_position.distance_to(patrol[i]) < global_position.distance_to(patrol[best]):
			best = i
	patrol_i = best
	_go(patrol[best])


func _catch(p: Node3D) -> void:
	frozen = true
	velocity = Vector3.ZERO
	look_at(Vector3(p.global_position.x, global_position.y, p.global_position.z), Vector3.UP, true)
	p.caught(self)


## Entered a ringed safe room: back out and wait outside.
func repelled(_zone: Node) -> void:
	if state == S.DORMANT:
		return
	var back := global_position - global_transform.basis.z * 2.5
	search_center = back
	_change(S.SEARCHING)
	_go(back)


func _feedback(delta: float, speed: float, p: Node3D) -> void:
	model.animate(delta, speed, head_target)
	var d := 99.0
	if p:
		d = global_position.distance_to(p.global_position)
	model.vibrate = clamp(1.0 - d / 8.0, 0.0, 1.0) + (0.6 if state == S.HUNTING else 0.0)
	# hollow footsteps — except while searching, when it makes no sound at all
	if speed > 0.2:
		_step_phase += delta * speed * 0.75
		if _step_phase >= 1.0:
			_step_phase = 0.0
			if not silent:
				_steps.stream = Sound.get_stream("listener_step_%d" % (randi() % 3))
				_steps.volume_db = 2.0 if state == S.HUNTING else -3.0
				_steps.pitch_scale = randf_range(0.9, 1.05)
				_steps.play()
	_strings.volume_db = lerp(_strings.volume_db, 2.0 if state == S.HUNTING else -6.0, delta * 2.0)
	if level and level.hud:
		var dr: float = clamp(1.0 - d / 16.0, 0.0, 1.0)
		if state == S.HUNTING:
			dr = max(dr, 0.55)
		level.hud.set_dread(dr)
	if _debug:
		_debug.text = "%s  s%.1f" % [NAMES[state], suspicion]
