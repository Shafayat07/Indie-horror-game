class_name Player
extends CharacterBody3D
## First-person controller: walk / sprint / crouch, flashlight, surface-aware
## footsteps that emit noise for The Listener, and the interaction ray.

signal stepped(surface: String)

const WALK := 2.7
const SPRINT := 4.9
const CROUCH := 1.35
const STAND_H := 1.75
const CROUCH_H := 1.05
const EYE_STAND := 1.62
const EYE_CROUCH := 0.92
const GRAVITY := 18.0

var hud: Node            # set by the level
var recorder: Node
var head: Node3D
var camera: Camera3D
var flashlight: SpotLight3D
var flash_pivot: Node3D
var input_enabled := true
var look_enabled := true
var crouching := false
var sprinting := false
var dead := false
var safe_zones := 0
var water_zones := 0
var speed_mult := 1.0
var flashlight_on := false

var _shape: CollisionShape3D
var _capsule: CapsuleShape3D
var _ray: RayCast3D
var _floor_ray: RayCast3D
var _ceiling: ShapeCast3D
var _step_player: AudioStreamPlayer3D
var _step_accum := 0.0
var _bob_t := 0.0
var _yaw := 0.0
var _pitch := 0.0
var _focus: Node = null
var _eye := EYE_STAND
var _shake := 0.0
var _last_surface := "stone"


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = B.LAYER_WORLD | B.LAYER_DOOR
	floor_max_angle = deg_to_rad(48)
	floor_snap_length = 0.4
	_capsule = CapsuleShape3D.new()
	_capsule.radius = 0.33
	_capsule.height = STAND_H
	_shape = CollisionShape3D.new()
	_shape.shape = _capsule
	_shape.position.y = STAND_H * 0.5
	add_child(_shape)

	head = Node3D.new()
	head.position.y = EYE_STAND
	add_child(head)
	camera = Camera3D.new()
	camera.fov = Game.settings.fov
	camera.near = 0.05
	camera.far = 600.0
	camera.current = true
	head.add_child(camera)

	flash_pivot = Node3D.new()
	add_child(flash_pivot)
	flashlight = SpotLight3D.new()
	flashlight.light_color = Color(1.0, 0.93, 0.8)
	flashlight.light_energy = 0.0
	flashlight.spot_range = 26.0
	flashlight.spot_angle = 27.0
	flashlight.spot_angle_attenuation = 1.3
	flashlight.spot_attenuation = 0.55
	flashlight.shadow_enabled = true
	flashlight.shadow_bias = 0.04
	flashlight.light_volumetric_fog_energy = 0.6
	flash_pivot.add_child(flashlight)
	flashlight.position = Vector3(0.18, -0.12, -0.1)

	_ray = RayCast3D.new()
	_ray.target_position = Vector3(0, 0, -2.4)
	_ray.collision_mask = B.LAYER_WORLD | B.LAYER_INTERACT | B.LAYER_DOOR
	_ray.collide_with_areas = false
	camera.add_child(_ray)
	_ray.add_exception(self)

	_floor_ray = RayCast3D.new()
	_floor_ray.position.y = 0.3
	_floor_ray.target_position = Vector3(0, -1.2, 0)
	_floor_ray.collision_mask = B.LAYER_WORLD | B.LAYER_DOOR
	add_child(_floor_ray)
	_floor_ray.add_exception(self)

	_ceiling = ShapeCast3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.3
	_ceiling.shape = sph
	_ceiling.position.y = CROUCH_H - 0.3
	_ceiling.target_position = Vector3(0, STAND_H - CROUCH_H + 0.1, 0)
	_ceiling.collision_mask = B.LAYER_WORLD | B.LAYER_DOOR
	add_child(_ceiling)
	_ceiling.add_exception(self)

	_step_player = AudioStreamPlayer3D.new()
	_step_player.bus = "SFX"
	_step_player.unit_size = 3.0
	_step_player.volume_db = -6.0
	add_child(_step_player)
	_step_player.position.y = 0.1

	recorder = preload("res://scripts/player/recorder.gd").new()
	recorder.name = "Recorder"
	add_child(recorder)
	recorder.setup(self)

	Game.settings_changed.connect(func(): camera.fov = Game.settings.fov)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func place(pos: Vector3, yaw_deg: float) -> void:
	global_position = pos
	_yaw = deg_to_rad(yaw_deg)
	_pitch = 0.0
	rotation.y = _yaw
	head.rotation.x = 0.0
	velocity = Vector3.ZERO
	flash_pivot.global_transform = camera.global_transform


