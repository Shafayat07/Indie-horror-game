class_name Door
extends Node3D
## Hinged door. The panel swings open away from the player with a creak.
## Locked doors check a progression flag. Door bodies live on their own physics
## layer so the navigation bake sees them as closed walls: The Listener never
## paths through doorways, which is what makes interiors feel like refuges.

signal opened

var width := 1.0
var height := 2.1
var locked_flag := ""          # flag required to open ("" = unlocked)
var locked_text := "Locked."
var unlock_text := ""          # toast when a locked door is opened with its key
var id := ""                   # persistence id (state flag door_<id>)
var noise_radius := 9.0
var is_open := false
var panel_material: Material
var auto_close := false
var prompt_override := ""
var _hinge: Node3D
var _body: StaticBody3D
var _busy := false


static func make(parent: Node3D, pos: Vector3, yaw: float, opts := {}) -> Door:
	var d := Door.new()
	d.width = opts.get("w", 1.0)
	d.height = opts.get("h", 2.1)
	d.locked_flag = opts.get("lock", "")
	d.locked_text = opts.get("locked_text", "Locked.")
	d.unlock_text = opts.get("unlock_text", "")
	d.id = opts.get("id", "")
	d.noise_radius = opts.get("noise", 9.0)
	d.panel_material = opts.get("mat", B.mat("wood_dark", Color(0.9, 0.85, 0.8), 0.6))
	d.prompt_override = opts.get("prompt", "")
	parent.add_child(d)
	d.position = pos
	d.rotation_degrees.y = yaw
	d._build()
	if d.id != "" and Game.has_flag("door_" + d.id):
		d._set_open_instant()
	return d


func _build() -> void:
	_hinge = Node3D.new()
	add_child(_hinge)
	_hinge.position = Vector3(-width * 0.5, 0, 0)
	_body = StaticBody3D.new()
	_body.collision_layer = B.LAYER_DOOR | B.LAYER_INTERACT
	_body.collision_mask = 0
	_body.set_meta("surface", "wood")
	_hinge.add_child(_body)
	_body.position = Vector3(width * 0.5, height * 0.5, 0)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(width - 0.04, height - 0.02, 0.07)
	mi.mesh = bm
	mi.material_override = panel_material
	_body.add_child(mi)
	var handle := MeshInstance3D.new()
	var hm := BoxMesh.new()
	hm.size = Vector3(0.04, 0.04, 0.16)
	handle.mesh = hm
	handle.material_override = B.flat(Color(0.25, 0.22, 0.18), 0.4, 0.8)
	_body.add_child(handle)
	handle.position = Vector3(width * 0.36, -0.05, 0)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(width - 0.04, height - 0.02, 0.08)
	cs.shape = sh
	_body.add_child(cs)
	_body.set_meta("interact_target", self)
	# Navigation-only blocker: collides with nothing, but the nav bake parses it.
	var nb := StaticBody3D.new()
	nb.collision_layer = B.LAYER_NAVBLOCK
	nb.collision_mask = 0
	var ncs := CollisionShape3D.new()
	var nsh := BoxShape3D.new()
	nsh.size = Vector3(width + 0.3, height, 0.6)
	ncs.shape = nsh
	nb.add_child(ncs)
	add_child(nb)
	nb.position = Vector3(0, height * 0.5, 0)
	# frame
	var fm := B.mat("wood_dark", Color(0.6, 0.55, 0.5), 0.6)
	B.box(self, Vector3(0, height + 0.06, 0), Vector3(width + 0.2, 0.12, 0.26), fm, {"collide": false})


func get_prompt() -> String:
	if prompt_override != "":
		return prompt_override
	return "Close" if is_open else "Open"


func can_interact() -> bool:
	return not _busy


func interact(player: Node) -> void:
	if _busy:
		return
	if not is_open and locked_flag != "" and not Game.has_flag(locked_flag):
		Sound.play_at("door_locked", global_position + Vector3(0, 1, 0), -4.0)
		Sound.emit_noise(global_position, 6.0, "door")
		player.hud.toast(locked_text)
		return
	if not is_open and locked_flag != "" and unlock_text != "" and not Game.has_flag("door_" + id + "_unlocked"):
		Game.set_flag("door_" + id + "_unlocked")
		player.hud.toast(unlock_text)
	var away := 1.0
	var to_player: Vector3 = player.global_position - global_position
	if to_player.dot(global_transform.basis.z) > 0:
		away = -1.0
	_swing(not is_open, away)


func open_from_script(away := 1.0) -> void:
	if not is_open:
		_swing(true, away)


func _swing(open: bool, away: float) -> void:
	_busy = true
	is_open = open
	if id != "":
		if open:
			Game.set_flag("door_" + id)
		else:
			Game.state.flags.erase("door_" + id)
	Sound.play_at("door_creak_%d" % (randi() % 2), global_position + Vector3(0, 1.2, 0), -3.0, {"pitch": randf_range(0.9, 1.1)})
	Sound.emit_noise(global_position, noise_radius, "door")
	var tw := create_tween()
	tw.tween_property(_hinge, "rotation_degrees:y", (95.0 * away) if open else 0.0, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished
	_busy = false
	if open:
		opened.emit()


func _set_open_instant() -> void:
	is_open = true
	_hinge.rotation_degrees.y = 95.0
