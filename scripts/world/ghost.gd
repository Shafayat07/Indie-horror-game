extends Node3D
## A drowned islander: pale, wet, rim-lit, slightly transparent. "face" is a
## close-up variant for jumpscares (gaping mouth, empty eyes, torn ears).

var kind := "villager"
var _mat: ShaderMaterial
static var _shader: Shader


func _ready() -> void:
	if _shader == null:
		_shader = Shader.new()
		_shader.code = """
shader_type spatial;
render_mode blend_mix, cull_back, unshaded, depth_prepass_alpha;
uniform vec4 tint : source_color = vec4(0.62, 0.7, 0.72, 1.0);
uniform float alpha = 0.85;
uniform float flicker = 1.0;   // 0 = a calm, dreamy glow (Suha)
void fragment() {
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.2);
	float n = fract(sin(dot(floor(UV * 40.0 + TIME * 3.0), vec2(12.9898, 78.233))) * 43758.5453);
	ALBEDO = tint.rgb * (0.25 + rim * 1.4) + vec3(n * 0.03 * flicker);
	ALPHA = clamp(alpha * (0.55 + rim) * (1.0 - flicker * (0.08 - 0.08 * sin(TIME * 23.0))), 0.0, 1.0);
}
"""
	_mat = ShaderMaterial.new()
	_mat.shader = _shader
	if kind == "suha":
		_mat.set_shader_parameter("tint", Color(1.0, 0.86, 0.74))
		_mat.set_shader_parameter("flicker", 0.0)
	var dark := B.flat(Color(0, 0, 0), 1.0)
	var hair := B.flat(Color(0.02, 0.025, 0.025), 0.3)
	var gore := B.flat(Color(0.25, 0.02, 0.02), 0.3)
	if kind == "smile":
		# right in your face: drowned-white skin, huge black eyes, a grin too wide for it
		_mat.set_shader_parameter("tint", Color(0.6, 0.65, 0.63))
		_mat.set_shader_parameter("alpha", 1.0)
		_mat.set_shader_parameter("flicker", 0.25)
		var teeth := B.flat(Color(0.86, 0.84, 0.74), 0.4)
		var pupil := B.glow(Color(0.95, 0.95, 0.85), 1.5)
		_part(SphereMesh, Vector3(0, 1.55, 0), Vector3(0.25, 0.33, 0.25), _mat)
		_part(SphereMesh, Vector3(0, 1.66, -0.05), Vector3(0.27, 0.24, 0.27), hair)
		for sx in [-1, 1]:
			_part(CylinderMesh, Vector3(sx * 0.2, 1.25, -0.02), Vector3(0.07, 0.75, 0.07), hair)     # wet hair down the sides
			_part(SphereMesh, Vector3(sx * 0.088, 1.6, 0.2), Vector3(0.072, 0.062, 0.035), dark)   # eyes, too big
			_part(SphereMesh, Vector3(sx * 0.088, 1.598, 0.232), Vector3(0.006, 0.006, 0.005), pupil)  # pinprick pupils
			_part(SphereMesh, Vector3(sx * 0.155, 1.475, 0.185), Vector3(0.03, 0.022, 0.02), dark)  # grin corners, pulled up
		_part(SphereMesh, Vector3(0, 1.44, 0.205), Vector3(0.17, 0.045, 0.03), dark)               # the grin
		for i in 15:
			var x := -0.13 + i * 0.0186
			var curve := 0.014 * pow(abs(x) / 0.13, 2.0)
			_part(SphereMesh, Vector3(x, 1.452 + curve, 0.226), Vector3(0.0045, 0.014, 0.004), teeth)          # thin, sharp
			_part(SphereMesh, Vector3(x + 0.009, 1.428 + curve * 0.6, 0.224), Vector3(0.004, 0.012, 0.004), teeth)
		_part(CylinderMesh, Vector3(0, 1.0, 0), Vector3(0.24, 0.9, 0.2), _mat)
	elif kind == "face":
		_part(SphereMesh, Vector3(0, 1.55, 0), Vector3(0.24, 0.3, 0.24), _mat)
		for sx in [-1, 1]:
			_part(SphereMesh, Vector3(sx * 0.08, 1.6, 0.19), Vector3(0.06, 0.05, 0.04), dark)   # empty eyes
			_part(SphereMesh, Vector3(sx * 0.2, 1.55, 0.0), Vector3(0.04, 0.07, 0.05), gore)     # where the ears were
		_part(SphereMesh, Vector3(0, 1.43, 0.18), Vector3(0.07, 0.11, 0.05), dark)               # gaping mouth
		_part(SphereMesh, Vector3(0, 1.68, -0.06), Vector3(0.27, 0.22, 0.27), hair)
		_part(CylinderMesh, Vector3(0, 1.0, 0), Vector3(0.22, 0.9, 0.2), _mat)
	elif kind == "suha":
		# a woman in a long pale dress, hair over one shoulder; warm, never wet
		_part(CylinderMesh, Vector3(0, 0.75, 0), Vector3(0.32, 1.5, 0.32), _mat, 0.1)
		_part(SphereMesh, Vector3(0, 1.62, 0.02), Vector3(0.13, 0.17, 0.14), _mat)
		_part(SphereMesh, Vector3(0, 1.67, -0.03), Vector3(0.15, 0.18, 0.15), B.flat(Color(0.12, 0.07, 0.05), 0.4))
		_part(CylinderMesh, Vector3(0.1, 1.35, 0.05), Vector3(0.07, 0.5, 0.06), B.flat(Color(0.12, 0.07, 0.05), 0.4))
		for sx in [-1, 1]:
			_part(CylinderMesh, Vector3(sx * 0.21, 1.1, 0.04), Vector3(0.05, 0.6, 0.05), _mat)
	else:
		_part(CylinderMesh, Vector3(0, 0.75, 0), Vector3(0.3, 1.5, 0.3), _mat, 0.12)            # long wet shift
		_part(SphereMesh, Vector3(0, 1.62, 0.02), Vector3(0.14, 0.18, 0.15), _mat)
		_part(SphereMesh, Vector3(0, 1.66, -0.04), Vector3(0.16, 0.2, 0.16), hair)
		_part(CylinderMesh, Vector3(0, 1.35, -0.12), Vector3(0.22, 0.6, 0.06), hair)            # hair hanging down the back
		for sx in [-1, 1]:
			_part(SphereMesh, Vector3(sx * 0.05, 1.64, 0.14), Vector3(0.03, 0.025, 0.02), dark)
			_part(CylinderMesh, Vector3(sx * 0.22, 1.05, 0.02), Vector3(0.05, 0.75, 0.05), _mat)
	for c in get_children():
		if c is GeometryInstance3D:
			c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## For cutscenes: shift the figure's colour / opacity / steadiness over time.
func set_look(tint: Color, alpha: float, flicker: float) -> void:
	_mat.set_shader_parameter("tint", tint)
	_mat.set_shader_parameter("alpha", alpha)
	_mat.set_shader_parameter("flicker", flicker)


func _part(mesh_type, pos: Vector3, size: Vector3, m: Material, top := -1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh = mesh_type.new()
	if mesh is SphereMesh:
		mesh.radius = 0.5
		mesh.height = 1.0
		mesh.radial_segments = 12
		mesh.rings = 6
	else:
		mesh.top_radius = (top if top > 0 else 0.5)
		mesh.bottom_radius = 0.5
		mesh.height = 1.0
		mesh.radial_segments = 10
	mi.mesh = mesh
	mi.material_override = m
	add_child(mi)
	mi.position = pos
	mi.scale = size * 2.0 if mesh is SphereMesh else Vector3(size.x * 2.0, size.y, size.z * 2.0)
	return mi


func vanish() -> void:
	var tw := create_tween()
	tw.tween_method(func(v): _mat.set_shader_parameter("alpha", v), 0.85, 0.0, 0.35)
	tw.tween_callback(queue_free)
