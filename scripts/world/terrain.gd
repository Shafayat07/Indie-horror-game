class_name Terrain
extends StaticBody3D
## Vey Isle's ground: a deterministic height function (shared with every
## builder so props sit on the ground), rendered as a mesh with a slope/height
## blended shader and collided with a HeightMapShape3D.

const CELL := 2.0
const MIN_X := -130.0
const MAX_X := 130.0
const MIN_Z := -140.0
const MAX_Z := 150.0
const SEA_FLOOR := -9.0

static var _noise: FastNoiseLite
static var _detail: FastNoiseLite

## Flattened pads: [x, z, radius, height, falloff]
const PADS := [
	[0.0, 79.0, 7.0, 1.9, 6.0],      # dock landing
	[8.0, 72.0, 6.0, 2.1, 5.0],      # shed
	[0.0, 45.0, 26.0, 4.2, 10.0],    # settlement
	[-2.0, 25.0, 12.0, 4.4, 8.0],    # square / junction
	[-56.0, -8.0, 22.0, 6.5, 10.0],  # weather station
	[0.0, -82.0, 13.0, 16.5, 8.0],   # lighthouse
	[42.0, 10.0, 6.0, 4.6, 6.0],     # cliff top lookout
]

## Paths: [ax, az, bx, bz, half_width, height_a, height_b] (NAN = keep terrain)
const PATHS := [
	[0.0, 80.0, 0.0, 62.0, 1.8, 1.9, 3.7],
	[0.0, 62.0, 0.0, 22.0, 2.2, 3.7, 4.4],
	[-2.0, 22.0, -36.0, -6.0, 2.0, 4.4, 6.4],
	[-36.0, -6.0, -46.0, -8.0, 2.0, 6.4, 6.5],
	[0.0, 22.0, 0.0, 5.0, 2.0, 4.4, 5.6],
	[0.0, 5.0, 0.0, -70.0, 2.0, 5.6, 16.5],
	[2.0, 24.0, 42.0, 10.0, 2.0, 4.4, 4.6],
	[42.0, 10.0, 52.0, 2.0, 1.6, 4.6, 2.0],
	[52.0, 2.0, 62.0, -4.0, 1.6, 2.0, -0.9],
]


static func _init_noise() -> void:
	if _noise:
		return
	_noise = FastNoiseLite.new()
	_noise.seed = 4242
	_noise.frequency = 0.012
	_noise.fractal_octaves = 4
	_detail = FastNoiseLite.new()
	_detail.seed = 77
	_detail.frequency = 0.08
	_detail.fractal_octaves = 2


static func _smooth(e0: float, e1: float, x: float) -> float:
	return smoothstep(e0, e1, x)


## Raw landform before pads and paths.
static func _base(x: float, z: float) -> float:
	_init_noise()
	var n := _noise.get_noise_2d(x, z)
	# Island silhouette: an ellipse, pushed outward in the north for the headland.
	var rz := 88.0 if z > -5.0 else 102.0
	var d := Vector2(x / 96.0, (z + 5.0) / rz).length() + n * 0.10
	var land := 1.0 - _smooth(0.86, 1.0, d)
	var h := 3.6 + n * 2.2 + _detail.get_noise_2d(x, z) * 0.35
	# the lighthouse headland
	var lh := Vector2(x, z + 82.0).length()
	h += 12.5 * exp(-(lh * lh) / (2.0 * 30.0 * 30.0))
	# a ridge behind the station so the west feels enclosed
	h += 6.0 * exp(-pow((x + 82.0) / 14.0, 2.0)) * _smooth(-60.0, -20.0, z) * (1.0 - _smooth(30.0, 60.0, z))
	h = lerp(SEA_FLOOR, h, land)
	# East cliffs and the tidal shelf exposed at low tide (x 58..75, z -50..20)
	var zone := _smooth(28.0, 18.0, z) * _smooth(-62.0, -52.0, z)
	if zone > 0.0:
		var cliff := lerp(h, -1.0, _smooth(50.0, 56.0, x))
		cliff = lerp(cliff, SEA_FLOOR, _smooth(74.0, 84.0, x))
		cliff += _detail.get_noise_2d(x * 2.0, z * 2.0) * 0.25 * _smooth(57.0, 60.0, x)
		h = lerp(h, cliff, zone)
	return h


static func height(x: float, z: float) -> float:
	var h := _base(x, z)
	for p in PADS:
		var d := Vector2(x - p[0], z - p[1]).length()
		var w := 1.0 - _smooth(p[2], p[2] + p[4], d)
		h = lerp(h, p[3], w)
	var pw := path_weight(x, z)
	if pw.x > 0.0:
		h = lerp(h, pw.y, pw.x)
	return h


