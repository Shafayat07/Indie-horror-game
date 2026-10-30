"""Blender (bpy) script that models the game's hero assets and exports GLB.

Run with Blender's Python module (pip install bpy==5.2.3):
    python tools/blender/build_models.py [lighthouse chapel trees kell]

Coordinates: models are authored so that after glTF export (Y-up) the game's
conventions hold: Blender +X = Godot +X, Blender +Z = Godot +Y, Blender -Y = Godot +Z.
Materials are named (whitewash, stone, red, iron, glass, copper, lamp, slate,
wood, bark, pine, skin, membrane, ...) and replaced in Godot by the project's
procedural texture sets, so only the names matter here.
"""
import math
import os
import sys

import bpy  # must come first: it makes bmesh/mathutils importable
import bmesh
from mathutils import Matrix, Vector

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "models")


# --------------------------------------------------------------------------- helpers
def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def material(name):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    return m


def obj_from_bmesh(name, bm, mat=None):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    if mat:
        ob.data.materials.append(material(mat))
    return ob


def activate(ob):
    for o in bpy.data.objects:
        if o is not None and o.name in bpy.context.view_layer.objects:
            o.select_set(False)
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob


def apply_mods(ob):
    activate(ob)
    for m in list(ob.modifiers):
        bpy.ops.object.modifier_apply(modifier=m.name)


def boolean(ob, cutter, op="DIFFERENCE"):
    mod = ob.modifiers.new("bool", "BOOLEAN")
    mod.object = cutter
    mod.operation = op
    mod.solver = "EXACT"
    apply_mods(ob)


def delete(ob):
    bpy.data.objects.remove(ob, do_unlink=True)


def cylinder(name, r1, r2, z0, z1, segs=32, mat=None, cap=True):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=cap, cap_tris=False, segments=segs, radius1=r1, radius2=r2, depth=z1 - z0)
    bmesh.ops.translate(bm, verts=bm.verts, vec=(0, 0, (z0 + z1) / 2))
    return obj_from_bmesh(name, bm, mat)


def box(name, center, size, mat=None, rot_z=0.0):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=size, verts=bm.verts)
    bmesh.ops.rotate(bm, verts=bm.verts, cent=(0, 0, 0), matrix=Matrix.Rotation(rot_z, 3, "Z"))
    bmesh.ops.translate(bm, verts=bm.verts, vec=center)
    return obj_from_bmesh(name, bm, mat)


def posed(ob, loc, rot):
    """Rotate an object built at the origin about its own centre, then move it."""
    ob.rotation_euler = rot
    ob.location = loc
    activate(ob)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return ob


def join(name, objs):
    activate(objs[0])
    for o in objs[1:]:
        o.select_set(True)
    bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active
    ob.name = name
    return ob


def bevel(ob, width=0.04, segs=2):
    m = ob.modifiers.new("bevel", "BEVEL")
    m.width = width
    m.segments = segs
    m.limit_method = "ANGLE"
    apply_mods(ob)


def smooth(ob, angle=40):
    activate(ob)
    bpy.ops.object.shade_smooth_by_angle(angle=math.radians(angle))


def export(name, objects=None):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + ".glb")
    for o in bpy.context.view_layer.objects:
        o.select_set(objects is None or o in objects)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=objects is not None,
                              export_apply=True, export_yup=True, export_materials="EXPORT")
    print("exported", path)


def skin_object(name, verts, edges, radii, mat, subdiv=2, root=0):
    """Organic tube mesh from a skeleton (Skin modifier + subdivision)."""
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, edges, [])
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    skin = ob.modifiers.new("skin", "SKIN")
    sv = me.skin_vertices[0].data
    for i, r in enumerate(radii):
        sv[i].radius = r if isinstance(r, tuple) else (r, r)
    sv[root].use_root = True
    sub = ob.modifiers.new("sub", "SUBSURF")
    sub.levels = subdiv
    apply_mods(ob)
    ob.data.materials.append(material(mat))
    smooth(ob, 60)
    return ob


# --------------------------------------------------------------------------- lighthouse
TOP = 15.5


