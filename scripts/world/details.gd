extends Node3D
## Environmental detail and authored scares layered over the existing areas.
## Props here are small and mostly non-colliding, so routes, puzzles and
## navigation stay exactly as they were. Every scare plays once, only when the
## player is calm (no reading, no hunt, a quiet gap since the last scare).

var level: Node
var _last_scare := -999.0
var _watch := []          # [node, callable] checks run each frame until they return true

const QUIET_GAP := 35.0


func setup(lv: Node) -> void:
	level = lv
	_dock()
	_settlement()
	_station()
	_forest()
	_graveyard()
	_lowvey()
	_caves()
	_annex()
	_lighthouse()


func _process(_delta: float) -> void:
	for i in range(_watch.size() - 1, -1, -1):
		if (_watch[i] as Callable).call():
			_watch.remove_at(i)


## A scare may play now: the player is free, nothing is hunting, and it's been quiet a while.
func _calm() -> bool:
	var p: Node = level.player
	var now := Time.get_ticks_msec() / 1000.0
	return now - _last_scare > QUIET_GAP and not p.dead and p.input_enabled and not level.hud.reading \
		and not level.listener.is_active() and not get_tree().paused


func _scared() -> void:
	_last_scare = Time.get_ticks_msec() / 1000.0


func _near(pos: Vector3, r: float) -> bool:
	return level.player.global_position.distance_to(pos) < r


func _g(x: float, z: float) -> float:
	return Terrain.height(x, z)


# ------------------------------------------------------------------ small props
func _anchor(pos: Vector3, yaw: float, tilt := 70.0) -> void:
	var r := Node3D.new()
	add_child(r)
	r.position = pos
	r.rotation_degrees = Vector3(tilt, yaw, 0)
	var iron := B.mat("metal_rust", Color(0.55, 0.45, 0.4), 1.6, {"metallic": 0.4})
	B.cyl(r, Vector3(0, 0.75, 0), 0.07, 1.5, iron, {"collide": false})
	B.box(r, Vector3(0, 0.08, 0), Vector3(1.1, 0.12, 0.12), iron, {"collide": false})
	for sx in [-1, 1]:
		B.box(r, Vector3(sx * 0.52, 0.25, 0), Vector3(0.1, 0.4, 0.12), iron, {"collide": false}).rotation_degrees.z = sx * -25
	B.box(r, Vector3(0, 1.4, 0), Vector3(0.6, 0.08, 0.08), iron, {"collide": false})


func _ring(pos: Vector3, yaw: float) -> void:
	var t := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.22
	tm.outer_radius = 0.34
	t.mesh = tm
	t.material_override = B.flat(Color(0.62, 0.16, 0.1), 0.7)
	add_child(t)
	t.position = pos
	t.rotation_degrees = Vector3(90, yaw, 0)


func _coil(pos: Vector3) -> Node3D:
	var r := Node3D.new()
	add_child(r)
	r.position = pos
	var rope := B.mat("rope", Color(0.75, 0.7, 0.6), 2.5)
	for i in 4:
		var t := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.18 - i * 0.02
		tm.outer_radius = 0.26 - i * 0.02
		t.mesh = tm
		t.material_override = rope
		r.add_child(t)
		t.position = Vector3(0, 0.04 + i * 0.06, 0)
	return r


func _bucket(pos: Vector3, fallen := false) -> void:
	var b := B.cyl(self, pos + Vector3(0, 0.18, 0), 0.16, 0.36, B.mat("metal_rust", Color(0.7, 0.7, 0.7), 2.0, {"metallic": 0.4}), {"collide": false, "top": 0.2})
	if fallen:
		b.rotation_degrees = Vector3(90, randf() * 360.0, 0)
		b.position.y = pos.y + 0.16


func _fish_crate(pos: Vector3, yaw: float) -> void:
	var r := Node3D.new()
	add_child(r)
	r.position = pos
	r.rotation_degrees.y = yaw
	var w := B.mat("wood_planks", Color(0.8, 0.75, 0.65), 1.4)
	for i in 3:
		B.box(r, Vector3(0, 0.06 + i * 0.1, 0.3), Vector3(0.8, 0.06, 0.03), w, {"collide": false})
		B.box(r, Vector3(0, 0.06 + i * 0.1, -0.3), Vector3(0.8, 0.06, 0.03), w, {"collide": false})
	for sx in [-1, 1]:
		B.box(r, Vector3(sx * 0.39, 0.15, 0), Vector3(0.03, 0.3, 0.6), w, {"collide": false})
	B.box(r, Vector3(0, 0.02, 0), Vector3(0.78, 0.03, 0.6), w, {"collide": false})