func _unhandled_input(event: InputEvent) -> void:
	if dead:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and look_enabled:
		var s: float = Game.settings.mouse_sensitivity * 0.01
		_yaw -= event.relative.x * s
		_pitch -= event.relative.y * s * (-1.0 if Game.settings.invert_y else 1.0)
		_pitch = clamp(_pitch, deg_to_rad(-85), deg_to_rad(85))
	if not input_enabled:
		return
	if event.is_action_pressed("interact"):
		_try_interact()
	elif event.is_action_pressed("flashlight"):
		toggle_flashlight()


func toggle_flashlight(silent := false) -> void:
	flashlight_on = not flashlight_on
	if not silent:
		Sound.play_2d("flashlight", -10.0)
		Sound.emit_noise(global_position, 2.5, "click")
	var tw := create_tween()
	tw.tween_property(flashlight, "light_energy", 2.6 if flashlight_on else 0.0, 0.06)


func _physics_process(delta: float) -> void:
	rotation.y = _yaw
	head.rotation.x = _pitch
	if dead:
		velocity.x = move_toward(velocity.x, 0, delta * 10)
		velocity.z = move_toward(velocity.z, 0, delta * 10)
		velocity.y -= GRAVITY * delta
		move_and_slide()
		return

	var want := Vector2.ZERO
	if input_enabled:
		want = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	# crouch with headroom check so the player can never get stuck uncrouched in a vent
	var want_crouch := input_enabled and Input.is_action_pressed("crouch")
	if want_crouch and not crouching:
		_set_crouch(true)
	elif not want_crouch and crouching:
		_ceiling.force_shapecast_update()
		if not _ceiling.is_colliding():
			_set_crouch(false)
	sprinting = input_enabled and Input.is_action_pressed("sprint") and not crouching and want.y < 0.1 and want.length() > 0.1
	var speed := (CROUCH if crouching else (SPRINT if sprinting else WALK)) * speed_mult
	if recorder.listening:
		speed = min(speed, WALK * 0.75)
	var dir := (transform.basis * Vector3(want.x, 0, want.y))
	dir.y = 0
	dir = dir.normalized() * min(want.length(), 1.0)
	var accel := 10.0 if is_on_floor() else 2.0
	velocity.x = lerp(velocity.x, dir.x * speed, clamp(accel * delta, 0, 1))
	velocity.z = lerp(velocity.z, dir.z * speed, clamp(accel * delta, 0, 1))
	if is_on_floor():
		if input_enabled and Input.is_action_just_pressed("jump") and not crouching:
			velocity.y = 4.2
			Sound.emit_noise(global_position, 6.0, "jump")
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()

	# eye height & subtle bob
	var target_eye := EYE_CROUCH if crouching else EYE_STAND
	_eye = lerp(_eye, target_eye, clamp(delta * 10.0, 0, 1))
	var hspeed := Vector2(velocity.x, velocity.z).length()
	var bob := Vector3.ZERO
	if is_on_floor() and hspeed > 0.3 and not Game.settings.reduced_effects:
		_bob_t += delta * hspeed * 2.2
		bob = Vector3(cos(_bob_t * 0.5) * 0.025, abs(sin(_bob_t * 0.5)) * 0.035, 0)
	head.position = Vector3(bob.x, _eye + bob.y, 0)
	if _shake > 0.0:
		_shake = max(_shake - delta, 0.0)
		var k := _shake * (0.3 if Game.settings.reduced_effects else 1.0)
		camera.h_offset = randf_range(-1, 1) * 0.03 * k
		camera.v_offset = randf_range(-1, 1) * 0.03 * k
	else:
		camera.h_offset = 0
		camera.v_offset = 0

	# flashlight follows the view with a little weight
	var target := camera.global_transform
	flash_pivot.global_transform = flash_pivot.global_transform.interpolate_with(target, clamp(delta * 14.0, 0, 1))

	# footsteps
	if is_on_floor() and hspeed > 0.4:
		_step_accum += hspeed * delta
		var stride := 0.62 if crouching else (0.95 if sprinting else 0.72)
		if _step_accum >= stride:
			_step_accum = 0.0
			_footstep()
	else:
		_step_accum = 0.45

	_update_focus()


func _set_crouch(c: bool) -> void:
	crouching = c
	var h := CROUCH_H if c else STAND_H
	_capsule.height = h
	_shape.position.y = h * 0.5


