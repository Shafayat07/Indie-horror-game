extends Node3D
## LOW VEY — the village the sea took in 1923, lying on the tidal shelf below
## the east cliffs. Under water until the transmission pulls the tide out.
## Walk into its square and the island repeats the thirteen-second silence.

const C := Vector3(67, 0, -20)

var level: Node


func build(lv: Node) -> void:
	level = lv
	add_to_group("navsrc_surface")
	var stone := B.mat("stone_blocks", Color(0.75, 0.82, 0.8), 0.4)
	var weed := B.flat(Color(0.05, 0.09, 0.05), 0.4)
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	# roofless cottages: broken walls, doorways, a chimney stack each
	# cottages either side of a clear lane (x 63.5..68.5) that leads on to the cave mouth
	for spec in [[Vector3(-6, 0, -8), 6.0], [Vector3(4, 0, -2), -6.0], [Vector3(-6, 0, 8), 4.0], [Vector3(4, 0, 12), 8.0], [Vector3(-6, 0, -18), -5.0]]:
		var house := Node3D.new()
		add_child(house)
		var p: Vector3 = C + spec[0]
		house.position = Vector3(p.x, Terrain.height(p.x, p.z), p.z)
		house.rotation_degrees.y = spec[1]
		for w in [[Vector3(0, 0, -2), Vector3(4.6, 1, 0.4)], [Vector3(-2.3, 0, 0), Vector3(0.4, 1, 4.0)], [Vector3(2.3, 0, 0.8), Vector3(0.4, 1, 2.4)], [Vector3(-1.2, 0, 2), Vector3(2.2, 1, 0.4)]]:
			var h := rng.randf_range(0.8, 2.4)
			B.box(house, w[0] + Vector3(0, h * 0.5, 0), Vector3(w[1].x, h, w[1].z), stone, {"surface": "stone"})
			B.box(house, w[0] + Vector3(0, h + 0.03, 0), Vector3(w[1].x, 0.06, w[1].z), weed, {"collide": false})
		B.box(house, Vector3(-1.6, 1.6, -1.6), Vector3(0.7, 3.2, 0.7), stone, {})
	# the family at supper, turned toward the lighthouse
	var hp := C + Vector3(4, 0, -2)
	var house_floor := Vector3(hp.x, Terrain.height(hp.x, hp.z), hp.z)
	P.table(self, house_floor, 0, Vector2(1.4, 0.9))
	for i in 3:
		P.corpse(self, house_floor + Vector3(-0.8 + i * 0.8, 0, 0.75), 180 + (i - 1) * 25, "sit")
	P.examine(self, house_floor + Vector3(0, 0.9, 0), Vector3(1.6, 0.6, 1.2), "lowvey_table")
	P.note(self, house_floor + Vector3(0.4, 0.8, -0.2), "wren_1923", 20)
	# the church bell of Low Vey, fallen in the sand
	var bp := C + Vector3(0, 0, 3)
	var bell := B.cyl(self, Vector3(bp.x, Terrain.height(bp.x, bp.z) + 0.3, bp.z), 0.55, 0.9, B.mat("metal_green", Color(0.6, 0.8, 0.7), 1.0, {"metallic": 0.6}), {"top": 0.3, "collide": false})
	bell.rotation_degrees = Vector3(80, 20, 0)
	P.examine(self, Vector3(bp.x, Terrain.height(bp.x, bp.z) + 0.5, bp.z), Vector3(1.4, 1.0, 1.4), "church_bell")
	# what people left: a child's toys on a step, nets still knotted for mending
	var tp := C + Vector3(-6, 0, 8)
	var tg := Vector3(tp.x + 1.0, Terrain.height(tp.x + 1.0, tp.z + 1.0), tp.z + 1.0)
	var wood := B.mat("wood_planks", Color(0.7, 0.55, 0.4), 1.0)
	B.box(self, tg + Vector3(0, 0.1, 0), Vector3(0.45, 0.12, 0.16), wood, {"collide": false})
	B.box(self, tg + Vector3(0, 0.3, 0), Vector3(0.02, 0.3, 0.02), wood, {"collide": false})
	B.sphere(self, tg + Vector3(0.45, 0.12, 0.1), 0.12, B.flat(Color(0.55, 0.42, 0.38), 0.9))
	B.cyl(self, tg + Vector3(-0.4, 0.1, 0.15), 0.13, 0.2, B.flat(Color(0.5, 0.15, 0.1), 0.5, 0.5), {"collide": false})
	P.examine(self, tg + Vector3(0, 0.3, 0), Vector3(1.2, 0.6, 0.8), "toys")
	var np := C + Vector3(-6, 0, -18)
	var ng := Vector3(np.x + 1.5, Terrain.height(np.x + 1.5, np.z + 2.5), np.z + 2.5)
	P.net_pile(self, ng)
	P.buoy(self, ng + Vector3(0.9, 0, 0.4), 70.0)
	P.examine(self, ng + Vector3(0, 0.4, 0), Vector3(1.6, 0.8, 1.4), "nets")
	# the square: the island repeats the thirteen seconds of 1923
	Zone.make(self, Vector3(C.x, Terrain.height(C.x, C.z) + 1.5, C.z), Vector3(10, 4, 10), {"once": true, "require": "tide_out", "block": "lowvey_silence", "on_enter": func(_b):
		level.chapter("ch_lowvey")
		level.hud.elias("lowvey", 1.0)
		await get_tree().create_timer(4.0).timeout
		level.horror.silence13(_after_silence)})


func _after_silence() -> void:
	Game.set_flag("lowvey_silence")
	var p: Node3D = level.player
	Sound.play_2d("sting_2", 2.0)
	p.shake(1.0)
	# for one breath, the drowned are all around you
	var ghosts := []
	for i in 7:
		var a := TAU * i / 7.0
		var pos: Vector3 = p.global_position + Vector3(sin(a), 0, cos(a)) * 3.2
		pos.y = Terrain.height(pos.x, pos.z)
		ghosts.append(level.horror.make_ghost(pos, a + PI))
	await get_tree().create_timer(0.9).timeout
	for g in ghosts:
		g.vanish()
	Sound.say("[seven figures, all around you, facing you. Then only the sea.]", "aside", 4.0)
	# and out past the shelf, under the water, a bell answers
	await get_tree().create_timer(9.0).timeout
	Sound.play_at("bell_drowned", C + Vector3(30, -2, 4), 8.0, {"unit_size": 30.0, "max_distance": 200.0})
	level.hud.elias("sea_bell", 1.5)
