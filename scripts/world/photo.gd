class_name PhotoFrame
extends Node3D
## An old framed photograph that is never quite still: film grain, a faint
## flicker, a slow underwater sway. Every so often its haunted twin bleeds
## through for a moment (hollow faces, someone extra behind them). Stare at
## it up close and the haunted version comes in and stays until you look away.

const SHADER := """
shader_type spatial;
uniform sampler2D photo : source_color, filter_linear;
uniform sampler2D haunt : source_color, filter_linear;
uniform float stare = 0.0;
uniform float seed = 0.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	float t = TIME + seed * 17.0;
	vec2 uv = (UV - 0.5) * (1.0 - 0.012 * sin(t * 0.7)) + 0.5;
	uv.x += 0.004 * sin(uv.y * 28.0 + t * 2.3) * stare;
	float cyc = fract(t / 9.0);
	float blip = smoothstep(0.0, 0.02, cyc) * (1.0 - smoothstep(0.04, 0.07, cyc))
		* step(0.45, hash(vec2(floor(t / 9.0), seed)));
	float h = clamp(max(blip * 0.9, stare), 0.0, 1.0);
	vec3 c = mix(texture(photo, uv).rgb, texture(haunt, uv).rgb, h);
	c *= 0.93 + 0.07 * hash(vec2(floor(t * 9.0), seed));
	c += (hash(uv * 420.0 + floor(t * 14.0)) - 0.5) * 0.07;
	ALBEDO = c;
	ROUGHNESS = 0.55;
	EMISSION = c * 0.05;
}
"""

static var _shader: Shader

var _mat: ShaderMaterial
var _stare := 0.0
var _whispered := false


## kind: family, portrait, child, crew, lighthouse, couple. The photo faces local +Z.
static func make(parent: Node3D, pos: Vector3, yaw: float, kind: String, height := 0.34) -> PhotoFrame:
	var f := PhotoFrame.new()
	parent.add_child(f)
	f.position = pos
	f.rotation_degrees.y = yaw
	f._build(kind, height)
	return f


func _build(kind: String, height: float) -> void:
	var tex: Texture2D = load("res://assets/textures/photos/%s.png" % kind)
	var aspect := float(tex.get_width()) / float(tex.get_height())
	var size := Vector2(height * aspect, height)
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER
	_mat = ShaderMaterial.new()
	_mat.shader = _shader
	_mat.set_shader_parameter("photo", tex)
	_mat.set_shader_parameter("haunt", load("res://assets/textures/photos/%s_h.png" % kind))
	_mat.set_shader_parameter("seed", randf() * 10.0)
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = size
	q.mesh = qm
	q.material_override = _mat
	q.position.z = 0.022
	add_child(q)
	var wood := B.mat("wood_dark", Color(0.75, 0.62, 0.5), 1.0)
	B.box(self, Vector3(0, 0, 0.005), Vector3(size.x + 0.06, size.y + 0.06, 0.03), wood, {"collide": false})


func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var to := global_position - cam.global_position
	var close := to.length() < 2.6
	var looking := close and (-cam.global_transform.basis.z).dot(to.normalized()) > 0.97
	_stare = clampf(_stare + (delta * 0.35 if looking else -delta * 1.5), 0.0, 1.0)
	_mat.set_shader_parameter("stare", smoothstep(0.35, 1.0, _stare))
	if _stare > 0.9 and not _whispered:
		_whispered = true
		Sound.play_at("whisper_1", global_position, -10.0, {"unit_size": 1.5})
