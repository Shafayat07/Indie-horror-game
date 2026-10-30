extends Node3D
## Kell's body from the Blender model (assets/models/kell.glb), split into
## body / head / two wings so they can be animated procedurally:
## wingbeats in flight, folded and upside-down while roosting, swept back to dive.

var root: Node3D
var body: Node3D
var head: Node3D
var wing_l: Node3D
var wing_r: Node3D
var _t := 0.0
var _mode := "fly"
var _twitch := 0.0


func _ready() -> void:
	root = Node3D.new()
	add_child(root)
	var scene: Node3D = Models.spawn("res://assets/models/kell.glb", root, Vector3.ZERO)
	for n in scene.find_children("*", "MeshInstance3D", true, false):
		match String(n.name):
			"KellBody": body = n
			"KellHead": head = n
			"KellWingL": wing_l = n
			"KellWingR": wing_r = n
	scale = Vector3.ONE * 1.25
	for n in [body, head, wing_l, wing_r]:
		if n:
			n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


func pose_hang() -> void:
	_mode = "hang"
	root.rotation = Vector3(PI, 0, 0)        # upside down, feet to the ceiling
	root.position = Vector3(0, 0, 0)


func pose_fly() -> void:
	_mode = "fly"
	root.rotation = Vector3(-0.5, 0, 0)      # pitched forward, body trailing
	root.position = Vector3(0, -1.2, 0)


func pose_dive() -> void:
	_mode = "dive"
	root.rotation = Vector3(-1.1, 0, 0)


func pose_dead() -> void:
	_mode = "dead"
	root.rotation = Vector3(-PI * 0.5, 0, 0.3)
	root.position = Vector3(0, 0.2, 0)
	if wing_l:
		wing_l.rotation = Vector3(0, 0, 0.1)
		wing_r.rotation = Vector3(0, 0, -0.1)


func twitch() -> void:
	_twitch = 1.0


func look_toward(_p: Vector3) -> void:
	pass


func animate(delta: float, speed: float) -> void:
	if wing_l == null:
		return
	_t += delta
	_twitch = max(_twitch - delta, 0.0)
	match _mode:
		"hang":
			# wings wrapped around the body, a slow breathing sway
			wing_l.rotation = Vector3(0, 1.35, 0.2)
			wing_r.rotation = Vector3(0, -1.35, -0.2)
			root.rotation.z = sin(_t * 0.6) * 0.04 + sin(_t * 30.0) * 0.06 * _twitch
			if head:
				head.rotation.x = sin(_t * 0.4) * 0.1 + _twitch * 0.5
		"fly":
			var beat := sin(_t * (7.0 + speed * 0.2))
			wing_l.rotation = Vector3(0, 0.15, beat * 0.75)
			wing_r.rotation = Vector3(0, -0.15, -beat * 0.75)
			root.position.y = -1.2 - beat * 0.15
			if head:
				head.rotation.y = sin(_t * 1.7) * 0.5     # the head scanning, listening
		"dive":
			wing_l.rotation = Vector3(0, 0.9, 0.5)
			wing_r.rotation = Vector3(0, -0.9, -0.5)
