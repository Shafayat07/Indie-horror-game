class_name Zone
extends Area3D
## Box trigger volume for the player (and optionally The Listener).
## Used for ambience changes, safe rooms, shallow water, and authored events.

signal entered(body: Node3D)
signal exited(body: Node3D)

var once := false
var ambience := ""
var safe := false
var water := false
var reverb := -1.0
var require_flag := ""
var block_flag := ""
var _fired := false


static func make(parent: Node3D, pos: Vector3, size: Vector3, opts := {}) -> Zone:
	var z := Zone.new()
	z.once = opts.get("once", false)
	z.ambience = opts.get("ambience", "")
	z.safe = opts.get("safe", false)
	z.water = opts.get("water", false)
	z.reverb = opts.get("reverb", -1.0)
	z.require_flag = opts.get("require", "")
	z.block_flag = opts.get("block", "")
	z.collision_layer = 16
	z.collision_mask = 2 | 4
	z.monitorable = false
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	z.add_child(cs)
	parent.add_child(z)
	z.position = pos
	if opts.has("yaw"):
		z.rotation_degrees.y = opts.yaw
	if opts.has("on_enter"):
		z.entered.connect(opts.on_enter)
	return z


func _ready() -> void:
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _on_enter(body: Node3D) -> void:
	if body.is_in_group("listener_ai"):
		if safe:
			body.repelled(self)
		return
	if not body.is_in_group("player"):
		return
	if safe:
		body.set_safe(true)
	if water:
		body.water_zones += 1
	if ambience != "" or reverb >= 0.0:
		body.enter_ambience(self)
	if require_flag != "" and not Game.has_flag(require_flag):
		return
	if block_flag != "" and Game.has_flag(block_flag):
		return
	if once and _fired:
		return
	_fired = true
	entered.emit(body)


func _on_exit(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if safe:
		body.set_safe(false)
	if water:
		body.water_zones = max(body.water_zones - 1, 0)
	if ambience != "" or reverb >= 0.0:
		body.exit_ambience(self)
	exited.emit(body)