func _puddle(x: float, z: float, r: float, y := INF) -> void:
	var h: float = _g(x, z) if y == INF else y
	B.cyl(self, Vector3(x, h + 0.012, z), r, 0.01, _water(), {"collide": false, "segments": 18}).scale = Vector3(1.0, 1.0, randf_range(0.5, 0.9))


static var _water_m: StandardMaterial3D


## Standing water: a thin, glossy, half-transparent skin that picks up lamps and the sky.
func _water() -> StandardMaterial3D:
	if _water_m == null:
		_water_m = StandardMaterial3D.new()
		_water_m.albedo_color = Color(0.05, 0.065, 0.075, 0.55)
		_water_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_water_m.roughness = 0.03
		_water_m.metallic = 0.4
		_water_m.metallic_specular = 0.9
	return _water_m


func _sign(pos: Vector3, yaw: float, text: String) -> void:
	var r := Node3D.new()
	add_child(r)
	r.position = pos
	r.rotation_degrees.y = yaw
	B.box(r, Vector3(0, 0, 0), Vector3(1.4, 0.5, 0.05), B.mat("wood_painted", Color(0.7, 0.72, 0.7), 1.0), {"collide": false})
	B.label(r, Vector3(0, 0, 0.03), text, 22, Color(0.12, 0.1, 0.09))


func _log(pos: Vector3, yaw: float, length: float, radius: float) -> void:
	var l := B.cyl(self, pos + Vector3(0, radius * 0.8, 0), radius, length, B.mat("bark", Color(0.8, 0.8, 0.75), 0.6), {"collide": false})
	l.rotation_degrees = Vector3(90, yaw, randf_range(-5, 5))