## Returns Vector2(weight, height) for the nearest path.
static func path_weight(x: float, z: float) -> Vector2:
	var best := Vector2.ZERO
	var p := Vector2(x, z)
	for s in PATHS:
		var a := Vector2(s[0], s[1])
		var b := Vector2(s[2], s[3])
		var ab := b - a
		var t: float = clamp((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var d := p.distance_to(a + ab * t)
		var w := 1.0 - _smooth(s[4], s[4] + 2.5, d)
		if w > best.x:
			best = Vector2(w, lerp(float(s[5]), float(s[6]), t))
	return best


static func ground(x: float, z: float) -> float:
	return height(x, z)


func build() -> void:
	collision_layer = B.LAYER_WORLD
	collision_mask = 0
	set_meta("surface", "grass")
	var nx := int((MAX_X - MIN_X) / CELL) + 1
	var nz := int((MAX_Z - MIN_Z) / CELL) + 1
	var heights := PackedFloat32Array()
	heights.resize(nx * nz)
	var paths := PackedFloat32Array()
	paths.resize(nx * nz)
	for iz in nz:
		for ix in nx:
			var x := MIN_X + ix * CELL
			var z := MIN_Z + iz * CELL
			heights[iz * nx + ix] = height(x, z)
			paths[iz * nx + ix] = path_weight(x, z).x
	# visual mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in nz:
		for ix in nx:
			var i := iz * nx + ix
			st.set_color(Color(paths[i], 0, 0))
			st.set_uv(Vector2(ix, iz))
			st.add_vertex(Vector3(MIN_X + ix * CELL, heights[i], MIN_Z + iz * CELL))
	for iz in nz - 1:
		for ix in nx - 1:
			var a := iz * nx + ix
			var b := a + 1
			var c := a + nx
			var d := c + 1
			st.add_index(a); st.add_index(b); st.add_index(c)
			st.add_index(b); st.add_index(d); st.add_index(c)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _material()
	add_child(mi)
	# collision: heightmap uses 1 m cells, so scale the shape node by CELL
	var hs := HeightMapShape3D.new()
	hs.map_width = nx
	hs.map_depth = nz
	var scaled := PackedFloat32Array()
	scaled.resize(heights.size())
	for i in heights.size():
		scaled[i] = heights[i] / CELL
	hs.map_data = scaled
	var cs := CollisionShape3D.new()
	cs.shape = hs
	cs.scale = Vector3(CELL, CELL, CELL)
	cs.position = Vector3((MIN_X + MAX_X) * 0.5, 0, (MIN_Z + MAX_Z) * 0.5)
	add_child(cs)


func surface_at(p: Vector3) -> String:
	if path_weight(p.x, p.z).x > 0.5:
		return "gravel"
	if p.y < 1.2:
		return "gravel"
	return "grass"


func _material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
uniform sampler2D grass_a : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_n : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_a : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_n : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D gravel_a : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand_a : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float tide = 0.0;
varying vec3 wpos;
varying vec3 wnorm;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec2 uv = wpos.xz * 0.16;
	float slope = 1.0 - wnorm.y;
	vec3 bw = pow(abs(wnorm), vec3(4.0));
	bw /= (bw.x + bw.y + bw.z);
	vec3 r = texture(rock_a, wpos.zy * 0.09).rgb * bw.x + texture(rock_a, wpos.xz * 0.09).rgb * bw.y + texture(rock_a, wpos.xy * 0.09).rgb * bw.z;
	vec3 rn = texture(rock_n, wpos.zy * 0.09).rgb * bw.x + texture(rock_n, wpos.xz * 0.09).rgb * bw.y + texture(rock_n, wpos.xy * 0.09).rgb * bw.z;
	vec3 g = texture(grass_a, uv).rgb;
	vec3 g2 = texture(grass_a, uv * 0.23 + 0.31).rgb;
	g = mix(g, g2, 0.35);
	vec3 gr = texture(gravel_a, uv * 1.4).rgb;
	vec3 s = texture(sand_a, uv * 0.8).rgb;
	float rock_w = smoothstep(0.22, 0.42, slope + (g2.g - 0.2) * 0.4);
	float sand_w = smoothstep(1.8, 0.7, wpos.y);
	float path_w = smoothstep(0.3, 0.8, COLOR.r) * (1.0 - rock_w * 0.7);
	vec3 col = mix(g, s, sand_w);
	col = mix(col, gr, path_w);
	col = mix(col, r, rock_w);
	// wet line left by the tide
	float wet = smoothstep(tide + 3.2, tide + 0.2, wpos.y);
	col *= mix(1.0, 0.55, wet);
	ALBEDO = col;
	ROUGHNESS = mix(mix(0.92, 0.7, rock_w), 0.25, wet);
	NORMAL_MAP = mix(texture(grass_n, uv).rgb, rn, rock_w);
	NORMAL_MAP_DEPTH = 1.2;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("grass_a", load(B.TEX + "grass_coastal_albedo.png"))
	m.set_shader_parameter("grass_n", load(B.TEX + "grass_coastal_normal.png"))
	m.set_shader_parameter("rock_a", load(B.TEX + "cliff_albedo.png"))
	m.set_shader_parameter("rock_n", load(B.TEX + "cliff_normal.png"))
	m.set_shader_parameter("gravel_a", load(B.TEX + "gravel_albedo.png"))
	m.set_shader_parameter("sand_a", load(B.TEX + "sand_wet_albedo.png"))
	return m