def lighthouse():
    reset()
    parts = []
    # tapered round tower shell (hollow), wall from 6.9..7.3 at the base to 6.55..6.95 at the top
    outer = cylinder("shell", 7.3, 6.95, 0.0, TOP, 48, "whitewash")
    inner = cylinder("cut", 6.9, 6.55, -0.5, TOP + 0.5, 48)
    boolean(outer, inner)
    delete(inner)
    # door opening (Godot +Z = Blender -Y), with an arched head
    door_cut = box("dcut", (0, -7.1, 1.3), (1.5, 3.0, 2.6))
    arch = cylinder("arch", 0.75, 0.75, -1.5, 1.5, 24)
    arch.rotation_euler = (math.radians(90), 0, 0)
    arch.location = (0, -7.1, 2.6)
    apply_mods(arch)
    activate(arch)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    boolean(outer, door_cut)
    boolean(outer, arch)
    delete(door_cut)
    delete(arch)
    # red band: separate ring so it carries its own material
    band = cylinder("band", 7.13, 7.09, 8.2, 9.8, 48, "red", cap=False)
    sbm = bmesh.new()
    sbm.from_mesh(band.data)
    bmesh.ops.reverse_faces(sbm, faces=sbm.faces)
    sbm.to_mesh(band.data)
    sbm.free()
    band2 = cylinder("band2", 7.14, 7.1, 8.2, 9.8, 48, "red", cap=False)
    parts += [outer, band, band2]
    # stone plinth with the door gap
    plinth = cylinder("plinth", 8.0, 7.7, 0.0, 1.3, 48, "stone")
    pin = cylinder("pcut", 7.25, 7.25, -0.5, 2.0, 48)
    boolean(plinth, pin)
    delete(pin)
    pd = box("pd", (0, -7.6, 1.0), (1.5, 2.0, 2.4))
    boolean(plinth, pd)
    delete(pd)
    bevel(plinth, 0.05)
    parts.append(plinth)
    # door surround: stone jambs and an arch of voussoirs
    for sx in (-1, 1):
        parts.append(box("jamb", (sx * 0.95, -7.35, 1.3), (0.4, 0.5, 2.6), "stone"))
    for i in range(9):
        a = math.pi * i / 8
        v = box("vous", (0, 0, 0), (0.32, 0.5, 0.42), "stone")
        parts.append(posed(v, (math.cos(a) * 0.98, -7.35, 2.6 + math.sin(a) * 0.98), (0, -a + math.pi / 2, 0)))
    # recessed windows with stone frames and dark glass (some lit)
    for k, (ang, z) in enumerate([(45, 4.5), (135, 4.5), (225, 4.5), (315, 4.5), (90, 10.6), (270, 10.6), (180, 13.2)]):
        a = math.radians(ang)
        rr = 7.15 - (z / TOP) * 0.35
        x, y = math.sin(a) * rr, -math.cos(a) * rr
        frame = box("wframe", (x, y, z), (1.05, 0.25, 1.75), "stone", -a)
        glass = box("wglass", (x * 1.003, y * 1.003, z), (0.75, 0.27, 1.45), "lamp" if k in (4, 6) else "glass_dark", -a)
        parts += [frame, glass]
    # cornice: corbels under a projecting gallery deck
    for i in range(36):
        a = 2 * math.pi * i / 36
        c = box("corbel", (math.cos(a) * 7.2, math.sin(a) * 7.2, TOP - 0.45), (0.9, 0.35, 0.9), "stone", a)
        parts.append(c)
    deck = cylinder("deck", 8.3, 8.3, TOP, TOP + 0.45, 48, "stone")
    bevel(deck, 0.06)
    parts.append(deck)
    # gallery railing
    for i in range(48):
        a = 2 * math.pi * i / 48
        parts.append(cylinder("post", 0.04, 0.04, TOP + 0.45, TOP + 1.6, 6, "iron"))
        parts[-1].location = (math.cos(a) * 8.1, math.sin(a) * 8.1, 0)
    for z in (TOP + 1.0, TOP + 1.6):
        bpy.ops.mesh.primitive_torus_add(major_radius=8.1, minor_radius=0.04, major_segments=64, minor_segments=6, location=(0, 0, z))
        t = bpy.context.active_object
        t.data.materials.append(material("iron"))
        parts.append(t)
    # lantern room: iron base, glazing with mullions, copper dome, ventilator
    parts.append(cylinder("lbase", 3.2, 3.1, TOP + 0.45, TOP + 1.6, 16, "red"))
    glass_c = cylinder("lglass", 2.9, 2.9, TOP + 1.6, TOP + 4.6, 12, "glass", cap=False)
    parts.append(glass_c)
    for i in range(12):
        a = 2 * math.pi * (i + 0.5) / 12
        m = box("mullion", (math.cos(a) * 2.95, math.sin(a) * 2.95, TOP + 3.1), (0.1, 0.1, 3.0), "iron", a)
        parts.append(m)
    for z in (TOP + 1.65, TOP + 3.1, TOP + 4.55):
        bpy.ops.mesh.primitive_torus_add(major_radius=2.95, minor_radius=0.06, major_segments=12, minor_segments=4, location=(0, 0, z))
        t = bpy.context.active_object
        t.data.materials.append(material("iron"))
        parts.append(t)
    parts.append(cylinder("eave", 3.5, 3.3, TOP + 4.55, TOP + 4.8, 24, "copper"))
    bpy.ops.mesh.primitive_uv_sphere_add(radius=3.3, segments=32, ring_count=16, location=(0, 0, TOP + 4.8))
    dome = bpy.context.active_object
    dome.scale = (1, 1, 0.62)
    bm = bmesh.new()
    bm.from_mesh(dome.data)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < -0.01], context="VERTS")
    bm.to_mesh(dome.data)
    bm.free()
    dome.data.materials.append(material("copper"))
    parts.append(dome)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.45, segments=16, ring_count=8, location=(0, 0, TOP + 7.0))
    ball = bpy.context.active_object
    ball.data.materials.append(material("copper"))
    parts.append(ball)
    parts.append(cylinder("rod", 0.04, 0.02, TOP + 7.0, TOP + 9.5, 6, "iron"))
    for p in parts:
        activate(p)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    shell = join("LighthouseShell", [outer, band, band2, plinth])
    join("LighthouseDetail", [o for o in bpy.context.view_layer.objects if o.name != "LighthouseShell"])
    export("lighthouse")


