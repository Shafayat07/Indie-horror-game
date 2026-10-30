extends Node3D
## Lived-in detail and atmosphere for every location, added in one place:
## ground fog and dust that follow the player, the foghorn out at sea, cave
## drips, and small clutter that makes each place feel recently abandoned.

var level: Node
var _fog: GPUParticles3D
var _dust: GPUParticles3D
var _horn_t := 40.0


func setup(lv: Node) -> void:
	level = lv
	_fog = _particles(160, 9.0, Vector3(22, 0.4, 22), Vector2(4.0, 1.4), Color(0.6, 0.66, 0.7, 0.05), Vector3(0.25, 0.0, 0.1), 0.15)
	_dust = _particles(120, 6.0, Vector3(4, 1.5, 4), Vector2(0.02, 0.02), Color(0.9, 0.85, 0.7, 0.5), Vector3(0, -0.02, 0), 0.03)
	_dock()
	_settlement()
	_station()
	_lighthouse()
	_chamber()
	_caves()
	_forest()
	_graveyard()


func _particles(amount: int, life: float, box: Vector3, size: Vector2, col: Color, dir: Vector3, vel: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.visibility_aabb = AABB(-box * 1.5 - Vector3(0, 4, 0), box * 3.0 + Vector3(0, 8, 0))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = box
	pm.direction = dir.normalized() if dir.length() > 0 else Vector3.UP
	pm.spread = 40.0
	pm.initial_velocity_min = vel * 0.5
	pm.initial_velocity_max = vel
	pm.gravity = Vector3.ZERO
	p.process_material = pm
	var qm := QuadMesh.new()
	qm.size = size
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if size.x > 1.0 else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = col
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	if size.x > 1.0:
		var g := GradientTexture2D.new()
		g.fill = GradientTexture2D.FILL_RADIAL
		g.fill_from = Vector2(0.5, 0.5)
		g.fill_to = Vector2(1.0, 0.5)
		var grad := Gradient.new()
		grad.set_color(0, Color(1, 1, 1, 1))
		grad.set_color(1, Color(1, 1, 1, 0))
		g.gradient = grad
		m.albedo_texture = g
	qm.material = m
	p.draw_pass_1 = qm
	add_child(p)
	return p


func _process(delta: float) -> void:
	if level == null or level.player == null:
		return
	var pp: Vector3 = level.player.global_position
	_fog.global_position = pp + Vector3(0, 0.3, 0)
	_fog.emitting = level.space == "surface"
	_dust.global_position = pp + Vector3(0, 1.4, 0)
	_horn_t -= delta
	if _horn_t <= 0.0:
		_horn_t = randf_range(70.0, 130.0)
		if level.space == "surface" and not Game.has_flag("chose_break"):
			Sound.play_at("foghorn", Vector3(-40, 5, 260), -2.0, {"unit_size": 120.0, "max_distance": 600.0})


func _g(x: float, z: float) -> float:
	return Terrain.height(x, z)


func _lantern(pos: Vector3, energy := 0.8) -> void:
	B.cyl(self, pos, 0.1, 0.25, B.glow(Color(1.0, 0.65, 0.3), 2.5), {"collide": false})
	var l := B.omni(self, pos, Color(1.0, 0.62, 0.3), energy, 5.0)
	l.set_script(preload("res://scripts/world/flicker.gd"))


func _dock() -> void:
	for i in 5:
		P.crate(self, Vector3(-0.9, 1.5, 102.0 + i * 0.9), randf() * 20.0, 0.5)
	for z in [88.0, 104.0]:
		_lantern(Vector3(1.3, 2.3, z), 0.5)
	var rope := B.mat("rope", Color.WHITE, 2.0)
	for z in [92.0, 110.0]:
		var coil := B.cyl(self, Vector3(0.9, 1.55, z), 0.35, 0.12, rope, {"collide": false})
	# gull bones: the birds left the island
	for i in 6:
		B.box(self, Vector3(randf_range(-1, 1), 1.52, randf_range(84, 96)), Vector3(0.03, 0.02, randf_range(0.1, 0.25)), B.flat(Color(0.82, 0.8, 0.72)), {"collide": false}).rotation.y = randf() * TAU
	P.barrel(self, Vector3(4, _g(4, 77), 77), Color(0.3, 0.35, 0.3))
	P.net_pile(self, Vector3(-4, _g(-4, 76), 76))


func _settlement() -> void:
	# a child's ball and bucket by the blue house, firewood, a creaking sign, a wind chime
	B.sphere(self, Vector3(4.5, _g(4.5, 43) + 0.15, 43), 0.15, B.flat(Color(0.6, 0.12, 0.1), 0.6))
	B.cyl(self, Vector3(5.2, _g(5.2, 44) + 0.12, 44), 0.12, 0.24, B.mat("metal_red", Color.WHITE, 2.0), {"collide": false})
	for i in 8:
		B.cyl(self, Vector3(-13.2, _g(-13, 52) + 0.12 + (i / 4) * 0.22, 51 + (i % 4) * 0.25), 0.11, 1.0, B.mat("bark", Color.WHITE, 1.0), {"collide": i == 0, "rot": Vector3(0, 0, 90)})
	var sign := Node3D.new()
	add_child(sign)
	sign.position = Vector3(-5.9, _g(-6, 48) + 2.6, 48.8)
	B.box(sign, Vector3(0, -0.3, 0), Vector3(0.05, 0.4, 0.8), B.mat("wood_painted", Color.WHITE, 1.0), {"collide": false})
	B.label(sign, Vector3(0.04, -0.3, 0), "TEA", 30, Color(0.2, 0.15, 0.1), Vector3(0, 90, 0))
	var tw := create_tween().set_loops()
	tw.tween_property(sign, "rotation_degrees:x", 8.0, 1.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(sign, "rotation_degrees:x", -6.0, 1.8).set_trans(Tween.TRANS_SINE)
	var chime := Node3D.new()
	add_child(chime)
	chime.position = Vector3(-5.9, _g(-6, 47) + 2.4, 46.5)
	for i in 4:
		B.cyl(chime, Vector3(i * 0.06, -0.3 - i * 0.05, 0), 0.01, 0.4 + i * 0.1, B.flat(Color(0.6, 0.6, 0.55), 0.3, 0.8), {"collide": false})
	var t := Timer.new()
	t.wait_time = 6.0
	t.autostart = true
	chime.add_child(t)
	t.timeout.connect(func(): Sound.play_at("bell_drowned", chime.global_position, -26.0, {"pitch": 3.5, "unit_size": 2.0}))
	# candles in the windows that should be dark
	for pos in [Vector3(-12, 5.7, 47.5), Vector3(-6.4, 5.7, 32.6), Vector3(12.1, 5.7, 40.5)]:
		_lantern(pos, 0.25)


func _station() -> void:
	var o: Vector3 = level.areas.station.ORIGIN
	for i in 10:
		P.paper(self, o + Vector3(randf_range(1.5, 6.5), 0.01, randf_range(-3, 3.5)), randf() * 360.0)
	P.chair(self, o + Vector3(5.5, 0, 1.5), 75).rotation_degrees.z = 85
	P.crate(self, o + Vector3(-6.4, 0, -3.2), 10)


func _lighthouse() -> void:
	var c: Vector3 = level.areas.lighthouse.C
	P.crate(self, c + Vector3(-2.0, 6.0, -2.6), 15, 0.6)
	for i in 6:
		B.box(self, c + Vector3(1.5 + i * 0.22, 6.08, 2.6), Vector3(0.18, 0.06, 0.26), B.flat(Color(randf_range(0.2, 0.4), 0.15, 0.1), 0.8), {"collide": false})
	_lantern(c + Vector3(-2.6, 12.9, 1.5), 0.6)


func _chamber() -> void:
	var o: Vector3 = level.CHAMBER_ORIGIN
	for i in 3:
		B.cyl(self, o + Vector3(-8 + i * 7, 0.45, 9.5), 0.45, 0.6, B.mat("wood_dark", Color.WHITE, 1.0), {"rot": Vector3(90, 0, 0)})
	for i in 8:
		P.paper(self, o + Vector3(randf_range(-6, 6), 0.01, randf_range(6, 11)), randf() * 360.0)


func _caves() -> void:
	var caves = level.areas.caves
	for spot in [Vector2(-2, -20), Vector2(3, -26), Vector2(-14, -30), Vector2(0, -55), Vector2(-1, -64)]:
		var p := _particles(6, 1.2, Vector3(0.6, 0.1, 0.6), Vector2(0.02, 0.06), Color(0.7, 0.8, 0.85, 0.7), Vector3(0, -1, 0), 4.0)
		p.global_position = caves._p(spot.x, spot.y, caves._ceil(spot.x, spot.y) - caves.floor_h(spot.x, spot.y) - 0.3)


func _forest() -> void:
	# a dead campfire and an abandoned rucksack: someone else came looking for Kell
	var c := Vector3(-46, 0, 44)
	var g := _g(c.x, c.z)
	for i in 6:
		var a := TAU * i / 6.0
		B.rock(self, Vector3(c.x + cos(a) * 0.6, g, c.z + sin(a) * 0.6), Vector3.ONE * 0.18, i, B.mat("stone_wet", Color.WHITE, 1.0), false)
	B.box(self, Vector3(c.x, g + 0.04, c.z), Vector3(0.7, 0.05, 0.7), B.flat(Color(0.02, 0.02, 0.02), 0.9), {"collide": false})
	var sack := B.sphere(self, Vector3(c.x + 1.4, g + 0.25, c.z + 0.6), 0.3, B.flat(Color(0.2, 0.22, 0.15), 0.9))
	sack.scale = Vector3(1.0, 1.4, 0.7)
	for i in 4:
		B.cyl(self, Vector3(-40 - i * 7, _g(-40 - i * 7, 56) + 0.2, 56 + (i % 2) * 6), 0.25, 3.0, B.mat("bark", Color.WHITE, 1.0), {"rot": Vector3(0, i * 40, 90)})


func _graveyard() -> void:
	var c := Vector3(-98, 0, 46)
	for i in 8:
		var x := c.x + randf_range(-12, 12)
		var z := c.z + randf_range(-16, 16)
		B.cyl(self, Vector3(x, _g(x, z) + 0.15, z), 0.12, randf_range(1.5, 3.0), B.mat("wood_dark", Color(0.7, 0.7, 0.7), 1.0), {"collide": false, "rot": Vector3(0, randf() * 180, 90)})
	for i in 3:
		P.net_pile(self, Vector3(c.x + 6 + i * 2, _g(c.x + 6, c.z - 8), c.z - 8 + i))
