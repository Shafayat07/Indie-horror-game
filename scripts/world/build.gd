class_name B
## Procedural construction helpers. The whole island is assembled from these
## so that geometry, collision, footstep surfaces and materials stay consistent.

const TEX := "res://assets/textures/"
const LAYER_WORLD := 1
const LAYER_INTERACT := 8
const LAYER_DOOR := 32
const LAYER_NAVBLOCK := 64

static var _mats := {}
static var _rock_meshes := []
static var _rock_shapes := {}


## Triplanar PBR material from one of the generated texture sets.
## Weathering defaults per texture set: [grime, moss, wet]. Override with
## extra {"grime", "moss", "wet"}; extra {"world": false} keeps the plain
## StandardMaterial3D (object-space, for creature skins and moving models).
const WEATHER := {
	"stone_blocks": [0.6, 0.55, 0.35], "whitewash": [0.6, 0.35, 0.25], "cliff": [0.5, 0.6, 0.45],
	"stone_wet": [0.5, 0.5, 0.8], "rock_cave": [0.45, 0.0, 0.85], "concrete": [0.65, 0.3, 0.3],
	"plaster_white": [0.55, 0.0, 0.15], "roof": [0.5, 0.6, 0.3], "slate": [0.5, 0.55, 0.35],
	"wood_planks": [0.6, 0.2, 0.4], "wood_dark": [0.5, 0.0, 0.15], "wood_painted": [0.55, 0.1, 0.2],
	"metal_rust": [0.55, 0.0, 0.35], "metal_green": [0.5, 0.0, 0.3], "metal_red": [0.5, 0.0, 0.25],
	"cobble": [0.55, 0.35, 0.6], "gravel": [0.5, 0.2, 0.4], "sand_wet": [0.4, 0.0, 0.7],
	"bark": [0.5, 0.4, 0.2], "rope": [0.45, 0.0, 0.4], "wallpaper": [0.6, 0.0, 0.1],
}
static var _surface: Shader


static func mat(tex: String, tint := Color.WHITE, scale := 0.35, extra := {}) -> Material:
	var key := "%s|%s|%s|%s" % [tex, tint, scale, extra]
	if _mats.has(key):
		return _mats[key]
	if extra.get("world", true) and WEATHER.has(tex):
		if _surface == null:
			_surface = load("res://assets/shaders/surface.gdshader")
		var w: Array = WEATHER[tex]
		var sm := ShaderMaterial.new()
		sm.shader = _surface
		sm.set_shader_parameter("tint", tint)
		sm.set_shader_parameter("tex_albedo", load(TEX + tex + "_albedo.png"))
		sm.set_shader_parameter("tex_normal", load(TEX + tex + "_normal.png"))
		sm.set_shader_parameter("tex_rough", load(TEX + tex + "_rough.png"))
		sm.set_shader_parameter("tex_macro", load(TEX + "macro.png"))
		sm.set_shader_parameter("tex_moss", load(TEX + "moss_albedo.png"))
		sm.set_shader_parameter("uv_scale", scale)
		sm.set_shader_parameter("normal_scale", extra.get("normal", 1.0))
		sm.set_shader_parameter("roughness", extra.get("roughness", 1.0))
		sm.set_shader_parameter("metallic", extra.get("metallic", 0.0))
		sm.set_shader_parameter("grime", extra.get("grime", w[0]))
		sm.set_shader_parameter("moss", extra.get("moss", w[1]))
		sm.set_shader_parameter("wet", extra.get("wet", w[2]))
		_mats[key] = sm
		return sm
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(TEX + tex + "_albedo.png")
	m.albedo_color = tint
	m.normal_enabled = true
	m.normal_texture = load(TEX + tex + "_normal.png")
	m.normal_scale = extra.get("normal", 1.0)
	m.roughness_texture = load(TEX + tex + "_rough.png")
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	m.roughness = extra.get("roughness", 1.0)
	m.metallic = extra.get("metallic", 0.0)
	m.uv1_triplanar = true
	m.uv1_world_triplanar = extra.get("world", true)
	m.uv1_scale = Vector3.ONE * scale
	m.uv1_triplanar_sharpness = 4.0
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_mats[key] = m
	return m


static func flat(color: Color, roughness := 0.8, metallic := 0.0) -> StandardMaterial3D:
	var key := "flat|%s|%s|%s" % [color, roughness, metallic]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	_mats[key] = m
	return m


