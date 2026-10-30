extends Node3D
## THE UNDERGROUND RESEARCH ANNEX — Project Morrow (optional). Reached through
## an iron door in the cave gallery. Examination room, containment cells,
## Morrow's records. Taking Morrow's tape (part one of the last recording)
## kills the lights and brings The Listener down the corridor: a chase.

const O := Vector3(220, -200, 0)   # must match island.ANNEX_ORIGIN

var level: Node
var lamps: Array[Light3D] = []
var _tile := B.mat("concrete", Color(0.75, 0.8, 0.78), 0.5)
var _floor := B.mat("concrete", Color(0.5, 0.52, 0.5), 0.6)


func build(lv: Node) -> void:
	level = lv
	add_to_group("navsrc_annex")
	level.checkpoints["annex"] = [O + Vector3(0, 0.3, -1.5), 0.0, "annex"]
	B.box(self, O + Vector3(0, -0.25, -18), Vector3(26, 0.5, 40), _floor, {"surface": "stone"})
	B.box(self, O + Vector3(0, 3.15, -18), Vector3(26, 0.3, 40), _tile, {"collide": false})
	# corridor x -1.5..1.5, z -4..-36 ; rooms open off it
	_wall(Vector3(-1.6, 0, -4), Vector3(-1.6, 0, -36), [[-10.0, 1.4], [-26.0, 1.2]])
	_wall(Vector3(1.6, 0, -4), Vector3(1.6, 0, -36), [[-18.0, 1.4], [-33.0, 1.2]])
	_wall(Vector3(-1.6, 0, -36), Vector3(1.6, 0, -36), [])
	_wall(Vector3(-4, 0, 1.5), Vector3(4, 0, 1.5), [])            # entrance hall
	_wall(Vector3(-4, 0, 1.5), Vector3(-4, 0, -4), [])
	_wall(Vector3(4, 0, 1.5), Vector3(4, 0, -4), [])
	_wall(Vector3(-4, 0, -4), Vector3(-1.6, 0, -4), [])
	_wall(Vector3(1.6, 0, -4), Vector3(4, 0, -4), [])
	for z in range(-6, -36, -6):
		var l := B.omni(self, O + Vector3(0, 2.8, z), Color(0.75, 0.9, 0.85), 0.9, 7.0, z == -12)
		l.set_script(preload("res://scripts/world/flicker.gd"))
		lamps.append(l)
		B.box(self, O + Vector3(0, 3.0, z), Vector3(1.2, 0.06, 0.25), B.glow(Color(0.8, 0.95, 0.9), 1.5), {"collide": false})
	B.label(self, O + Vector3(0, 2.4, -3.85), "PROJECT MORROW — CLINICAL WING", 34, Color(0.75, 0.8, 0.75))
	_exam_room()
	_containment()
	_records()
	_tape_room()
	var up := Interactable.make(self, O + Vector3(0, 1.2, 1.2), Vector3(2.5, 2.4, 0.6), "Climb back up to the caves")
	up.used.connect(func(_p): _leave())
	Zone.make(self, O + Vector3(0, 1.5, -18), Vector3(26, 3, 40), {"ambience": "station_in", "reverb": 0.3})
	Zone.make(self, O + Vector3(0, 1.5, -6), Vector3(3, 3, 2), {"once": true, "block": "annex_glimpse", "on_enter": func(_b):
		Game.set_flag("annex_glimpse")
		level.chapter("ch_annex")
		level.hud.elias("annex", 0.5)
		level.horror.listener_glimpse(O + Vector3(0, 0, -34), 0.0, lamps[-1], 1.4)})