# --------------------------------------------------------------------------- chapel
def chapel():
    """St. Brendan's chapel: nave along Godot Z (Blender -Y), tower at the front (+Z)."""
    reset()
    W, L, H = 8.0, 16.0, 6.0      # nave interior
    T = 0.6
    parts = []
    nave = box("nave", (0, 0, H / 2), (W + 2 * T, L + 2 * T, H), "stone_blocks")
    hollow = box("nh", (0, 0, H / 2), (W, L, H + 1))
    boolean(nave, hollow)
    delete(hollow)
    # tall arched windows on both long sides
    for sx in (-1, 1):
        for i in range(3):
            y = -5 + i * 5
            cut = box("wc", (sx * (W / 2 + T / 2), y, 3.2), (T * 3, 1.1, 2.6))
            boolean(nave, cut)
            delete(cut)
            arch = cylinder("wa", 0.55, 0.55, -1, 1, 16)
            arch.rotation_euler = (0, math.radians(90), 0)
            arch.location = (sx * (W / 2 + T / 2), y, 4.5)
            activate(arch)
            bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
            boolean(nave, arch)
            delete(arch)
            g = box("stained", (sx * (W / 2 + T / 2), y, 3.6), (0.08, 1.1, 3.4), "stained")
            parts.append(g)
    # front opening into the tower porch, and the vestry door at the back right
    boolean(nave, box("fo", (0, -(L / 2 + T / 2), 1.6), (2.4, T * 3, 3.2)))
    delete(bpy.data.objects["fo"])
    boolean(nave, box("vo", (W / 2 + T / 2, L / 2 - 3, 1.15), (T * 3, 1.1, 2.3)))
    delete(bpy.data.objects["vo"])
    bevel(nave, 0.03, 1)
    # gabled slate roof
    rise = 3.6
    slope = math.hypot(W / 2 + T + 0.5, rise)
    ang = math.atan2(rise, W / 2 + T + 0.5)
    for sx in (-1, 1):
        r = box("roof", (0, 0, 0), (slope, L + 2 * T + 0.8, 0.25), "slate")
        parts.append(posed(r, (sx * (W / 4 + T / 2 + 0.25), 0, H + rise / 2 + 0.1), (0, sx * ang, 0)))
    # gable ends (triangles)
    for sy in (-1, 1):
        bm = bmesh.new()
        hw = W / 2 + T
        y0 = sy * (L / 2 + T / 2)
        vs = [bm.verts.new(v) for v in [(-hw, y0 - T / 2, H), (hw, y0 - T / 2, H), (0, y0 - T / 2, H + rise),
                                        (-hw, y0 + T / 2, H), (hw, y0 + T / 2, H), (0, y0 + T / 2, H + rise)]]
        bm.faces.new([vs[0], vs[2], vs[1]])
        bm.faces.new([vs[3], vs[4], vs[5]])
        bm.faces.new([vs[0], vs[1], vs[4], vs[3]])
        bm.faces.new([vs[1], vs[2], vs[5], vs[4]])
        bm.faces.new([vs[2], vs[0], vs[3], vs[5]])
        parts.append(obj_from_bmesh("gable", bm, "stone_blocks"))
    # bell tower over the porch
    tw = 4.6
    ty = -(L / 2 + T + tw / 2)
    tower = box("tower", (0, ty, 9.0), (tw, tw, 18.0), "stone_blocks")
    th = box("th", (0, ty, 9.0), (tw - 1.0, tw - 1.0, 19.0))
    boolean(tower, th)
    delete(th)
    boolean(tower, box("tdoor", (0, ty - tw / 2, 1.5), (1.6, 2, 3.0)))
    delete(bpy.data.objects["tdoor"])
    boolean(tower, box("tback", (0, ty + tw / 2, 1.6), (2.4, 2, 3.2)))
    delete(bpy.data.objects["tback"])
    for (x, y) in [(0, ty - tw / 2), (0, ty + tw / 2), (-tw / 2, ty), (tw / 2, ty)]:
        c = box("belfry", (x, y, 15.6), (1.4 if y != ty else 2, 2 if y != ty else 1.4, 2.4))
        boolean(tower, c)
        delete(c)
    bevel(tower, 0.03, 1)
    parts.append(tower)
    # louvres and clock faces
    for (x, y, rz) in [(0, ty - tw / 2 + 0.25, 0), (0, ty + tw / 2 - 0.25, 0), (-tw / 2 + 0.25, ty, math.pi / 2), (tw / 2 - 0.25, ty, math.pi / 2)]:
        for k in range(5):
            l = box("louvre", (0, 0, 0), (1.35, 0.06, 0.3), "wood")
            parts.append(posed(l, (x, y, 14.7 + k * 0.42), (math.radians(35), 0, rz)))
    for (x, y, rot) in [(0, ty - tw / 2 - 0.05, (math.radians(90), 0, 0)), (-tw / 2 - 0.05, ty, (0, math.radians(90), 0)), (tw / 2 + 0.05, ty, (0, math.radians(90), 0))]:
        face = cylinder("clock", 0.9, 0.9, -0.05, 0.05, 32, "clockface")
        parts.append(posed(face, (x, y, 12.4), rot))
    # spire
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=4, radius1=tw * 0.72, radius2=0.05, depth=8.0)
    bmesh.ops.rotate(bm, verts=bm.verts, cent=(0, 0, 0), matrix=Matrix.Rotation(math.pi / 4, 3, "Z"))
    bmesh.ops.translate(bm, verts=bm.verts, vec=(0, ty, 22.0))
    parts.append(obj_from_bmesh("spire", bm, "slate"))
    parts.append(box("cross_v", (0, ty, 26.6), (0.12, 0.12, 1.4), "iron"))
    parts.append(box("cross_h", (0, ty, 26.9), (0.7, 0.12, 0.12), "iron"))
    # vestry: low annex on the right-hand side at the back
    vx = W / 2 + T + 2.0
    vest = box("vestry", (vx, L / 2 - 3, 1.6), (4.0 + T, 5.0, 3.2), "stone_blocks")
    vh = box("vh", (vx, L / 2 - 3, 1.6), (4.0 - T, 5.0 - 2 * T, 4.0))
    boolean(vest, vh)
    delete(vh)
    boolean(vest, box("vdoor", (W / 2 + T / 2, L / 2 - 3, 1.15), (T * 3, 1.1, 2.3)))
    delete(bpy.data.objects["vdoor"])
    parts.append(vest)
    parts.append(box("vroof", (vx, L / 2 - 3, 3.35), (4.6 + T, 5.6, 0.3), "slate"))
    for p in [nave] + parts:
        activate(p)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    walls = join("ChapelWalls", [nave, tower, vest] + [p for p in parts if p.name.startswith("gable")])
    detail = join("ChapelDetail", [p for p in list(bpy.context.view_layer.objects) if p != walls])
    export("chapel")