static func glow(color: Color, energy := 2.0, unshaded := false) -> StandardMaterial3D:
	var key := "glow|%s|%s|%s" % [color, energy, unshaded]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mats[key] = m
	return m


static func glass(color := Color(0.5, 0.6, 0.65, 0.25)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.1
	m.metallic = 0.3
	return m


# ------------------------------------------------------------------ primitives
static func _body(parent: Node3D, shape: Shape3D, xf: Transform3D, surface: String, layer := LAYER_WORLD) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.collision_layer = layer
	sb.collision_mask = 0
	if surface != "":
		sb.set_meta("surface", surface)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	sb.add_child(cs)
	parent.add_child(sb)
	sb.transform = xf
	return sb


static func box(parent: Node3D, pos: Vector3, size: Vector3, material: Material, opts := {}) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = material
	parent.add_child(mi)
	mi.position = pos
	if opts.has("rot"):
		mi.rotation_degrees = opts.rot
	if opts.get("shadow", true) == false:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if opts.get("collide", true):
		var sh := BoxShape3D.new()
		sh.size = size
		_body(mi, sh, Transform3D.IDENTITY, opts.get("surface", ""), opts.get("layer", LAYER_WORLD))
	return mi


static func cyl(parent: Node3D, pos: Vector3, radius: float, height: float, material: Material, opts := {}) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = opts.get("top", radius)
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = opts.get("segments", 12)
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = material
	parent.add_child(mi)
	mi.position = pos
	if opts.has("rot"):
		mi.rotation_degrees = opts.rot
	if opts.get("collide", true):
		var sh := CylinderShape3D.new()
		sh.radius = max(radius, opts.get("top", radius))
		sh.height = height
		_body(mi, sh, Transform3D.IDENTITY, opts.get("surface", ""))
	return mi


static func sphere(parent: Node3D, pos: Vector3, radius: float, material: Material, opts := {}) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = opts.get("height", radius * 2.0)
	sm.radial_segments = 12
	sm.rings = 6
	mi.mesh = sm
	mi.material_override = material
	parent.add_child(mi)
	mi.position = pos
	return mi


## Invisible collision-only box (blockers, ramps).
static func collider(parent: Node3D, pos: Vector3, size: Vector3, rot := Vector3.ZERO, surface := "") -> StaticBody3D:
	var sh := BoxShape3D.new()
	sh.size = size
	var xf := Transform3D(Basis.from_euler(rot * PI / 180.0), pos)
	return _body(parent, sh, xf, surface)


## Stairs from `a` (bottom, centre of first step) to `b` (top landing edge).
## Visual steps plus one smooth ramp collider so the controller never snags.
static func stairs(parent: Node3D, a: Vector3, b: Vector3, width: float, material: Material, surface := "wood") -> void:
	var flat_d := Vector3(b.x - a.x, 0, b.z - a.z)
	var length := flat_d.length()
	var rise := b.y - a.y
	var dir := flat_d.normalized()
	var steps := int(max(2, round(rise / 0.2)))
	var yaw := atan2(dir.x, dir.z)
	var basis := Basis(Vector3.UP, yaw)
	for i in steps:
		var t := (i + 0.5) / steps
		var h := rise * (i + 1) / steps
		var p := a + dir * length * t
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(width, h, length / steps + 0.02)
		mi.mesh = bm
		mi.material_override = material
		parent.add_child(mi)
		mi.transform = Transform3D(basis, Vector3(p.x, a.y + h * 0.5, p.z))
	var slope_len := sqrt(length * length + rise * rise)
	var pitch := atan2(rise, length)
	var mid := (a + b) * 0.5
	var sh := BoxShape3D.new()
	sh.size = Vector3(width, 0.2, slope_len)
	var rb := basis * Basis(Vector3.RIGHT, -pitch)
	var xf := Transform3D(rb, mid + rb.y * -0.1)
	_body(parent, sh, xf, surface)


static func omni(parent: Node3D, pos: Vector3, color: Color, energy := 1.0, rng := 6.0, shadow := false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	l.omni_attenuation = 1.4
	l.shadow_enabled = shadow
	l.light_specular = 0.4
	parent.add_child(l)
	l.position = pos
	return l


static func spot(parent: Node3D, pos: Vector3, color: Color, energy := 2.0, rng := 12.0, angle := 35.0, rot := Vector3(-90, 0, 0), shadow := false) -> SpotLight3D:
	var l := SpotLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.spot_range = rng
	l.spot_angle = angle
	l.shadow_enabled = shadow
	parent.add_child(l)
	l.position = pos
	l.rotation_degrees = rot
	return l


static func label(parent: Node3D, pos: Vector3, text: String, size := 32, color := Color(0.85, 0.82, 0.74), rot := Vector3.ZERO) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = load("res://assets/fonts/SpecialElite-Regular.ttf")
	l.font_size = size
	l.pixel_size = 0.004
	l.modulate = color
	l.outline_size = 0
	l.shaded = true
	l.double_sided = false
	parent.add_child(l)
	l.position = pos
	l.rotation_degrees = rot
	return l


# ------------------------------------------------------------------ rocks
static func rock_mesh(variant: int) -> ArrayMesh:
	if _rock_meshes.is_empty():
		for v in 5:
			_rock_meshes.append(_make_rock(v))
	return _rock_meshes[variant % _rock_meshes.size()]


static func _make_rock(seed: int) -> ArrayMesh:
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 14
	sm.rings = 9
	var arrays := sm.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var n := FastNoiseLite.new()
	n.seed = 100 + seed
	n.frequency = 0.9
	n.fractal_octaves = 3
	var squash := Vector3(1.0 + 0.3 * sin(seed * 1.7), 0.7 + 0.2 * cos(seed * 2.3), 1.0 + 0.25 * cos(seed))
	for i in verts.size():
		var v := verts[i]
		var d := 1.0 + n.get_noise_3dv(v * 1.3) * 0.45
		# flatten facets a little for a chiselled, low-poly read
		v = (v * d) * squash
		v.y = max(v.y, -0.55)
		verts[i] = v
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for i in idx:
		st.add_vertex(verts[i])
	st.generate_normals()
	return st.commit()


static func rock(parent: Node3D, pos: Vector3, scale: Vector3, variant: int, material: Material, collide := true, yaw := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = rock_mesh(variant)
	mi.material_override = material
	parent.add_child(mi)
	mi.position = pos
	mi.rotation = Vector3(0.15 * sin(variant * 3.1), yaw, 0.12 * cos(variant * 1.3))
	mi.scale = scale
	if collide:
		var sb := StaticBody3D.new()
		sb.collision_layer = LAYER_WORLD
		sb.collision_mask = 0
		sb.set_meta("surface", "stone")
		var cs := CollisionShape3D.new()
		var key := variant % 5
		if not _rock_shapes.has(key):
			_rock_shapes[key] = mi.mesh.create_convex_shape(true, false)
		cs.shape = _rock_shapes[key]
		sb.add_child(cs)
		mi.add_child(sb)
	return mi


# ------------------------------------------------------------------ rooms
## Builds a rectangular room centred on `origin` (floor level). `size` is the
## interior (width x, height y, depth z). Openings: {side:"n|s|e|w", at: offset
## along the wall from its centre, w: width, h: height, sill: bottom height}.
static func room(parent: Node3D, origin: Vector3, size: Vector3, opts := {}) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	root.position = origin
	if opts.has("yaw"):
		root.rotation_degrees.y = opts.yaw
	var t: float = opts.get("thick", 0.2)
	var wall_m: Material = opts.get("wall", mat("plaster_white"))
	var outer_m: Material = opts.get("outer", wall_m)
	var floor_m: Material = opts.get("floor", mat("wood_planks"))
	var ceil_m: Material = opts.get("ceiling", mat("wood_dark"))
	var surface: String = opts.get("surface", "wood")
	# floor slab (thick so the terrain never pokes through)
	box(root, Vector3(0, -0.25, 0), Vector3(size.x + t * 2, 0.5, size.z + t * 2), floor_m, {"surface": surface})
	if opts.get("ceiling_on", true):
		box(root, Vector3(0, size.y + 0.1, 0), Vector3(size.x + t * 2, 0.2, size.z + t * 2), ceil_m, {"shadow": true})
	var openings: Array = opts.get("openings", [])
	var sides := {
		"n": [Vector3(0, 0, -size.z * 0.5 - t * 0.5), size.x + t * 2, false],
		"s": [Vector3(0, 0, size.z * 0.5 + t * 0.5), size.x + t * 2, false],
		"e": [Vector3(size.x * 0.5 + t * 0.5, 0, 0), size.z, true],
		"w": [Vector3(-size.x * 0.5 - t * 0.5, 0, 0), size.z, true],
	}
	for side in sides:
		if side in opts.get("skip", []):
			continue
		var c: Vector3 = sides[side][0]
		var length: float = sides[side][1]
		var along_z: bool = sides[side][2]
		var ops := []
		for o in openings:
			if o.side == side:
				ops.append(o)
		ops.sort_custom(func(x, y): return x.at < y.at)
		var cursor := -length * 0.5
		var segs := []  # [from, to, bottom, top]
		for o in ops:
			var a: float = o.at - o.w * 0.5
			var b2: float = o.at + o.w * 0.5
			if a > cursor:
				segs.append([cursor, a, 0.0, size.y])
			var sill: float = o.get("sill", 0.0)
			var top: float = sill + o.h
			if sill > 0.0:
				segs.append([a, b2, 0.0, sill])
			if top < size.y:
				segs.append([a, b2, top, size.y])
			cursor = b2
		if cursor < length * 0.5:
			segs.append([cursor, length * 0.5, 0.0, size.y])
		for s in segs:
			var mid: float = (s[0] + s[1]) * 0.5
			var w: float = s[1] - s[0]
			var h: float = s[3] - s[2]
			if w <= 0.01 or h <= 0.01:
				continue
			var p := c + (Vector3(0, 0, mid) if along_z else Vector3(mid, 0, 0))
			p.y = s[2] + h * 0.5
			var sz := Vector3(t, h, w) if along_z else Vector3(w, h, t)
			box(root, p, sz, wall_m, {"surface": surface})
			if outer_m != wall_m:
				# thin outer skin so exteriors can use a different material
				var normal := Vector3(signf(c.x), 0, signf(c.z))
				var skin := Vector3(0.04, h, w + (0.0 if along_z else 0.08)) if along_z else Vector3(w + 0.08, h, 0.04)
				box(root, p + normal * (t * 0.5 + 0.02), skin, outer_m, {"collide": false})
	if opts.get("roof", false):
		gable_roof(root, size, t, opts.get("roof_mat", mat("roof", Color.WHITE, 0.5)), opts.get("gable_mat", outer_m))
	return root


static func gable_roof(root: Node3D, size: Vector3, t: float, roof_m: Material, gable_m: Material) -> void:
	var w := size.x + t * 2 + 0.6
	var d := size.z + t * 2 + 0.6
	var rise := w * 0.32
	var slope_len := sqrt((w * 0.5) * (w * 0.5) + rise * rise)
	var ang := rad_to_deg(atan2(rise, w * 0.5))
	var y0 := size.y + 0.2
	for sgn in [-1, 1]:
		var mi := box(root, Vector3(sgn * w * 0.25, y0 + rise * 0.5, 0), Vector3(slope_len, 0.15, d), roof_m, {"collide": false})
		mi.rotation_degrees.z = -sgn * ang
	# gable triangles (approximated by stacked boxes)
	for zs in [-1, 1]:
		for i in 5:
			var hh := rise / 5.0
			var ww := (size.x + t * 2) * (1.0 - (i + 0.5) / 5.0)
			box(root, Vector3(0, y0 + hh * (i + 0.5), zs * (size.z * 0.5 + t * 0.5)), Vector3(ww, hh, t), gable_m, {"collide": false})


## Glowing window pane (for "lit windows" with no power) and frame.
static func window_glow(parent: Node3D, pos: Vector3, size: Vector2, yaw: float, color := Color(1.0, 0.62, 0.3), energy := 1.6) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = size
	mi.mesh = qm
	mi.material_override = glow(color, energy)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.position = pos
	mi.rotation_degrees.y = yaw
	return mi


static func ring_mark(parent: Node3D, pos: Vector3, yaw: float) -> void:
	## The researchers' white ring painted on safe-room doors.
	var tm := TorusMesh.new()
	tm.inner_radius = 0.22
	tm.outer_radius = 0.28
	tm.rings = 24
	tm.ring_segments = 6
	var mi := MeshInstance3D.new()
	mi.mesh = tm
	mi.material_override = glow(Color(0.85, 0.88, 0.85), 0.35)
	parent.add_child(mi)
	mi.position = pos
	mi.rotation_degrees = Vector3(90, yaw, 0)
	mi.scale = Vector3(1, 0.2, 1)