func surface() -> String:
	if water_zones > 0:
		return "water"
	_floor_ray.force_raycast_update()
	if _floor_ray.is_colliding():
		var c := _floor_ray.get_collider()
		if c and c.has_meta("surface"):
			return c.get_meta("surface")
		if c and c.has_method("surface_at"):
			return c.surface_at(_floor_ray.get_collision_point())
	return "stone"


func _footstep() -> void:
	var s := surface()
	_last_surface = s
	_step_player.stream = Sound.get_stream("step_%s_%d" % [s, randi() % 4])
	_step_player.pitch_scale = randf_range(0.92, 1.08)
	var vol := -14.0 if crouching else (-3.0 if sprinting else -8.0)
	_step_player.volume_db = vol + (3.0 if s == "water" else 0.0)
	_step_player.play()
	# Noise radius The Listener hears. Crouching is near silent; water and metal are loud.
	var radius := 1.5 if crouching else (16.0 if sprinting else 5.0)
	if s == "water" or s == "metal":
		radius *= 1.6
	Sound.emit_noise(global_position, radius, "footstep")
	stepped.emit(s)


func _update_focus() -> void:
	var f: Node = null
	if input_enabled:
		_ray.force_raycast_update()
		if _ray.is_colliding():
			f = _resolve(_ray.get_collider())
	if f != _focus:
		_focus = f
	if hud:
		if _focus and _focus.can_interact():
			hud.set_prompt("[E]  " + _focus.get_prompt())
		else:
			hud.set_prompt("")


func _resolve(c: Object) -> Node:
	if c == null:
		return null
	if c.has_meta("interact_target"):
		return c.get_meta("interact_target")
	var n: Node = c as Node
	while n and n != get_tree().current_scene:
		if n.has_method("interact"):
			return n
		n = n.get_parent()
	return null


func _try_interact() -> void:
	if _focus and _focus.can_interact():
		_focus.interact(self)


func shake(amount: float) -> void:
	_shake = max(_shake, amount)


var _ambience_stack: Array = []


## Ambience zones nest (an interior inside the settlement zone); the innermost wins.
func enter_ambience(z: Node) -> void:
	_ambience_stack.erase(z)
	_ambience_stack.append(z)
	_apply_ambience()


func exit_ambience(z: Node) -> void:
	_ambience_stack.erase(z)
	_apply_ambience()


func _apply_ambience() -> void:
	var amb := ""
	var rv := 0.0
	for z in _ambience_stack:
		if z.ambience != "":
			amb = z.ambience
		if z.reverb >= 0.0:
			rv = z.reverb
	if amb != "":
		Sound.set_zone(amb)
	Sound.set_reverb_space(rv)


func set_safe(entered: bool) -> void:
	safe_zones += 1 if entered else -1
	safe_zones = max(safe_zones, 0)


func is_safe() -> bool:
	return safe_zones > 0


## How visible the player is right now (0..1). Used by The Listener's sight check.
func visibility_factor() -> float:
	var v := 1.0
	if crouching:
		v *= 0.45
	if flashlight_on:
		v *= 1.6
	if sprinting:
		v *= 1.2
	return v


func freeze(on: bool) -> void:
	input_enabled = not on
	look_enabled = not on
	if on:
		velocity = Vector3.ZERO


## Turn the camera smoothly to look at a point (cutscenes, the caught sequence).
func look_toward(point: Vector3, time := 0.6) -> void:
	var to := point - head.global_position
	var target_yaw := atan2(-to.x, -to.z)
	var target_pitch := atan2(to.y, Vector2(to.x, to.z).length())
	var diff := wrapf(target_yaw - _yaw, -PI, PI)
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "_yaw", _yaw + diff, time).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "_pitch", clamp(target_pitch, -1.4, 1.4), time).set_trans(Tween.TRANS_SINE)
	await tw.finished


## Called by The Listener when it reaches the player.
func caught(by: Node3D) -> void:
	if dead:
		return
	dead = true
	input_enabled = false
	look_enabled = false
	if recorder.listening:
		recorder.set_listening(false)
	hud.hide_overlays()
	Sound.play_2d("death_sting", 0.0)
	shake(2.5)
	await look_toward(by.global_position + Vector3(0, 2.1, 0), 0.35)
	hud.death_flash()
	await get_tree().create_timer(2.2).timeout
	hud.show_death_text()
	await get_tree().create_timer(2.0).timeout
	Game.restart_from_checkpoint()