# --------------------------------------------------------------------------- trees
def trees():
    reset()
    made = []
    for v in range(3):
        import random
        rnd = random.Random(v * 7 + 1)
        h = 9.0 + v * 1.5
        trunk = cylinder(f"Pine{v}_trunk", 0.28, 0.05, 0.0, h, 10, "bark")
        layers = []
        tiers = 7
        for i in range(tiers):
            z = 2.2 + i * (h - 2.6) / tiers
            r = (1.0 - i / tiers) * (2.4 + rnd.uniform(-0.3, 0.3)) + 0.35
            bm = bmesh.new()
            bmesh.ops.create_cone(bm, cap_ends=True, segments=9, radius1=r, radius2=0.05, depth=2.2)
            for vert in bm.verts:
                if vert.co.z < 0:
                    vert.co.z += rnd.uniform(-0.35, 0.15)
                    vert.co.x *= rnd.uniform(0.8, 1.2)
                    vert.co.y *= rnd.uniform(0.8, 1.2)
            bmesh.ops.translate(bm, verts=bm.verts, vec=(rnd.uniform(-0.1, 0.1), rnd.uniform(-0.1, 0.1), z + 1.1))
            bmesh.ops.rotate(bm, verts=bm.verts, cent=(0, 0, 0), matrix=Matrix.Rotation(rnd.uniform(0, 6.28), 3, "Z"))
            layers.append(obj_from_bmesh("tier", bm, "pine"))
        foliage = join(f"Pine{v}_foliage", layers)
        made += [trunk, foliage]
    # dead trees from skin skeletons
    for v in range(2):
        import random
        rnd = random.Random(100 + v)
        verts = [(0, 0, 0), (0.1, 0, 3.0), (0.0, 0.2, 6.0), (0.2, 0.1, 8.5)]
        edges = [(0, 1), (1, 2), (2, 3)]
        radii = [0.35, 0.25, 0.16, 0.05]
        for b in range(6):
            base = rnd.choice([1, 2, 2, 3])
            bx, by, bz = verts[base]
            a = rnd.uniform(0, 6.28)
            ln = rnd.uniform(1.5, 3.2)
            tip = (bx + math.cos(a) * ln, by + math.sin(a) * ln, bz + rnd.uniform(0.5, 2.0))
            mid = ((bx + tip[0]) / 2 + rnd.uniform(-0.3, 0.3), (by + tip[1]) / 2, (bz + tip[2]) / 2 + 0.3)
            verts += [mid, tip]
            edges += [(base, len(verts) - 2), (len(verts) - 2, len(verts) - 1)]
            radii += [0.08, 0.03]
        made.append(skin_object(f"Dead{v}", verts, edges, radii, "bark", 1))
    for o in made:
        o.location.x += 0  # each tree is its own object at the origin
    export("trees")