func _wall(a: Vector3, b: Vector3, gaps: Array) -> void:
	var along_z: bool = abs(a.x - b.x) < 0.01
	var lo: float = min(a.z, b.z) if along_z else min(a.x, b.x)
	var hi: float = max(a.z, b.z) if along_z else max(a.x, b.x)
	var cuts := []
	for g in gaps:
		cuts.append([g[0] - g[1] * 0.5, g[0] + g[1] * 0.5])
	cuts.sort_custom(func(x, y): return x[0] < y[0])
	var cursor := lo
	var segs := []
	for c in cuts:
		segs.append([cursor, c[0], 0.0])
		segs.append([c[0], c[1], 2.2])
		cursor = c[1]
	segs.append([cursor, hi, 0.0])
	for sgm in segs:
		var w: float = sgm[1] - sgm[0]
		if w <= 0.01:
			continue
		var mid: float = (sgm[0] + sgm[1]) * 0.5
		var y0: float = sgm[2]
		var h := 3.0 - y0
		var pos := O + (Vector3(a.x, y0 + h * 0.5, mid) if along_z else Vector3(mid, y0 + h * 0.5, a.z))
		B.box(self, pos, Vector3(0.2, h, w) if along_z else Vector3(w, h, 0.2), _tile, {"surface": "stone"})


func _exam_room() -> void:
	## west of the corridor at z -10: x -12..-1.6
	_wall(Vector3(-12, 0, -6), Vector3(-1.6, 0, -6), [])
	_wall(Vector3(-12, 0, -14), Vector3(-1.6, 0, -14), [])
	_wall(Vector3(-12, 0, -6), Vector3(-12, 0, -14), [])
	var c := O + Vector3(-7, 0, -10)
	B.omni(self, c + Vector3(0, 2.6, 0), Color(0.9, 0.95, 0.85), 0.7, 7.0, true)
	# the chair with the headset bolted in
	var metal := B.mat("metal_green", Color(0.8, 0.85, 0.8), 1.5)
	B.box(self, c + Vector3(0, 0.45, 0), Vector3(0.7, 0.9, 1.6), metal, {"surface": "metal"}).rotation_degrees.x = -10
	B.box(self, c + Vector3(0, 1.3, -0.75), Vector3(0.6, 0.9, 0.15), metal, {"collide": false})
	B.cyl(self, c + Vector3(0, 1.85, -0.7), 0.18, 0.12, B.flat(Color(0.1, 0.1, 0.1), 0.3, 0.7), {"collide": false})
	P.blood(self, c + Vector3(0.2, 0, 0.6), Vector2(1.6, 1.2))
	P.examine(self, c + Vector3(0, 1.0, 0), Vector3(0.8, 1.2, 1.6), "annex_chair")
	P.covered(self, c + Vector3(-3.2, 0, -2.6), 90)
	P.covered(self, c + Vector3(-3.2, 0, 2.4), 90)
	P.smear(self, O + Vector3(-11.85, 1.3, -9), Vector2(1.8, 1.4), 90)
	P.shelf(self, c + Vector3(3.5, 0, -3.6), 0, 1.6)
	for i in 6:
		P.ear_jar(self, c + Vector3(2.9 + (i % 3) * 0.4, 0.62 + (i / 3) * 0.55, -3.6))
	P.examine(self, c + Vector3(3.5, 1.0, -3.5), Vector3(1.6, 1.4, 0.5), "annex_jars")


func _containment() -> void:
	## east at z -18: three barred cells
	_wall(Vector3(1.6, 0, -14), Vector3(12, 0, -14), [])
	_wall(Vector3(1.6, 0, -22), Vector3(12, 0, -22), [])
	_wall(Vector3(12, 0, -14), Vector3(12, 0, -22), [])
	var bars := B.mat("metal_rust", Color(0.6, 0.6, 0.6), 1.0, {"metallic": 0.5})
	for i in 3:
		var x := 4.5 + i * 2.6
		for k in 7:
			B.cyl(self, O + Vector3(x - 1.2 + k * 0.4, 1.5, -15.8), 0.03, 3.0, bars, {"collide": false})
		B.collider(self, O + Vector3(x, 1.5, -15.8), Vector3(2.5, 3.0, 0.1))
	# cell 1: a body grown into rope and netting — what the Listener is made of
	P.corpse(self, O + Vector3(4.5, 0.4, -19.5), 0, "hung", true)
	P.net_pile(self, O + Vector3(4.5, 0, -18.8))
	P.smear(self, O + Vector3(4.5, 1.4, -21.85), Vector2(1.4, 1.6), 0)
	B.omni(self, O + Vector3(7, 2.6, -18), Color(0.85, 0.2, 0.15), 0.5, 7.0)
	level.horror.apparition(O + Vector3(9.7, 0, -19.5), PI, {"range": 14.0, "scare": true, "sting": 1, "kind": "face"})