func _bulb(parent: Node3D, pos: Vector3, energy := 0.6) -> void:
	## A bare bulb on a flex, swinging a little, throwing its light about.
	var pivot := Node3D.new()
	parent.add_child(pivot)
	pivot.position = pos
	B.box(pivot, Vector3(0, -0.3, 0), Vector3(0.01, 0.6, 0.01), B.flat(Color(0.05, 0.05, 0.05)), {"collide": false})
	B.sphere(pivot, Vector3(0, -0.64, 0), 0.05, B.glow(Color(1.0, 0.78, 0.5), 3.0))
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.75, 0.45)
	l.light_energy = energy
	l.omni_range = 6.0
	l.shadow_enabled = true
	pivot.add_child(l)
	l.position = Vector3(0, -0.7, 0)
	var tw := pivot.create_tween().set_loops()
	tw.tween_property(pivot, "rotation_degrees:z", 9.0, 1.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(pivot, "rotation_degrees:z", -9.0, 1.6).set_trans(Tween.TRANS_SINE)


func _curtain(parent: Node3D, pos: Vector3, yaw: float) -> void:
	var c := B.box(parent, pos, Vector3(0.45, 1.0, 0.02), B.flat(Color(0.5, 0.38, 0.3), 0.9), {"collide": false})
	c.rotation_degrees.y = yaw
	var tw := c.create_tween().set_loops()
	var d := randf_range(2.5, 4.0)
	tw.tween_property(c, "rotation_degrees:x", 6.0, d).set_trans(Tween.TRANS_SINE)
	tw.tween_property(c, "rotation_degrees:x", -2.0, d).set_trans(Tween.TRANS_SINE)


func _bob(n: Node3D, amp := 0.08, period := 3.0) -> void:
	var y := n.position.y
	var tw := n.create_tween().set_loops()
	tw.tween_property(n, "position:y", y + amp, period * 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(n, "position:y", y - amp, period * 0.5).set_trans(Tween.TRANS_SINE)


## Strips collision from a decorative prop (things overhead, things in the way of nothing).
func _no_collide(n: Node) -> void:
	for c in n.find_children("*", "CollisionObject3D", true, false):
		c.queue_free()


## A haunted spot: nothing to see from afar; come close and something is in your face.
func _distant_figure(pos: Vector3, _yaw: float, vanish_at: float, require := "") -> void:
	_watch.append(func() -> bool:
		if require != "" and not Game.has_flag(require):
			return false
		if _near(pos, vanish_at + 2.0) and _calm():
			_scared()
			level.horror.face_scare(2)
			return true
		return false)


# ------------------------------------------------------------------ the dock
func _dock() -> void:
	var dy := 1.5
	_anchor(Vector3(3.2, _g(3.2, 77.5) + 0.05, 77.5), 30.0)
	_ring(Vector3(6.0, _g(6.0, 74.4) + 1.6, 73.75), 0.0)
	_coil(Vector3(0.9, dy, 103.5))
	_coil(Vector3(-0.9, dy, 86.0))
	_bucket(Vector3(-1.0, dy, 99.5), true)
	_bucket(Vector3(1.1, dy, 91.0))
	_fish_crate(Vector3(-0.9, dy, 95.0), 10.0)
	_fish_crate(Vector3(1.0, dy, 107.0), -20.0)
	_sign(Vector3(-1.5, dy + 1.3, 82.0), 90.0, "VEY HARBOUR\nNO MOORING AFTER DARK")
	_puddle(0.3, 97.0, 0.5, dy)
	_puddle(-0.5, 88.0, 0.4, dy)
	# weed and barnacles where the posts meet the sea
	var weed := B.flat(Color(0.05, 0.09, 0.05), 0.35)
	for z in range(82, 112, 4):
		for x in [-1.45, 1.45]:
			B.box(self, Vector3(x, -0.25, z), Vector3(0.3, 0.6, 0.3), weed, {"collide": false})
	# drifting debris and a loose buoy
	for spec in [[Vector3(4.5, -0.05, 96), 30.0], [Vector3(-4.0, -0.05, 103), -60.0], [Vector3(-3.0, -0.05, 89), 80.0]]:
		var plank := B.box(self, spec[0], Vector3(1.6, 0.08, 0.25), B.mat("wood_planks", Color(0.6, 0.55, 0.5), 1.2), {"collide": false})
		plank.rotation_degrees.y = spec[1]
		_bob(plank, 0.05, randf_range(2.5, 4.0))
	var buoy := P.buoy(self, Vector3(-5.5, -0.2, 110), 35.0)
	_bob(buoy, 0.12, 3.4)
	# the rope coil that is somewhere else when you come back
	var coil := _coil(Vector3(0.6, dy, 96.0))
	_watch.append(func() -> bool:
		if Game.has_flag("has_station_key") and not _near(coil.global_position, 30.0):
			coil.position = Vector3(-0.7, dy, 92.0)
			return true
		return false)
	# something knocks on the underside of the boards, under your feet
	_watch.append(func() -> bool:
		var p: Vector3 = level.player.global_position
		if Game.has_flag("has_recorder") and p.z > 92 and p.z < 104 and abs(p.x) < 1.5 and _calm():
			_scared()
			for i in 3:
				get_tree().create_timer(0.5 * i).timeout.connect(func():
					Sound.play_at("knock3", level.player.global_position + Vector3(0, -1.2, 0), -2.0, {"unit_size": 3.0}))
			level.player.shake(0.25)
			return true
		return false)
	# on the way back: a light inside the empty boat, out when you get close
	var boat_light := OmniLight3D.new()
	boat_light.light_color = Color(1.0, 0.7, 0.4)
	boat_light.light_energy = 0.0
	boat_light.omni_range = 5.0
	add_child(boat_light)
	boat_light.position = Vector3(5.5, dy + 1.6, 108.5)
	_watch.append(func() -> bool:
		if not Game.has_flag("reached_station"):
			return false
		var d: float = level.player.global_position.distance_to(boat_light.global_position)
		if d < 40.0 and d > 14.0 and boat_light.light_energy == 0.0:
			boat_light.light_energy = 1.2
		elif d <= 14.0 and boat_light.light_energy > 0.0:
			boat_light.light_energy = 0.0
			Sound.play_at("door_creak_1", boat_light.global_position, -6.0)
			return true
		return false)
	# a wet figure standing in the shallows past the end of the pier, on your return
	_distant_figure(Vector3(-0.5, 1.5, 113.0), PI, 4.0, "has_station_key")


## A wooden fingerpost; each board points toward its place.
func _fingerpost(x: float, z: float, places: Array) -> void:
	var base := Vector3(x, _g(x, z), z)
	var wood := B.mat("wood_dark", Color(0.85, 0.78, 0.7), 1.0)
	B.box(self, base + Vector3(0, 1.35, 0), Vector3(0.14, 2.7, 0.14), wood, {})
	for i in places.size():
		var to: Vector3 = places[i][1]
		var arm := Node3D.new()
		add_child(arm)
		arm.position = base + Vector3(0, 2.35 - i * 0.36, 0)
		arm.rotation.y = atan2(-(to.z - z), to.x - x)
		var board := B.mat("wood_painted", Color(0.85, 0.82, 0.74), 1.0)
		B.box(arm, Vector3(0.75, 0, 0), Vector3(1.3, 0.26, 0.05), board, {"collide": false})
		B.box(arm, Vector3(1.45, 0, 0), Vector3(0.18, 0.18, 0.05), board, {"collide": false}).rotation_degrees.z = 45
		for side in [1, -1]:
			B.label(arm, Vector3(0.72, 0, 0.03 * side), places[i][0], 15, Color(0.1, 0.09, 0.08), Vector3(0, 0 if side > 0 else 180, 0))


# ------------------------------------------------------------------ the settlement
func _settlement() -> void:
	_fingerpost(4.4, 60.5, [["HARBOUR", Vector3(0, 0, 95)], ["LIGHTHOUSE", Vector3(0, 0, -82)], ["WEATHER STATION", Vector3(-60, 0, -10)]])
	_fingerpost(-4.7, 49.5, [["BLACKWOOD", Vector3(-57, 0, 33)], ["SHIP GRAVEYARD", Vector3(-98, 0, 46)], ["THE SQUARE", Vector3(-4, 0, 26)]])
	for spec in [[0.4, 30.0, 1.1], [-0.8, 38.0, 0.7], [1.0, 45.0, 1.4], [-0.5, 53.0, 0.9], [-3.5, 27.5, 1.2], [2.0, 58.0, 0.8]]:
		_puddle(spec[0], spec[1], spec[2])
	# a bicycle against the teahouse, a handcart by the square, a lamp that died
	var bike := Node3D.new()
	add_child(bike)
	bike.position = Vector3(-5.6, _g(-5.6, 46.0), 46.0)
	bike.rotation_degrees = Vector3(0, 90, 12)
	var iron := B.mat("metal_rust", Color(0.5, 0.45, 0.42), 2.0, {"metallic": 0.5})
	for z in [-0.5, 0.5]:
		var w := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.3
		tm.outer_radius = 0.34
		w.mesh = tm
		w.material_override = iron
		bike.add_child(w)
		w.position = Vector3(0, 0.34, z)
		w.rotation_degrees = Vector3(0, 0, 90)
	B.box(bike, Vector3(0, 0.55, 0), Vector3(0.04, 0.04, 0.9), iron, {"collide": false})
	B.box(bike, Vector3(0, 0.75, 0.3), Vector3(0.04, 0.4, 0.04), iron, {"collide": false})
	B.box(bike, Vector3(0, 0.95, 0.45), Vector3(0.5, 0.04, 0.04), iron, {"collide": false})
	var cart := Node3D.new()
	add_child(cart)
	cart.position = Vector3(-8.0, _g(-8.0, 25.0), 25.0)
	cart.rotation_degrees = Vector3(-14, 30, 0)
	var wood := B.mat("wood_planks", Color(0.7, 0.65, 0.55), 1.0)
	B.box(cart, Vector3(0, 0.6, 0), Vector3(1.0, 0.35, 1.5), wood, {})
	for sx in [-1, 1]:
		B.cyl(cart, Vector3(sx * 0.55, 0.35, 0.1), 0.35, 0.06, wood, {"collide": false, "rot": Vector3(0, 0, 90)})
		B.box(cart, Vector3(sx * 0.35, 0.65, -1.2), Vector3(0.06, 0.06, 1.0), wood, {"collide": false})
	var lp := B.cyl(self, Vector3(3.6, _g(3.6, 49.0) + 1.5, 49.0), 0.07, 3.0, iron, {})
	lp.rotation_degrees.z = -14
	# a child's shoe in the lane; a photograph lying face-down outside the blue house
	B.box(self, Vector3(1.2, _g(1.2, 41.5) + 0.05, 41.5), Vector3(0.09, 0.08, 0.18), B.flat(Color(0.35, 0.12, 0.1), 0.6), {"collide": false}).rotation_degrees.y = 35
	B.box(self, Vector3(5.2, _g(5.2, 39.0) + 0.02, 39.0), Vector3(0.22, 0.01, 0.17), B.flat(Color(0.75, 0.72, 0.62), 0.9), {"collide": false}).rotation_degrees.y = -20
	# torn curtains in the lit teahouse windows, moving with no draught
	var tc := Vector3(-9, 4.2, 50)
	_curtain(self, tc + Vector3(2.85, 1.45, -1.75), 90.0)
	_curtain(self, tc + Vector3(-0.35, 1.45, 2.35), 0.0)
	_curtain(self, tc + Vector3(1.15, 1.45, -2.35), 0.0)
	_bulb(self, tc + Vector3(0.6, 2.75, 0.4), 0.0)
	# someone walks past the teahouse's back window, inside, when you are out in the lane
	var sz := Vector3(-9, 5.5, 57.5)
	_watch.append(func() -> bool:
		if Game.has_flag("has_station_key") and _near(sz, 7.0) and _calm():
			_scared()
			var g: Node3D = level.horror.make_ghost(tc + Vector3(-2.2, 0, 1.8), PI * 0.5)
			var tw := g.create_tween()
			tw.tween_property(g, "position:x", tc.x + 2.2, 2.2)
			tw.tween_callback(g.queue_free)
			Sound.play_at("step_wood_2", tc + Vector3(0, 0.2, 1.8), -4.0)
			return true
		return false)
	# a cup topples behind you in the teahouse once you have heard its radio
	_watch.append(func() -> bool:
		if Game.has_flag("heard_teahouse") and _near(tc, 2.6) and _calm():
			_scared()
			get_tree().create_timer(6.0).timeout.connect(func():
				var p: Node3D = level.player
				Sound.play_at("metal_knock", p.global_position + p.global_transform.basis.z * 1.6, -10.0, {"unit_size": 2.0}))
			return true
		return false)


# ------------------------------------------------------------------ the station
func _station() -> void:
	var o := Vector3(-60, 6.5, -10)
	for spec in [[-52.0, -3.0, 0.9], [-66.0, -2.0, 1.2], [-57.0, -17.0, 0.7]]:
		_puddle(spec[0], spec[1], spec[2])
	var oil := B.flat(Color(0.01, 0.01, 0.012), 0.15, 0.5)
	B.cyl(self, Vector3(-55.5, _g(-55.5, -15.5) + 0.012, -15.5), 0.9, 0.01, oil, {"collide": false})
	var cable := B.flat(Color(0.03, 0.03, 0.03), 0.5)
	for spec in [[Vector3(-54, 0, -7), 40.0, 7.0], [Vector3(-63, 0, -4), -15.0, 5.0]]:
		var c: Vector3 = spec[0]
		B.box(self, Vector3(c.x, _g(c.x, c.z) + 0.03, c.z), Vector3(0.05, 0.05, spec[2]), cable, {"collide": false}).rotation_degrees.y = spec[1]
	_sign(Vector3(-52.6, _g(-52.6, -10.0) + 1.4, -10.0), 90.0, "DANGER\nHIGH VOLTAGE")
	# a swinging bulb in the monitoring room; it only lights when the station has power
	var bulb_root := Node3D.new()
	add_child(bulb_root)
	bulb_root.position = o
	_bulb(bulb_root, Vector3(4.5, 2.7, -1.2), 0.5)
	bulb_root.visible = false
	_watch.append(func() -> bool:
		if Game.has_flag("station_power"):
			bulb_root.visible = true
			return true
		return false)
	# the spare chair, turning slowly to face you once the lights are back on
	var chair := P.chair(self, o + Vector3(2.2, 0, -1.4), 20.0)
	_watch.append(func() -> bool:
		if Game.has_flag("station_power") and _near(o + Vector3(4.5, 1.0, -2.0), 3.5) and _calm():
			_scared()
			var target: Vector3 = level.player.global_position
			var tw := chair.create_tween()
			tw.tween_interval(2.0)
			tw.tween_callback(func(): Sound.play_at("door_creak_0", chair.global_position, -8.0, {"unit_size": 2.0}))
			tw.tween_property(chair, "rotation:y", atan2(target.x - chair.global_position.x, target.z - chair.global_position.z), 4.0)
			return true
		return false)


# ------------------------------------------------------------------ Blackwood
func _forest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	for i in 9:
		var x := rng.randf_range(-70, -36)
		var z := rng.randf_range(22, 62)
		if Terrain.path_weight(x, z).x > 0.05:
			continue
		_log(Vector3(x, _g(x, z), z), rng.randf() * 180.0, rng.randf_range(2.5, 5.0), rng.randf_range(0.18, 0.32))
	var cap := B.flat(Color(0.75, 0.68, 0.55), 0.6)
	for i in 16:
		var x := rng.randf_range(-68, -38)
		var z := rng.randf_range(24, 60)
		B.sphere(self, Vector3(x, _g(x, z) + 0.06, z), 0.06, cap, {"height": 0.07})
	# a net caught high in the branches over the path to the hut
	var hp := Vector3(-50.0, 0, 37.0)
	var net := P.net_pile(self, Vector3(hp.x, _g(hp.x, hp.z) + 3.4, hp.z))
	net.rotation_degrees.x = 80
	_no_collide(net)
	# something hanging overhead: you only notice when the rope creaks
	var hang := Node3D.new()
	add_child(hang)
	var hpos := Vector3(-46.0, 0, 44.0)
	hang.position = Vector3(hpos.x, _g(hpos.x, hpos.z) + 4.6, hpos.z)
	B.box(hang, Vector3(0, 1.2, 0), Vector3(0.03, 2.4, 0.03), B.mat("rope", Color.WHITE, 2.0), {"collide": false})
	P.corpse(hang, Vector3(0, -0.9, 0), 0.0, "hung")
	_no_collide(hang)   # overhead decoration must never count as a roof against Kell
	_watch.append(func() -> bool:
		if _near(Vector3(hpos.x, hang.position.y - 4.0, hpos.z), 3.0) and _calm():
			_scared()
			Sound.play_at("door_creak_1", hang.global_position, 0.0, {"unit_size": 4.0})
			var tw := hang.create_tween()
			tw.tween_property(hang, "rotation_degrees:z", 14.0, 0.5).set_trans(Tween.TRANS_SINE)
			tw.tween_property(hang, "rotation_degrees:z", -8.0, 1.0).set_trans(Tween.TRANS_SINE)
			tw.tween_property(hang, "rotation_degrees:z", 3.0, 1.2).set_trans(Tween.TRANS_SINE)
			return true
		return false)
	# a figure runs across the path ahead, between the trees
	var rz := Vector3(-41.0, 0, 46.0)
	_watch.append(func() -> bool:
		if _near(Vector3(rz.x, _g(rz.x, rz.z) + 1.0, rz.z), 6.0) and level.player.global_position.x < rz.x + 2.0 and _calm():
			_scared()
			var p: Node3D = level.player
			var fwd: Vector3 = -p.global_transform.basis.z
			fwd.y = 0.0
			var side: Vector3 = fwd.cross(Vector3.UP).normalized()
			var mid: Vector3 = p.global_position + fwd.normalized() * 11.0
			var a: Vector3 = mid - side * 9.0
			var b: Vector3 = mid + side * 9.0
			a.y = _g(a.x, a.z)
			b.y = _g(b.x, b.z)
			var g: Node3D = level.horror.make_ghost(a, atan2(side.x, side.z))
			var tw := g.create_tween()
			tw.tween_property(g, "global_position", b, 1.1)
			tw.tween_callback(g.queue_free)
			for i in 5:
				get_tree().create_timer(0.2 * i).timeout.connect(func():
					if is_instance_valid(g):
						Sound.play_at("step_grass_%d" % (i % 6), g.global_position, 2.0))
			return true
		return false)


# ------------------------------------------------------------------ the ship graveyard
func _graveyard() -> void:
	var c := Vector3(-98, 0, 46)
	var base := c + Vector3(0, _g(c.x, c.z), 0)
	var ship := Transform3D(Basis(Vector3.UP, deg_to_rad(8.0)), base + Vector3(-2, 0, 0))
	_anchor(base + Vector3(9.0, 0.0, -12.0), -60.0, 80.0)
	# a lifeboat, stove in, on the shingle
	var lb := Node3D.new()
	add_child(lb)
	lb.position = base + Vector3(10.0, 0, 9.0)
	lb.rotation_degrees = Vector3(0, 40, 25)
	var white := B.mat("wood_painted", Color(0.85, 0.85, 0.8), 1.0)
	B.box(lb, Vector3(0, 0.3, 0), Vector3(1.6, 0.1, 4.0), white, {"collide": false})
	for sx in [-1, 1]:
		B.box(lb, Vector3(sx * 0.8, 0.6, 0), Vector3(0.08, 0.6, 4.0), white, {"collide": false})
	B.label(lb, Vector3(0.85, 0.65, 0), "PELAGIC 2", 30, Color(0.2, 0.2, 0.2), Vector3(0, 90, 0))
	# porthole on the hull; on your way out of the hold, a face is pressed to it
	var port_pos: Vector3 = ship * Vector3(3.08, 2.0, -3.5)
	var port := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.22
	tm.outer_radius = 0.3
	port.mesh = tm
	port.material_override = B.mat("metal_rust", Color(0.6, 0.55, 0.5), 2.0, {"metallic": 0.5})
	add_child(port)
	port.global_position = port_pos
	port.rotation = Vector3(0, deg_to_rad(8.0), PI * 0.5)
	B.cyl(self, port_pos, 0.23, 0.02, B.flat(Color(0.03, 0.05, 0.06), 0.05, 0.4), {"collide": false, "rot": Vector3(0, 8, 90)})
	var outside: Vector3 = ship * Vector3(6.5, 1.0, 1.0)
	_watch.append(func() -> bool:
		if Game.has_flag("cargo_line") and _near(outside, 3.5) and _calm():
			_scared()
			var face: Node3D = level.horror.make_ghost(ship * Vector3(2.7, 0.35, -3.5), deg_to_rad(98.0), "face")
			Sound.play_at("door_slam", port_pos, 0.0, {"unit_size": 5.0})
			level.player.shake(0.35)
			get_tree().create_timer(1.3).timeout.connect(func():
				if is_instance_valid(face):
					face.vanish())
			return true
		return false)
	# crew belongings in the hold: a coat, cups, boots
	B.box(self, ship * Vector3(-2.0, 0.05, 1.5), Vector3(0.5, 0.04, 0.9), B.flat(Color(0.12, 0.13, 0.16), 0.9), {"collide": false})
	for i in 3:
		B.cyl(self, ship * Vector3(1.4 + i * 0.12, 0.84, 4.9), 0.04, 0.09, B.flat(Color(0.75, 0.72, 0.65), 0.4), {"collide": false})
	for z in [-0.4, -0.2]:
		B.box(self, ship * Vector3(-2.6, 0.12, z), Vector3(0.12, 0.24, 0.28), B.flat(Color(0.05, 0.05, 0.05), 0.5), {"collide": false})


# ------------------------------------------------------------------ Low Vey
func _lowvey() -> void:
	var c := Vector3(67, 0, -20)
	var algae := B.flat(Color(0.06, 0.12, 0.07), 0.25)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1923
	for i in 18:
		var x := c.x + rng.randf_range(-14, 14)
		var z := c.z + rng.randf_range(-22, 18)
		if abs(x - 66.0) < 2.6:
			continue
		B.cyl(self, Vector3(x, _g(x, z) + 0.015, z), rng.randf_range(0.4, 1.3), 0.01, algae, {"collide": false, "segments": 14})
	for i in 6:
		_puddle(c.x + rng.randf_range(-12, 12), c.z + rng.randf_range(-20, 16), rng.randf_range(0.6, 1.4))
	# a chair and a cradle out in the lane where the sea left them
	P.chair(self, Vector3(c.x - 3.0, _g(c.x - 3.0, c.z + 5.5), c.z + 5.5), 130.0).rotation_degrees.z = 70
	var cr := B.box(self, Vector3(c.x + 7.5, _g(c.x + 7.5, c.z - 9.0) + 0.25, c.z - 9.0), Vector3(0.5, 0.35, 0.9), B.mat("wood_dark", Color(0.8, 0.7, 0.6), 1.0), {"collide": false})
	cr.rotation_degrees = Vector3(0, 25, 15)
	# figures standing in the drowned houses, gone when you come near
	_distant_figure(Vector3(c.x - 6, _g(c.x - 6, c.z - 8), c.z - 8), PI * 0.4, 9.0, "tide_out")
	_distant_figure(Vector3(c.x + 4, _g(c.x + 4, c.z + 12), c.z + 12), PI * 1.2, 9.0, "lowvey_silence")
	# after the silence: one of them is right behind you
	_watch.append(func() -> bool:
		if not Game.has_flag("lowvey_silence"):
			return false
		_behind_you()
		return true)


func _behind_you() -> void:
	await get_tree().create_timer(16.0).timeout
	var p: Node3D = level.player
	if p.dead or level.listener.is_active():
		return
	_scared()
	var back: Vector3 = p.global_transform.basis.z
	back.y = 0.0
	var pos: Vector3 = p.global_position + back.normalized() * 1.3
	pos.y = _g(pos.x, pos.z) - 0.1
	var g: Node3D = level.horror.make_ghost(pos, p.rotation.y)
	Sound.play_at("step_water_1", pos, 0.0, {"unit_size": 2.0})
	var yaw0: float = p.rotation.y
	for i in 40:
		await get_tree().create_timer(0.1).timeout
		if not is_instance_valid(p) or p.dead:
			break
		if abs(wrapf(p.rotation.y - yaw0, -PI, PI)) > 2.2:
			if is_instance_valid(g):
				g.queue_free()
			level.horror.face_scare(2)
			return
	if is_instance_valid(g):
		g.vanish()


# ------------------------------------------------------------------ the caves
func _caves() -> void:
	var cv: Node = level.areas.caves
	var wood := B.mat("wood_dark", Color(0.6, 0.55, 0.5), 1.0)
	# old timber props at the entrance passage, from the people who came in before
	for z in [-3.0, -11.0]:
		for x in [-1.5, 1.5]:
			B.box(self, cv._p(x, z, 1.1), Vector3(0.18, 2.2, 0.18), wood, {"collide": false})
		B.box(self, cv._p(0.0, z, 2.25), Vector3(3.2, 0.2, 0.2), wood, {"collide": false})
	_coil(cv._p(-1.1, -6.5, 0.0))
	# a lantern someone dropped, still faintly lit
	B.cyl(self, cv._p(1.0, -14.0, 0.12), 0.08, 0.22, B.mat("metal_rust", Color.WHITE, 2.0, {"metallic": 0.5}), {"collide": false}).rotation_degrees.z = 80
	B.omni(self, cv._p(1.0, -14.0, 0.25), Color(1.0, 0.6, 0.3), 0.25, 2.5)
	# stalactites over the gallery, slick with water
	var drip := B.mat("rock_cave", Color(0.9, 0.95, 0.95), 1.2, {"wet": 1.0})
	var rng := RandomNumberGenerator.new()
	rng.seed = 55
	for i in 22:
		var z := rng.randf_range(-74, -38)
		var x := rng.randf_range(-2.4, 2.4)
		var top: Vector3 = cv._p(x, z, 3.6)
		var s := B.cyl(self, top, 0.12, rng.randf_range(0.5, 1.2), drip, {"collide": false, "top": 0.0})
		s.rotation_degrees.x = 180


# ------------------------------------------------------------------ the annex
func _annex() -> void:
	var o := Vector3(220, -200, 0)
	var c := o + Vector3(-7, 0, -10)
	# a gurney with a covered body; after the lights stutter, it moves
	var steel := B.mat("metal_green", Color(0.85, 0.9, 0.88), 1.5, {"metallic": 0.5})
	B.box(self, c + Vector3(2.4, 0.75, 2.5), Vector3(0.75, 0.06, 1.9), steel, {"collide": false})
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			B.box(self, c + Vector3(2.4 + sx * 0.33, 0.37, 2.5 + sz * 0.85), Vector3(0.04, 0.74, 0.04), steel, {"collide": false})
	var body: Node3D = P.covered(self, c + Vector3(2.4, 0.78, 2.5), 0)
	# discarded coats and broken glass
	B.box(self, c + Vector3(-2.0, 0.03, 3.0), Vector3(0.7, 0.03, 1.0), B.flat(Color(0.7, 0.72, 0.68), 0.9), {"collide": false}).rotation_degrees.y = 30
	var glass := B.flat(Color(0.6, 0.7, 0.7), 0.05, 0.2)
	for i in 8:
		B.box(self, c + Vector3(3.0 + randf_range(-0.5, 0.5), 0.01, -2.6 + randf_range(-0.5, 0.5)), Vector3(0.08, 0.005, 0.05), glass, {"collide": false}).rotation_degrees.y = randf() * 180.0
	_watch.append(func() -> bool:
		if _near(c, 4.0) and _calm():
			_scared()
			_body_moves(c, body)
			return true
		return false)


func _body_moves(c: Vector3, body: Node3D) -> void:
	await get_tree().create_timer(3.0).timeout
	# the room goes dark in stutters, and in the dark the sheet moves
	level.hud.set_dread(0.9)
	await get_tree().create_timer(0.25).timeout
	level.hud.set_dread(0.0)
	await get_tree().create_timer(0.15).timeout
	level.hud.set_dread(1.0)
	await get_tree().create_timer(0.5).timeout
	var tw := body.create_tween()
	tw.tween_property(body, "rotation_degrees:z", 9.0, 0.12)
	tw.tween_property(body, "rotation_degrees:z", 0.0, 0.4)
	Sound.play_at("metal_knock", body.global_position, -4.0, {"unit_size": 3.0})
	level.hud.set_dread(0.0)


# ------------------------------------------------------------------ the lighthouse
func _lighthouse() -> void:
	var lh: Node = level.areas.lighthouse
	var c: Vector3 = lh.C
	# keeper's things on the ground floor: a coat on a hook, boots, a rug, an oil lamp
	B.box(self, c + Vector3(-1.0, 0.012, -1.6), Vector3(1.8, 0.01, 1.2), B.flat(Color(0.3, 0.12, 0.09), 0.95), {"collide": false})
	B.box(self, c + Vector3(3.6, 1.4, -2.0), Vector3(0.1, 0.9, 0.45), B.flat(Color(0.12, 0.14, 0.16), 0.9), {"collide": false})
	for dz in [-0.12, 0.12]:
		B.box(self, c + Vector3(3.4, 0.12, -1.6 + dz), Vector3(0.28, 0.24, 0.12), B.flat(Color(0.05, 0.05, 0.05), 0.4), {"collide": false})
	B.cyl(self, c + Vector3(2.6, 0.95, 1.6), 0.08, 0.22, B.glow(Color(1.0, 0.7, 0.4), 1.5), {"collide": false})
	B.omni(self, c + Vector3(2.6, 1.2, 1.6), Color(1.0, 0.65, 0.35), 0.35, 4.0, true)
	# on the landing: something crosses the top of the stairs above you
	_watch.append(func() -> bool:
		var p: Vector3 = level.player.global_position
		if Game.has_flag("lh_glimpse") and p.y > c.y + 5.0 and p.y < c.y + 8.0 and p.distance_to(c) < 9.0 and _calm():
			_scared()
			level.horror.listener_glimpse(c + Vector3(1.5, 12.0, -2.0), PI * 0.3, null, 0.7)
			Sound.play_at("step_metal_3", c + Vector3(1.5, 12.2, -2.0), 0.0)
			return true
		return false)
