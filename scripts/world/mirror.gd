class_name HauntedMirror
extends Node3D
## A small wall mirror that really shows the room (a second camera looking
## back through the glass). Elias is not in it. Once, someone else is: a
## drowned figure standing right behind him, drawn on a layer only the
## mirror's camera can see.

const GHOST_LAYER := 1 << 19
const SELF_LAYER := 1 << 18    # the mirror's own frame and glass: its camera looks past them
const SIZE := Vector2(0.5, 0.66)

var level: Node
var require_flag := ""
var _vp: SubViewport
var _cam: Camera3D
var _look := 0.0
var _haunting := false


static func make(parent: Node3D, pos: Vector3, yaw: float, lv: Node, require := "") -> HauntedMirror:
	var m := HauntedMirror.new()
	m.level = lv
	m.require_flag = require
	parent.add_child(m)
	m.position = pos
	m.rotation_degrees.y = yaw
	return m


func _ready() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(192, 256)
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_vp)
	_cam = Camera3D.new()
	_cam.cull_mask = 0xFFFFF & ~SELF_LAYER
	_vp.add_child(_cam)
	var glass := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = SIZE
	glass.mesh = qm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = _vp.get_texture()
	mat.albedo_color = Color(0.9, 0.95, 0.97)
	mat.uv1_scale = Vector3(-1, 1, 1)   # a mirror is flipped left to right
	mat.uv1_offset = Vector3(1, 0, 0)
	glass.material_override = mat
	glass.position.z = 0.03
	glass.layers = SELF_LAYER
	add_child(glass)
	var frame := B.mat("wood_dark", Color(0.8, 0.7, 0.6), 1.0)
	B.box(self, Vector3(0, 0, 0.01), Vector3(SIZE.x + 0.08, SIZE.y + 0.08, 0.03), frame, {"collide": false}).layers = SELF_LAYER
	# the room's main camera never draws the mirror's ghost layer
	if level and level.player:
		level.player.camera.cull_mask &= ~GHOST_LAYER


func _process(delta: float) -> void:
	var pc := get_viewport().get_camera_3d()
	if pc == null or pc == _cam:
		return
	var n := global_transform.basis.z.normalized()
	var o := global_position + n * 0.03
	var d := (pc.global_position - o).dot(n)
	var near := pc.global_position.distance_to(o) < 6.0 and d > 0.1
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if near else SubViewport.UPDATE_DISABLED
	if not near:
		_look = 0.0
		return
	# the reflected eye, looking back through the glass
	var rp := pc.global_position - n * 2.0 * d
	var dist := rp.distance_to(o)
	_cam.global_position = rp
	_cam.look_at(o, Vector3.UP)
	_cam.fov = rad_to_deg(2.0 * atan(SIZE.y * 0.5 / dist))
	_cam.near = max(0.05, dist - 0.06)
	_cam.far = 40.0
	# looking into it for a moment, close up, is enough
	var facing := (-pc.global_transform.basis.z).dot((o - pc.global_position).normalized())
	if facing > 0.93 and dist < 7.0 and not _haunting and not Game.has_flag("mirror_ghost") \
			and (require_flag == "" or Game.has_flag(require_flag)):
		_look += delta
		if _look > 1.2:
			_haunt()


func _haunt() -> void:
	_haunting = true
	Game.set_flag("mirror_ghost")
	var p: Node3D = level.player
	var back: Vector3 = p.global_transform.basis.z
	back.y = 0.0
	var pos: Vector3 = p.global_position + back.normalized() * 0.9
	var g: Node3D = level.horror.make_ghost(pos, p.rotation.y, "villager")
	await get_tree().process_frame
	for v in g.find_children("*", "VisualInstance3D", true, false):
		(v as VisualInstance3D).layers = GHOST_LAYER
	Sound.play_at("whisper_2", pos + Vector3(0, 1.6, 0), -6.0)
	await get_tree().create_timer(1.8).timeout
	Sound.play_2d("sting_1", -4.0)
	level.player.shake(0.4)
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(g):
		g.queue_free()
	level.hud.elias("mirror", 0.6)