func _records() -> void:
	## west at z -26: Morrow's records office (white ring: safe)
	_wall(Vector3(-8, 0, -22), Vector3(-1.6, 0, -22), [])
	_wall(Vector3(-8, 0, -30), Vector3(-1.6, 0, -30), [])
	_wall(Vector3(-8, 0, -22), Vector3(-8, 0, -30), [])
	var d := Door.make(self, O + Vector3(-1.6, 0, -26), -90, {"id": "annex_office", "w": 1.1, "h": 2.1})
	B.ring_mark(self, O + Vector3(-1.45, 1.7, -25.2), -90)
	Zone.make(self, O + Vector3(-4.8, 1.5, -26), Vector3(6, 3, 7.6), {"safe": true})
	var c := O + Vector3(-5, 0, -26)
	B.omni(self, c + Vector3(0, 2.5, 0), Color(1.0, 0.8, 0.55), 0.6, 6.0)
	P.table(self, c + Vector3(-1, 0, -2.6), 0, Vector2(1.8, 0.8))
	P.note(self, c + Vector3(-1.4, 0.8, -2.6), "morrow_file", 10)
	var lst := P.examine(self, c + Vector3(-0.4, 0.95, -2.6), Vector3(0.6, 0.4, 0.5), "annex_list")
	lst.used.connect(func(_p): Game.set_flag("annex_list"))
	P.paper(self, c + Vector3(-0.4, 0.8, -2.6), -15)
	P.shelf(self, c + Vector3(2.3, 0, -3.6), 0, 1.4)


func _tape_room() -> void:
	## east at z -33: Morrow's tape
	_wall(Vector3(1.6, 0, -30), Vector3(7, 0, -30), [])
	_wall(Vector3(7, 0, -30), Vector3(7, 0, -36), [])
	_wall(Vector3(1.6, 0, -36), Vector3(7, 0, -36), [])
	var c := O + Vector3(4.5, 0, -33)
	P.table(self, c, 90, Vector2(1.2, 0.8))
	B.box(self, c + Vector3(0, 0.9, 0), Vector3(0.5, 0.2, 0.35), B.mat("wood_dark", Color(1.1, 1.0, 0.9), 2.0), {"collide": false})
	B.omni(self, c + Vector3(0, 2.5, 0), Color(1.0, 0.7, 0.4), 0.5, 5.0)
	var it := Interactable.make(self, c + Vector3(0, 1.0, 0), Vector3(0.7, 0.5, 0.6), "Play and record Dr. Morrow's tape")
	it.used.connect(func(p):
		if Game.has_recording("morrow_tape"):
			p.hud.toast("You already have Morrow's tape.")
			return
		Game.add_recording("morrow_tape", c + Vector3(0, 1.0, 0))
		Sound.play_at("radio_voice_c", c + Vector3(0, 1.0, 0), 0.0, {"bus": "Voice"})
		Sound.say(Story.RECORDINGS["morrow_tape"].caption, "radio", 6.0)
		p.hud.toast("Recorded: " + Story.RECORDINGS["morrow_tape"].name)
		_chase())


## The lights die; The Listener walks out of the dark end of the corridor.
func _chase() -> void:
	await get_tree().create_timer(5.0).timeout
	Sound.play_2d("power_down", 0.0)
	for l in lamps:
		l.set_script(null)
		l.light_energy = 0.0
	await get_tree().create_timer(1.5).timeout
	var pts := [O + Vector3(0, 0, -34), O + Vector3(0, 0, -20), O + Vector3(0, 0, -8), O + Vector3(-6, 0, -10), O + Vector3(7, 0, -18)]
	level.listener.activate(O + Vector3(0, 0, -6.0), pts, level.listener.S.HUNTING)
	level.listener.hunt_enabled = true
	level.listener.last_seen = level.player.global_position
	level.hud.toast("RUN — the white-ringed office, or the ladder.", 3.0)


func _leave() -> void:
	level.listener.deactivate()
	var caves = level.areas["caves"]
	var to: Vector3 = caves._p(-4.8, -47.5, 0.3)
	await level.travel(to, -60.0, "caves", "caves")
	if Game.has_flag("gallery_entered"):
		caves._activate_listener()