# --------------------------------------------------------------------------- the Kell creature
def kell():
    """A gaunt bat-like man. Parts are separate so the game can animate them:
    KellBody (torso, hips, bent legs), KellHead (skull, ears, snout, jaw),
    KellWingL / KellWingR (arm, elongated fingers, membrane) with origins at the shoulders."""
    reset()
    # body skeleton: pelvis -> spine -> chest -> neck base; legs bent backward like a bat's
    verts = [(0, 0, 1.0), (0, 0.05, 1.3), (0, 0.12, 1.65), (0, 0.18, 1.85),
             (-0.14, 0, 0.95), (-0.18, -0.25, 0.55), (-0.15, 0.15, 0.12), (-0.15, -0.05, 0.0),
             (0.14, 0, 0.95), (0.18, -0.25, 0.55), (0.15, 0.15, 0.12), (0.15, -0.05, 0.0),
             (-0.2, 0.15, 1.72), (0.2, 0.15, 1.72)]
    edges = [(0, 1), (1, 2), (2, 3), (0, 4), (4, 5), (5, 6), (6, 7), (0, 8), (8, 9), (9, 10), (10, 11), (2, 12), (2, 13)]
    radii = [0.17, 0.15, 0.2, 0.09, 0.11, 0.07, 0.05, 0.04, 0.11, 0.07, 0.05, 0.04, 0.1, 0.1]
    body = skin_object("KellBody", verts, edges, radii, "skin", 2)
    # visible ribs: thin ridges across the chest
    ribs = []
    for i in range(4):
        z = 1.35 + i * 0.09
        bpy.ops.mesh.primitive_torus_add(major_radius=0.17 - abs(i - 1.5) * 0.01, minor_radius=0.018, major_segments=16, minor_segments=4, location=(0, 0.1, z))
        t = bpy.context.active_object
        t.scale = (1.0, 0.8, 1.0)
        t.data.materials.append(material("skin"))
        ribs.append(t)
    body = join("KellBody", [body] + ribs)

    # head: skull with a pushed-forward snout, huge ears, lower jaw
    hverts = [(0, 0, 0), (0, -0.02, 0.14), (0, -0.16, 0.08), (0, -0.25, 0.04),
              (-0.08, 0.0, 0.17), (-0.2, 0.05, 0.46), (0.08, 0.0, 0.17), (0.2, 0.05, 0.46),
              (0, -0.1, -0.03), (0, -0.22, -0.02)]
    hedges = [(0, 1), (1, 2), (2, 3), (1, 4), (4, 5), (1, 6), (6, 7), (0, 8), (8, 9)]
    hradii = [0.07, 0.11, 0.07, 0.035, (0.04, 0.015), (0.09, 0.012), (0.04, 0.015), (0.09, 0.012), 0.045, 0.025]
    head = skin_object("KellHead", hverts, hedges, hradii, "skin", 2)
    eyes = []
    for sx in (-1, 1):
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.022, location=(sx * 0.055, -0.13, 0.15))
        e = bpy.context.active_object
        e.data.materials.append(material("eye"))
        eyes.append(e)
    teeth = []
    for i in range(6):
        x = -0.04 + i * 0.016
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, segments=4, radius1=0.006, radius2=0.0, depth=0.035)
        bmesh.ops.rotate(bm, verts=bm.verts, cent=(0, 0, 0), matrix=Matrix.Rotation(math.pi, 3, "X"))
        bmesh.ops.translate(bm, verts=bm.verts, vec=(x, -0.235, 0.0))
        teeth.append(obj_from_bmesh("tooth", bm, "bone"))
    head = join("KellHead", [head] + eyes + teeth)

    # wings: upper arm, forearm, three long fingers and a thumb claw; membrane between
    wings = []
    for side, sx in (("L", -1), ("R", 1)):
        shoulder = (0, 0, 0)
        elbow = (sx * 0.55, 0.15, -0.25)
        wrist = (sx * 1.1, 0.0, 0.05)
        f1 = (sx * 1.7, 0.1, 0.75)
        f2 = (sx * 2.3, 0.1, 0.25)
        f3 = (sx * 2.0, 0.05, -0.55)
        thumb = (sx * 1.2, -0.1, 0.25)
        verts = [shoulder, elbow, wrist, f1, f2, f3, thumb]
        edges = [(0, 1), (1, 2), (2, 3), (2, 4), (2, 5), (2, 6)]
        radii = [0.07, 0.05, 0.04, 0.012, 0.012, 0.012, 0.02]
        arm = skin_object("arm" + side, verts, edges, radii, "skin", 1)
        # membrane: fan of quads from fingers back to the body flank, ragged trailing edge
        bm = bmesh.new()
        flank_top = (sx * 0.05, 0.1, -0.15)
        flank_low = (sx * 0.1, 0.12, -0.95)
        ring = [shoulder, elbow, wrist, f1, f2, f3, flank_low, flank_top]
        center = Vector((sx * 0.9, 0.1, -0.1))
        vs = [bm.verts.new(p) for p in ring]
        c = bm.verts.new(center)
        for i in range(len(vs)):
            a, b = vs[i], vs[(i + 1) % len(vs)]
            if (i, (i + 1) % len(vs)) in [(2, 3)]:
                continue
            bm.faces.new([c, a, b])
        # sag the membrane between finger tips
        for v in bm.verts:
            v.co.y += 0.08 * math.sin(abs(v.co.x) * 2.5)
        bmesh.ops.subdivide_edges(bm, edges=bm.edges[:], cuts=2, use_grid_fill=True)
        mem = obj_from_bmesh("mem" + side, bm, "membrane")
        sol = mem.modifiers.new("sol", "SOLIDIFY")
        sol.thickness = 0.008
        apply_mods(mem)
        wing = join("KellWing" + side, [arm, mem])
        wings.append(wing)
    # position parts in the rest pose; origins stay at joints for animation in Godot
    head.location = (0, 0.22, 1.98)
    wings[0].location = (-0.2, 0.15, 1.72)
    wings[1].location = (0.2, 0.15, 1.72)
    export("kell")


if __name__ == "__main__":
    which = sys.argv[1:] or ["lighthouse", "chapel", "trees", "kell"]
    for w in which:
        globals()[w]()
