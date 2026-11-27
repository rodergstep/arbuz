"""Builds the game's toy-like low-poly models in Blender and exports them as .glb.

Run:  /Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup \
        --python tools/blender/build_models.py
Writes assets/models/{tygrytsa,car_hatchback,car_jeep,car_van}.glb.

Everything is original and built from primitives: rounded, chunky, readable shapes for a
three-year-old. Colours are plain material base colours; the game replaces every material with
its shared painted shader (game/art/model_painter.gd), so the look stays consistent.
Models face Blender +Y (= Godot -Z, forward). Moving parts are separate objects whose origin is
the joint (shoulder, hip, tail base) so the game can animate them by rotation.
"""
import math
import os

import bpy
from mathutils import Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "models")

ORANGE = (0.94, 0.52, 0.14, 1)
CREAM = (0.98, 0.95, 0.88, 1)
DARK = (0.16, 0.11, 0.10, 1)
SHIRT = (0.98, 0.97, 0.93, 1)
EMBROIDERY = (0.80, 0.16, 0.20, 1)
EMBROIDERY_DARK = (0.20, 0.12, 0.12, 1)
PINK = (0.85, 0.45, 0.50, 1)
TYRE = (0.18, 0.18, 0.20, 1)
GLASS = (0.72, 0.86, 0.96, 1)
LIGHT = (1.0, 0.93, 0.6, 1)
CHROME = (0.78, 0.80, 0.84, 1)
CAR_GLASS = (0.30, 0.48, 0.68, 1)

_materials = {}


def to_linear(c):
    # Colours above are picked as sRGB (as on screen); glTF stores linear base colours.
    return tuple((x / 12.92) if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c[:3]) + (c[3],)


def mat(name, color):
    color = to_linear(color)
    if name not in _materials:
        m = bpy.data.materials.new(name)
        m.diffuse_color = color
        m.use_nodes = True
        bsdf = m.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = 1.0
        _materials[name] = m
    return _materials[name]


def reset():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    for block in (bpy.data.meshes, bpy.data.materials):
        for item in list(block):
            block.remove(item)
    _materials.clear()


def finish(obj, name, material, parent=None, smooth=True, bevel=0.0):
    obj.name = name
    obj.data.materials.append(material)
    if smooth:
        bpy.ops.object.shade_smooth()
    if bevel > 0:
        mod = obj.modifiers.new("bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 3
    if parent is not None:
        set_parent(obj, parent)
    return obj


def set_parent(obj, parent):
    # Keep the object where it was built (world space) while making it a child of the joint.
    bpy.context.view_layer.update()
    obj.parent = parent
    obj.matrix_parent_inverse = parent.matrix_world.inverted()


def sphere(name, loc, scale, material, parent=None, segs=20):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segs, ring_count=max(8, segs // 2), location=loc)
    o = bpy.context.active_object
    o.scale = scale
    return finish(o, name, material, parent)


def box(name, loc, size, material, parent=None, bevel=0.03, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(location=loc, rotation=rot)
    o = bpy.context.active_object
    o.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    bpy.ops.object.transform_apply(scale=True)
    return finish(o, name, material, parent, smooth=bevel > 0, bevel=bevel)


def cylinder(name, loc, radius, depth, material, parent=None, rot=(0, 0, 0), verts=20):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=radius, depth=depth, location=loc, rotation=rot)
    o = bpy.context.active_object
    return finish(o, name, material, parent)


def empty(name, loc, parent=None):
    bpy.ops.object.empty_add(location=loc)
    e = bpy.context.active_object
    e.name = name
    if parent is not None:
        set_parent(e, parent)
    return e


def limb(name, joint, length, radius, material, parent, end_material=None):
    """A limb whose origin is the joint; it hangs down from there."""
    pivot = empty(name, joint, parent)
    cylinder(name + "_mesh", (joint[0], joint[1], joint[2] - length / 2), radius, length, material, pivot)
    sphere(name + "_end", (joint[0], joint[1], joint[2] - length), (radius * 1.15,) * 3, end_material or material, pivot, 14)
    return pivot


def export(name):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_apply=True, export_yup=True)
    print("wrote", path)


def build_tygrytsa():
    """Tygrytsa: an original, round, cheerful tigress in a vyshyvanka. About 1.25 m tall.

    Toddler-friendly proportions: a big round head with large shiny eyes, fluffy white cheeks,
    stripes on her head, back, arms and legs, a ringed tail, and an embroidered shirt with a
    red-and-black diamond band at the hem, the collar and the cuffs. Joints: LegL/LegR (hips),
    ArmL/ArmR (shoulders), Head (neck), Tail (tail base).
    """
    reset()
    o, c, d = mat("fur", ORANGE), mat("cream", CREAM), mat("stripe", DARK)
    s, e = mat("shirt", SHIRT), mat("embroidery", EMBROIDERY)
    ed, pink = mat("embroidery_dark", EMBROIDERY_DARK), mat("nose", PINK)
    white = mat("eye_white", (1.0, 1.0, 1.0, 1))
    root = empty("Tygrytsa", (0, 0, 0))
    # Legs (hip joints): short and sturdy, a stripe each, round cream paws.
    for side, x in (("L", -0.12), ("R", 0.12)):
        leg = limb("Leg" + side, (x, 0, 0.3), 0.2, 0.09, o, root, c)
        box("LegStripe" + side, (x, 0.0, 0.2), (0.19, 0.19, 0.035), d, leg, 0.01)
        sphere("Paw" + side, (x, 0.05, 0.06), (0.11, 0.14, 0.07), c, leg, 12)
    body = empty("Body", (0, 0, 0.3), root)
    # A round tummy under the shirt.
    sphere("Belly", (0, 0, 0.42), (0.27, 0.25, 0.22), o, body)
    sphere("Shirt", (0, 0, 0.55), (0.28, 0.26, 0.24), s, body)
    # Embroidered band at the hem: alternating red and black diamonds all the way round.
    for i in range(14):
        a = math.tau * i / 14
        box("Hem%d" % i, (math.sin(a) * 0.27, math.cos(a) * 0.25, 0.42), (0.05, 0.02, 0.05), e if i % 2 == 0 else ed, body, 0.0, (0, math.radians(45), -a))
    bpy.ops.mesh.primitive_torus_add(location=(0, 0, 0.76), major_radius=0.14, minor_radius=0.03)
    finish(bpy.context.active_object, "Collar", e, body)
    for i, z in enumerate((0.71, 0.64, 0.57, 0.5)):
        box("Diamond%d" % i, (0, 0.255, z), (0.05, 0.025, 0.05), e if i % 2 == 0 else ed, body, 0.0, (0, math.radians(45), 0))
    for i, z in enumerate((0.5, 0.62)):
        box("BackStripe%d" % i, (0, -0.25, z), (0.16, 0.03, 0.035), d, body, 0.01)
    # Arms (shoulder joints): shirt sleeves with embroidered cuffs, striped fur hands.
    for side, x in (("L", -0.27), ("R", 0.27)):
        arm = limb("Arm" + side, (x, 0, 0.72), 0.27, 0.07, s, root, o)
        bpy.ops.mesh.primitive_torus_add(location=(x, 0, 0.53), major_radius=0.072, minor_radius=0.022)
        finish(bpy.context.active_object, "Cuff" + side, e, arm)
        box("HandStripe" + side, (x, 0.0, 0.47), (0.13, 0.13, 0.025), d, arm, 0.01)
    # Head: big and round (toddler proportions).
    head = empty("Head", (0, 0, 0.82), root)
    sphere("Skull", (0, 0, 1.0), (0.34, 0.31, 0.3), o, head, 28)
    for x in (-1, 1):
        sphere("Cheek%+d" % x, (x * 0.16, 0.2, 0.9), (0.13, 0.1, 0.1), c, head, 16)
        sphere("CheekTuft%+d" % x, (x * 0.31, 0.05, 0.9), (0.07, 0.06, 0.05), c, head, 10)
    sphere("Muzzle", (0, 0.25, 0.92), (0.12, 0.08, 0.08), c, head, 16)
    sphere("Nose", (0, 0.32, 0.96), (0.05, 0.03, 0.035), pink, head, 12)
    sphere("Mouth", (0, 0.31, 0.87), (0.03, 0.01, 0.012), d, head, 8)
    # Big eyes: white, a dark iris, two shines.
    for x in (-0.12, 0.12):
        sphere("EyeWhite%+.0f" % (x * 100), (x, 0.25, 1.05), (0.075, 0.04, 0.085), white, head, 16)
        sphere("Eye%+.0f" % (x * 100), (x, 0.285, 1.04), (0.055, 0.02, 0.065), d, head, 14)
        sphere("Shine%+.0f" % (x * 100), (x + 0.02, 0.305, 1.07), (0.018,) * 3, white, head, 8)
        sphere("Shine2%+.0f" % (x * 100), (x - 0.015, 0.303, 1.02), (0.009,) * 3, white, head, 6)
        box("Brow%+.0f" % (x * 100), (x, 0.27, 1.16), (0.07, 0.02, 0.018), d, head, 0.005, (0, math.radians(-12 if x < 0 else 12), 0))
    # Round ears with pink inside.
    for x in (-0.22, 0.22):
        ear = sphere("Ear%+.0f" % (x * 100), (x, 0.0, 1.27), (0.1, 0.06, 0.1), o, head, 16)
        sphere("EarIn%+.0f" % (x * 100), (x, 0.035, 1.27), (0.06, 0.02, 0.06), pink, ear, 10)
    # Forehead stripes and side stripes.
    for i, x in enumerate((-0.08, 0.0, 0.08)):
        box("HeadStripe%d" % i, (x, 0.2, 1.24), (0.028, 0.08, 0.1 if i == 1 else 0.07), d, head, 0.008, (math.radians(-35), 0, 0))
    for x in (-1, 1):
        for k in range(2):
            box("SideStripe%+d%d" % (x, k), (x * 0.32, 0.0, 1.0 + k * 0.08), (0.03, 0.12, 0.03), d, head, 0.008, (0, 0, math.radians(20 * x)))
    # Tail: a curve of four pieces from the tail base, dark rings, dark tip.
    tail = empty("Tail", (0, -0.24, 0.4), root)
    for i in range(4):
        z = 0.4 + 0.08 * i
        y = -0.28 - 0.09 * i
        cylinder("Tail%d" % i, (0, y, z), 0.045, 0.14, o if i % 2 == 0 else d, tail, (math.radians(-60 + 18 * i), 0, 0), 12)
    sphere("TailTip", (0, -0.62, 0.72), (0.055,) * 3, d, tail, 10)
    export("tygrytsa")


def wheel(name, loc, radius, width, parent):
    w = cylinder(name, loc, radius, width, mat("tyre", TYRE), parent, (0, math.radians(90), 0), 22)
    cylinder(name + "_hub", (loc[0] + math.copysign(width / 2, loc[0]), loc[1], loc[2]), radius * 0.45, 0.02, mat("hub", CHROME), parent, (0, math.radians(90), 0), 16)
    return w


def lights(parent, y, z, x=0.55):
    for sx in (-x, x):
        sphere("Light%+.0f" % (sx * 10), (sx, y, z), (0.12, 0.05, 0.1), mat("light", LIGHT), parent, 12)


def car_body(name, profile, width, material, parent, bevel=0.16):
    """A car body from its side silhouette: profile is (y, z) points around the outline
    (y forward), pushed out to `width`, then rounded with a bevel and smoothed."""
    import bmesh
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    verts = [bm.verts.new((-width / 2, y, z)) for y, z in profile]
    face = bm.faces.new(verts)
    ext = bmesh.ops.extrude_face_region(bm, geom=[face])
    for v in [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]:
        v.co.x += width
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    mod = obj.modifiers.new("bevel", "BEVEL")
    mod.width = bevel
    mod.segments = 5
    mod.limit_method = "NONE"
    bpy.ops.object.modifier_apply(modifier=mod.name)
    sub = obj.modifiers.new("sub", "SUBSURF")
    sub.levels = 2
    bpy.ops.object.modifier_apply(modifier=sub.name)
    obj.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    set_parent(obj, parent)
    return obj


def car_wheel(name, loc, radius, width, parent, rim_colour=(0.92, 0.92, 0.94, 1)):
    """A chunky tyre with a rounded rim and five little spokes."""
    side = 1 if loc[0] > 0 else -1
    bpy.ops.mesh.primitive_torus_add(location=loc, major_radius=radius * 0.72, minor_radius=radius * 0.3, rotation=(0, math.radians(90), 0), major_segments=28, minor_segments=12)
    t = bpy.context.active_object
    t.scale = (1.0, 1.0, width / (radius * 0.6))
    finish(t, name, mat("tyre", TYRE), parent)
    rim = cylinder(name + "_rim", (loc[0] + side * width * 0.12, loc[1], loc[2]), radius * 0.5, width * 0.7, mat("rim", rim_colour), parent, (0, math.radians(90), 0), 20)
    sphere(name + "_cap", (loc[0] + side * width * 0.45, loc[1], loc[2]), (0.05, radius * 0.16, radius * 0.16), mat("hub", CHROME), parent, 10)
    for i in range(5):
        a = math.tau * i / 5
        box(name + "_spoke%d" % i, (loc[0] + side * width * 0.42, loc[1] + math.cos(a) * radius * 0.28, loc[2] + math.sin(a) * radius * 0.28), (0.03, radius * 0.08, radius * 0.38), mat("hub", CHROME), parent, 0.005, (a, 0, 0))


def car_details(root, body_paint, length_front, length_rear, belt, width, light_z, glass_box):
    """Headlights with chrome rings, taillights, grille, bumpers, mirrors, door line and handles,
    a number plate; glass_box = (y_min, y_max, z_min, z_max) where the body is painted as glass."""
    for x in (-width * 0.3, width * 0.3):
        cylinder("Headlight%+.0f" % (x * 10), (x, length_front - 0.02, light_z), 0.15, 0.08, mat("headlight", LIGHT), root, (math.radians(90), 0, 0), 20)
        bpy.ops.mesh.primitive_torus_add(location=(x, length_front + 0.01, light_z), major_radius=0.15, minor_radius=0.025, rotation=(math.radians(90), 0, 0))
        finish(bpy.context.active_object, "HeadRing%+.0f" % (x * 10), mat("chrome", CHROME), root)
        box("Taillight%+.0f" % (x * 10), (x * 1.05, length_rear + 0.02, light_z + 0.05), (0.26, 0.06, 0.14), mat("taillight", (0.9, 0.18, 0.18, 1)), root, 0.04)
    box("Grille", (0, length_front - 0.01, light_z - 0.18), (width * 0.38, 0.05, 0.12), mat("grille", (0.22, 0.22, 0.25, 1)), root, 0.04)
    for y, n in ((length_front + 0.02, "Front"), (length_rear - 0.02, "Rear")):
        box("Bumper" + n, (0, y, 0.38), (width * 0.92, 0.18, 0.18), mat("bumper", (0.30, 0.30, 0.33, 1)), root, 0.08)
    box("Plate", (0, length_front + 0.12, 0.38), (0.4, 0.02, 0.12), mat("plate", (0.98, 0.95, 0.75, 1)), root, 0.01)
    for side in (-1, 1):
        x = side * (width / 2 + 0.01)
        box("DoorLine%+d" % side, (x, glass_box[0] + 0.55, belt - 0.25), (0.01, 0.015, 0.5), mat("doorline", (0.25, 0.15, 0.15, 1)), root, 0.0)
        box("Handle%+d" % side, (x + side * 0.01, glass_box[0] + 0.35, belt - 0.08), (0.02, 0.16, 0.04), mat("chrome", CHROME), root, 0.01)
        blob("Mirror%+d" % side, [((side * (width / 2 + 0.05), glass_box[1] - 0.05, belt + 0.04), 0.13, (1.0, 0.6, 0.6))], body_paint, root)


def build_hatchback():
    """Our family car: a round, friendly hatchback: a smooth lower body, a glass cabin with a
    painted roof and pillars, round headlights with chrome rings, chunky wheels with spoked rims,
    mirrors, bumpers and a number plate."""
    reset()
    root = empty("CarHatchback", (0, 0, 0))
    body_paint = mat("paint", (0.90, 0.32, 0.28, 1))
    car_body("Body", [(-1.5, 0.28), (1.55, 0.28), (1.62, 0.58), (1.45, 0.86), (0.85, 1.02), (-1.42, 1.06), (-1.58, 0.7)], 1.72, body_paint, root)
    car_body("Windows", [(-1.34, 0.98), (0.84, 0.98), (0.2, 1.42), (-0.94, 1.44)], 1.58, mat("car_glass", CAR_GLASS), root, 0.06)
    car_body("Roof", [(-1.0, 1.36), (0.28, 1.36), (0.18, 1.5), (-0.95, 1.52)], 1.64, body_paint, root, 0.05)
    for side in (-1, 1):
        box("PillarB%+d" % side, (side * 0.77, -0.34, 1.2), (0.05, 0.12, 0.42), body_paint, root, 0.01)
    for x, y in ((-0.86, 1.0), (0.86, 1.0), (-0.86, -0.95), (0.86, -0.95)):
        car_wheel("Wheel%+.0f%+.0f" % (x, y), (x, y, 0.36), 0.36, 0.3, root)
    car_details(root, body_paint, 1.62, -1.58, 1.0, 1.72, 0.7, (-1.4, 0.8))
    export("car_hatchback")


def build_jeep():
    """A sturdy little jeep: a tall boxy body, a dark roof, big chunky wheels, a spare wheel
    on the back door, round headlights."""
    reset()
    root = empty("CarJeep", (0, 0, 0))
    body_paint = mat("paint", (0.36, 0.60, 0.38, 1))
    car_body("Body", [(-1.55, 0.42), (1.55, 0.42), (1.64, 0.78), (1.56, 1.06), (0.72, 1.12), (-1.55, 1.14), (-1.62, 0.8)], 1.82, body_paint, root, 0.12)
    car_body("Windows", [(-1.42, 1.06), (0.7, 1.06), (0.48, 1.62), (-1.42, 1.64)], 1.66, mat("car_glass", CAR_GLASS), root, 0.05)
    car_body("Roof", [(-1.47, 1.56), (0.54, 1.56), (0.48, 1.7), (-1.47, 1.72)], 1.74, mat("jeep_roof", (0.22, 0.24, 0.24, 1)), root, 0.05)
    for side in (-1, 1):
        box("PillarB%+d" % side, (side * 0.81, -0.4, 1.32), (0.05, 0.12, 0.52), body_paint, root, 0.01)
    for x, y in ((-0.9, 1.0), (0.9, 1.0), (-0.9, -0.98), (0.9, -0.98)):
        car_wheel("Wheel%+.0f%+.0f" % (x, y), (x, y, 0.45), 0.45, 0.36, root, (0.95, 0.82, 0.3, 1))
    # The spare wheel on the back door.
    bpy.ops.mesh.primitive_torus_add(location=(0, -1.75, 0.95), major_radius=0.27, minor_radius=0.12, rotation=(math.radians(90), 0, 0), major_segments=24, minor_segments=10)
    finish(bpy.context.active_object, "Spare", mat("tyre", TYRE), root)
    cylinder("SpareRim", (0, -1.76, 0.95), 0.18, 0.18, mat("rim", (0.95, 0.82, 0.3, 1)), root, (math.radians(90), 0, 0), 18)
    car_details(root, body_paint, 1.64, -1.62, 1.12, 1.82, 0.82, (-1.4, 0.68))
    export("car_jeep")


def build_van():
    """A cheerful little van: tall and round, big windows, a cream stripe, chunky wheels."""
    reset()
    root = empty("CarVan", (0, 0, 0))
    body_paint = mat("paint", (0.98, 0.78, 0.28, 1))
    body = car_body("Body", [(-1.62, 0.3), (1.55, 0.3), (1.66, 0.62), (1.6, 0.96), (1.12, 1.12), (-1.62, 1.12)], 1.8, body_paint, root)
    paint(body, mat("stripe_cream", CREAM), lambda p: 0.66 < p.z < 0.8)
    car_body("Windows", [(-1.5, 1.04), (1.1, 1.04), (0.78, 1.66), (-1.5, 1.7)], 1.66, mat("car_glass", CAR_GLASS), root, 0.06)
    car_body("Roof", [(-1.56, 1.62), (0.84, 1.62), (0.76, 1.84), (-1.56, 1.88)], 1.76, body_paint, root, 0.06)
    for side in (-1, 1):
        for y in (-0.55, 0.35):
            box("Pillar%+.0f%+d" % (y * 10, side), (side * 0.81, y, 1.35), (0.05, 0.12, 0.6), body_paint, root, 0.01)
    for x, y in ((-0.88, 1.0), (0.88, 1.0), (-0.88, -1.0), (0.88, -1.0)):
        car_wheel("Wheel%+.0f%+.0f" % (x, y), (x, y, 0.37), 0.37, 0.3, root)
    car_details(root, body_paint, 1.65, -1.64, 1.1, 1.8, 0.72, (-1.5, 1.05))
    export("car_van")


def build_hata():
    """A Ukrainian hata: white walls, a soft thatched roof, blue shutters, flower boxes. 5 x 4.5 m."""
    reset()
    root = empty("Hata", (0, 0, 0))
    box("Walls", (0, 0, 1.4), (5.0, 4.4, 2.8), mat("wall", WALL), root, 0.12)
    box("Plinth", (0, 0, 0.12), (5.2, 4.6, 0.24), mat("plinth", (0.55, 0.42, 0.34, 1)), root, 0.05)
    # Thatched roof: a deep rounded hip, overhanging
    bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=4.3, radius2=0.6, depth=2.2, location=(0, 0, 3.85), rotation=(0, 0, math.radians(45)))
    roof = bpy.context.active_object
    roof.scale = (1.0, 0.92, 1.0)
    finish(roof, "Roof", mat("thatch", THATCH), root, smooth=True, bevel=0.25)
    # Door (front faces +Y = Godot -Z) and windows with blue shutters and flower boxes
    box("Door", (0, 2.21, 1.0), (0.9, 0.08, 1.9), mat("wood", WOOD), root, 0.04)
    for x in (-1.6, 1.6):
        box("Window%+.0f" % x, (x, 2.21, 1.6), (0.8, 0.06, 0.8), mat("glass", GLASS), root, 0.03)
        for sx in (-0.55, 0.55):
            box("Shutter%+.0f%+.0f" % (x, sx), (x + sx, 2.23, 1.6), (0.3, 0.06, 0.85), mat("shutter", SHUTTER), root, 0.03)
        box("FlowerBox%+.0f" % x, (x, 2.33, 1.12), (0.9, 0.22, 0.18), mat("wood", WOOD), root, 0.03)
        for i, fx in enumerate((-0.3, 0.0, 0.3)):
            sphere("Flower%+.0f%d" % (x, i), (x + fx, 2.36, 1.28), (0.09,) * 3, mat("flower_red", FLOWER_RED) if i != 1 else mat("petal", PETAL), root, 10)
    box("Chimney", (1.2, -0.8, 4.4), (0.5, 0.5, 1.1), mat("wall", WALL), root, 0.05)
    export("hata")


def build_tree():
    """A round, soft tree: three leafy balls on a short trunk. About 4.5 m."""
    reset()
    root = empty("Tree", (0, 0, 0))
    cylinder("Trunk", (0, 0, 1.0), 0.22, 2.0, mat("wood", WOOD), root, verts=10)
    crown = empty("Crown", (0, 0, 2.2), root)
    for x, y, z, r in ((0, 0, 3.0, 1.3), (0.8, 0.3, 2.6, 0.9), (-0.7, -0.4, 2.7, 0.95), (0.1, -0.6, 3.6, 0.8)):
        sphere("Leaves%+.0f%+.0f" % (x * 10, y * 10), (x, y, z), (r, r, r * 0.92), mat("leaf", LEAF), crown, 16)
    export("tree")


def build_sunflower():
    """A tall sunflower with a big face. About 1.9 m."""
    reset()
    root = empty("Sunflower", (0, 0, 0))
    cylinder("Stem", (0, 0, 0.9), 0.04, 1.8, mat("stem", STEM), root, verts=8)
    for z, side in ((0.7, 1), (1.15, -1)):
        sphere("Leaf%d" % side, (0.18 * side, 0, z), (0.2, 0.06, 0.09), mat("stem", STEM), root, 10)
    head = empty("Head", (0, 0.05, 1.85), root)
    cylinder("Face", (0, 0.06, 1.85), 0.2, 0.06, mat("seeds", SEEDS), head, (math.radians(90), 0, 0), 16)
    for i in range(12):
        a = math.tau * i / 12
        sphere("Petal%d" % i, (math.cos(a) * 0.28, 0.04, 1.85 + math.sin(a) * 0.28), (0.1, 0.03, 0.06), mat("petal", PETAL), head, 8)
        bpy.context.active_object.rotation_euler = (0, -a, 0)
    export("sunflower")


def build_fence():
    """A wicker fence (tyn) section, 2 m long, 0.9 m tall."""
    reset()
    root = empty("Fence", (0, 0, 0))
    for x in (-1.0, -0.5, 0.0, 0.5, 1.0):
        cylinder("Post%+.0f" % (x * 10), (x, 0, 0.45), 0.04, 0.95, mat("wood", WOOD), root, verts=8)
    for z in (0.25, 0.45, 0.65):
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.035, depth=2.1, location=(0, 0, z), rotation=(0, math.radians(90), 0))
        finish(bpy.context.active_object, "Weave%.0f" % (z * 100), mat("wicker", (0.70, 0.55, 0.36, 1)), root, bevel=0.0)
    export("fence")


def build_well():
    """A village well with a little roof and a bucket."""
    reset()
    root = empty("Well", (0, 0, 0))
    cylinder("Ring", (0, 0, 0.4), 0.7, 0.8, mat("stone", STONE), root, verts=16)
    cylinder("Water", (0, 0, 0.75), 0.6, 0.05, mat("water", (0.35, 0.6, 0.85, 1)), root, verts=16)
    for x in (-0.65, 0.65):
        box("Post%+.0f" % x, (x, 0, 1.2), (0.12, 0.12, 1.6), mat("wood", WOOD), root, 0.02)
    bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=1.1, radius2=0.05, depth=0.7, location=(0, 0, 2.2), rotation=(0, 0, math.radians(45)))
    finish(bpy.context.active_object, "Roof", mat("thatch", THATCH), root, bevel=0.05)
    cylinder("Bucket", (0, 0, 1.25), 0.14, 0.22, mat("wood", WOOD), root, verts=12)
    export("well")


def build_ferry():
    """A small river ferry: a flat deck that fits the car, railings, a little cabin, a funnel."""
    reset()
    root = empty("Ferry", (0, 0, 0))
    box("Hull", (0, 0, 0.25), (3.2, 5.6, 0.6), mat("hull", (0.86, 0.32, 0.30, 1)), root, 0.2)
    box("Deck", (0, 0, 0.57), (2.9, 5.3, 0.06), mat("deck", (0.72, 0.58, 0.40, 1)), root, 0.02)
    for x in (-1.5, 1.5):
        box("Rail%+.0f" % x, (x, 0, 0.85), (0.06, 5.2, 0.06), mat("rail", (0.97, 0.96, 0.92, 1)), root, 0.0)
        for y in (-2.4, -1.2, 0.0, 1.2, 2.4):
            cylinder("Post%+.0f%+.0f" % (x, y), (x, y, 0.72), 0.03, 0.3, mat("rail", (0.97, 0.96, 0.92, 1)), root, verts=6)
    box("Cabin", (0, -2.25, 1.2), (1.4, 0.9, 1.2), mat("cabin", (0.97, 0.96, 0.92, 1)), root, 0.12)
    box("CabinWindow", (0, -1.79, 1.35), (1.0, 0.05, 0.4), mat("glass", GLASS), root, 0.03)
    cylinder("Funnel", (0, -2.4, 2.1), 0.2, 0.7, mat("funnel", (0.25, 0.38, 0.66, 1)), root, verts=14)
    export("ferry")


BRICK = (0.74, 0.36, 0.28, 1)
SLATE = (0.42, 0.45, 0.52, 1)
TRIM = (0.97, 0.96, 0.93, 1)


def gable_roof(name, loc, width, depth, height, material, parent):
    """A pitched roof along X: a triangular prism."""
    bpy.ops.mesh.primitive_cone_add(vertices=3, radius1=1.0, radius2=1.0, depth=width, location=loc, rotation=(0, math.radians(90), 0))
    roof = bpy.context.active_object
    roof.scale = (height, depth / 1.6, 1.0)
    roof.rotation_euler = (math.radians(90), math.radians(90), 0)
    roof.rotation_euler = (0, math.radians(90), math.radians(90))
    return finish(roof, name, material, parent, smooth=False, bevel=0.05)


def english_windows(root, front_y, xs, zs):
    for x in xs:
        for z in zs:
            box("Frame%+.0f%+.0f" % (x * 10, z * 10), (x, front_y, z), (0.8, 0.06, 0.95), mat("trim", TRIM), root, 0.02)
            box("Pane%+.0f%+.0f" % (x * 10, z * 10), (x, front_y + 0.02, z), (0.62, 0.05, 0.76), mat("glass", GLASS), root, 0.01)


def build_english_house():
    """A red-brick English house: two storeys, slate roof, white window frames, a chimney. 5 x 4.5 m."""
    reset()
    root = empty("EnglishHouse", (0, 0, 0))
    box("Walls", (0, 0, 2.1), (5.0, 4.4, 4.2), mat("brick", BRICK), root, 0.08)
    bpy.ops.mesh.primitive_cube_add(location=(0, 0, 4.9))
    roof = bpy.context.active_object
    roof.scale = (2.75, 2.4, 0.01)
    bpy.ops.object.transform_apply(scale=True)
    finish(roof, "RoofBase", mat("slate", SLATE), root, smooth=False)
    for sy in (-1, 1):
        box("RoofSide%+d" % sy, (0, sy * 1.15, 5.05), (5.5, 2.6, 0.18), mat("slate", SLATE), root, 0.04, (math.radians(-35 * sy), 0, 0))
    box("Chimney", (1.6, -0.6, 5.7), (0.6, 0.6, 1.4), mat("brick", BRICK), root, 0.04)
    box("Door", (0, 2.22, 1.0), (0.95, 0.08, 2.0), mat("door_blue", (0.22, 0.36, 0.62, 1)), root, 0.04)
    box("Step", (0, 2.45, 0.08), (1.4, 0.5, 0.16), mat("trim", TRIM), root, 0.02)
    english_windows(root, 2.21, (-1.6, 1.6), (1.3,))
    english_windows(root, 2.21, (-1.6, 0.0, 1.6), (3.2,))
    export("english_house")


def build_shop(name, awning):
    """A small English shop: brick, a big window, a striped awning in the shop's colour."""
    reset()
    root = empty("Shop", (0, 0, 0))
    box("Walls", (0, 0, 2.0), (6.0, 5.0, 4.0), mat("brick", BRICK), root, 0.08)
    box("Roof", (0, 0, 4.15), (6.3, 5.3, 0.3), mat("slate", SLATE), root, 0.06)
    box("ShopWindow", (-1.6, 2.51, 1.3), (2.2, 0.06, 1.6), mat("glass", GLASS), root, 0.03)
    box("WindowFrame", (-1.6, 2.5, 1.3), (2.4, 0.04, 1.8), mat("trim", TRIM), root, 0.02)
    box("Door", (1.4, 2.52, 1.05), (1.0, 0.08, 2.1), mat("trim", TRIM), root, 0.04)
    box("Sign", (0, 2.55, 3.1), (4.0, 0.12, 0.7), mat("sign", awning), root, 0.06)
    for i in range(6):
        colour = awning if i % 2 == 0 else TRIM
        box("Awning%d" % i, (-2.5 + i * 1.0, 3.0, 2.45), (1.0, 1.0, 0.08), mat("awning%d" % (i % 2), colour), root, 0.0, (math.radians(-25), 0, 0))
    export(name)


def build_clock_tower():
    """The town's clock tower: tall stone tower, a big round clock face, a pointed roof. 11 m."""
    reset()
    root = empty("ClockTower", (0, 0, 0))
    box("Tower", (0, 0, 4.5), (2.6, 2.6, 9.0), mat("stone", STONE), root, 0.1)
    for y, rot in ((1.32, 0), (-1.32, 180)):
        cylinder("Face%+d" % y, (0, y, 7.4), 0.85, 0.1, mat("clock_face", TRIM), root, (math.radians(90), 0, 0), 24)
        box("HourHand%+d" % y, (0, y * 1.04, 7.6), (0.1, 0.05, 0.6), mat("hands", DARK), root, 0.0)
        box("MinuteHand%+d" % y, (0.25, y * 1.04, 7.4), (0.7, 0.05, 0.08), mat("hands", DARK), root, 0.0)
    bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=2.1, radius2=0.05, depth=2.6, location=(0, 0, 10.3), rotation=(0, 0, math.radians(45)))
    finish(bpy.context.active_object, "Spire", mat("slate", SLATE), root, bevel=0.05)
    export("clock_tower")


def build_bus_stop():
    """A red bus-stop shelter with a round sign."""
    reset()
    root = empty("BusStop", (0, 0, 0))
    red = mat("bus_red", (0.85, 0.20, 0.20, 1))
    for x in (-1.3, 1.3):
        box("Post%+.0f" % x, (x, -0.5, 1.2), (0.1, 0.1, 2.4), red, root, 0.02)
    box("Roof", (0, -0.2, 2.45), (2.9, 1.4, 0.12), red, root, 0.04)
    box("Back", (0, -0.85, 1.4), (2.6, 0.06, 1.8), mat("glass", GLASS), root, 0.02)
    box("Bench", (0, -0.6, 0.5), (2.2, 0.4, 0.08), mat("wood", WOOD), root, 0.02)
    cylinder("SignPole", (1.8, 0.3, 1.3), 0.05, 2.6, mat("rail", TRIM), root, verts=8)
    cylinder("Sign", (1.8, 0.3, 2.6), 0.32, 0.06, red, root, (math.radians(90), 0, 0), 20)
    export("bus_stop")


def build_barn():
    """A farm barn: red, white trim, a big double door."""
    reset()
    root = empty("Barn", (0, 0, 0))
    red = mat("barn_red", (0.78, 0.24, 0.22, 1))
    box("Walls", (0, 0, 2.2), (6.5, 6.0, 4.4), red, root, 0.08)
    for sy in (-1, 1):
        box("RoofSide%+d" % sy, (0, sy * 1.55, 5.0), (7.0, 3.5, 0.2), mat("slate", SLATE), root, 0.05, (math.radians(-38 * sy), 0, 0))
    box("BigDoor", (0, 3.02, 1.6), (2.6, 0.08, 3.0), mat("trim", TRIM), root, 0.03)
    box("DoorCross1", (0, 3.07, 1.6), (0.15, 0.04, 3.6), red, root, 0.0, (0, math.radians(40), 0))
    box("DoorCross2", (0, 3.07, 1.6), (0.15, 0.04, 3.6), red, root, 0.0, (0, math.radians(-40), 0))
    export("barn")


def build_lamp():
    """A black street lamp."""
    reset()
    root = empty("Lamp", (0, 0, 0))
    cylinder("Pole", (0, 0, 1.6), 0.07, 3.2, mat("iron", DARK), root, verts=8)
    box("Head", (0, 0, 3.35), (0.4, 0.4, 0.5), mat("lamp_glass", LIGHT), root, 0.05)
    box("Cap", (0, 0, 3.65), (0.5, 0.5, 0.1), mat("iron", DARK), root, 0.03)
    export("lamp")


def quadruped(root, body_col, head_col, body_scale, head_loc, leg_h, leg_col, leg_r=0.07):
    """A round toy animal on four short legs; the body is centred over the legs."""
    sphere("Body", (0, 0, leg_h + body_scale[2] * 0.8), body_scale, body_col, root, 18)
    for x in (-body_scale[0] * 0.6, body_scale[0] * 0.6):
        for y in (-body_scale[1] * 0.55, body_scale[1] * 0.55):
            cylinder("Leg%+.0f%+.0f" % (x * 10, y * 10), (x, y, leg_h / 2), leg_r, leg_h, leg_col, root, verts=8)
    sphere("HeadA", head_loc, (0.22, 0.24, 0.22), head_col, root, 16)


def eyes(root, head_loc, spread=0.09, forward=0.2):
    for x in (-spread, spread):
        sphere("EyeA%+.0f" % (x * 100), (head_loc[0] + x, head_loc[1] + forward, head_loc[2] + 0.06), (0.03,) * 3, mat("eye", DARK), root, 8)


# --- Ukraine: the village's own things ---------------------------------------------------

BLOSSOM = (0.98, 0.86, 0.90, 1)
CHERRY = (0.80, 0.10, 0.18, 1)
WHEAT = (0.93, 0.76, 0.36, 1)
HAY = (0.86, 0.70, 0.36, 1)
POPLAR = (0.30, 0.55, 0.28, 1)
WILLOW = (0.50, 0.70, 0.36, 1)
CLAY = (0.78, 0.44, 0.26, 1)
PUMPKIN = (0.95, 0.55, 0.15, 1)
STORK_BEAK = (0.92, 0.35, 0.18, 1)
UA_BLUE = (0.25, 0.50, 0.85, 1)
UA_YELLOW = (0.98, 0.80, 0.20, 1)


def build_poplar():
    """A tall, narrow Ukrainian poplar (tополя): a slim green flame. About 8 m."""
    reset()
    root = empty("Poplar", (0, 0, 0))
    cylinder("Trunk", (0, 0, 0.8), 0.18, 1.6, mat("wood", WOOD), root, verts=8)
    for i, (z, r) in enumerate(((2.6, 0.95), (4.0, 0.9), (5.3, 0.75), (6.4, 0.55), (7.3, 0.35))):
        sphere("Leaves%d" % i, (0.05 * (i % 2), 0, z), (r, r, r * 1.35), mat("poplar", POPLAR), root, 14)
    export("poplar")


def build_cherry_tree():
    """A cherry tree in an orchard (вишня): a soft crown of white-pink blossom with red cherries."""
    reset()
    root = empty("CherryTree", (0, 0, 0))
    cylinder("Trunk", (0, 0, 0.8), 0.16, 1.6, mat("wood", WOOD), root, verts=8)
    for x, y, z in ((-0.4, 0.1, 1.7), (0.35, 0.3, 1.8)):
        cylinder("Branch%+.0f" % (x * 10), (x * 0.5, y * 0.5, z - 0.2), 0.07, 0.8, mat("wood", WOOD), root, (math.radians(25 * (1 if y > 0 else -1)), math.radians(35 * (1 if x > 0 else -1)), 0), 6)
    for x, y, z, r in ((0, 0, 2.4, 1.0), (0.75, 0.2, 2.1, 0.75), (-0.7, -0.2, 2.15, 0.8), (0.1, -0.55, 2.9, 0.65), (-0.2, 0.55, 2.8, 0.6)):
        sphere("Blossom%+.0f%+.0f" % (x * 10, y * 10), (x, y, z), (r, r, r * 0.85), mat("blossom", BLOSSOM), root, 14)
    for i in range(10):
        a = math.tau * i / 10
        sphere("Cherry%d" % i, (math.cos(a) * 0.95, math.sin(a) * 0.95, 2.0 + 0.3 * math.sin(i * 1.7)), (0.08,) * 3, mat("cherry", CHERRY), root, 8)
    export("cherry_tree")


def build_willow():
    """A weeping willow by the river (верба): a wide crown hanging in long drapes."""
    reset()
    root = empty("Willow", (0, 0, 0))
    cylinder("Trunk", (0, 0, 1.1), 0.28, 2.2, mat("wood", WOOD), root, verts=10)
    sphere("Crown", (0, 0, 3.2), (1.8, 1.8, 1.1), mat("willow", WILLOW), root, 16)
    for i in range(10):
        a = math.tau * i / 10
        sphere("Drape%d" % i, (math.cos(a) * 1.55, math.sin(a) * 1.55, 2.1), (0.42, 0.42, 1.15), mat("willow", WILLOW), root, 10)
    export("willow")


def build_haystack():
    """A round haystack (копиця) with a little stick on top."""
    reset()
    root = empty("Haystack", (0, 0, 0))
    sphere("Hay", (0, 0, 0.9), (1.05, 1.05, 1.2), mat("hay", HAY), root, 16)
    bpy.ops.mesh.primitive_cone_add(vertices=14, radius1=0.75, radius2=0.1, depth=0.8, location=(0, 0, 2.0))
    finish(bpy.context.active_object, "Top", mat("hay", HAY), root)
    cylinder("Stick", (0, 0, 2.5), 0.03, 0.6, mat("wood", WOOD), root, verts=6)
    export("haystack")


def build_stork_nest():
    """A stork in its nest on top of a tall pole (лелека): a lucky sign over a Ukrainian village."""
    reset()
    root = empty("StorkNest", (0, 0, 0))
    cylinder("Pole", (0, 0, 2.5), 0.12, 5.0, mat("wood", WOOD), root, verts=8)
    bpy.ops.mesh.primitive_torus_add(location=(0, 0, 5.1), major_radius=0.55, minor_radius=0.2)
    finish(bpy.context.active_object, "Nest", mat("nest", (0.55, 0.42, 0.28, 1)), root)
    white, black = mat("stork_white", (0.98, 0.98, 0.97, 1)), mat("stork_black", (0.15, 0.15, 0.17, 1))
    sphere("Body", (0, 0, 5.45), (0.25, 0.42, 0.25), white, root, 14)
    sphere("Wings", (0, -0.15, 5.47), (0.27, 0.3, 0.18), black, root, 12)
    cylinder("Neck", (0, 0.3, 5.75), 0.06, 0.45, white, root, (math.radians(-20), 0, 0), 8)
    sphere("Head", (0, 0.36, 6.0), (0.1,) * 3, white, root, 10)
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.04, radius2=0.005, depth=0.4, location=(0, 0.6, 5.95), rotation=(math.radians(-100), 0, 0))
    finish(bpy.context.active_object, "Beak", mat("stork_beak", STORK_BEAK), root)
    for x in (-0.045, 0.045):
        sphere("Eye%+.0f" % (x * 100), (x, 0.43, 6.03), (0.018,) * 3, black, root, 6)
    export("stork_nest")


def build_zhuravel():
    """A well sweep (журавель): a post with a long see-saw pole and a bucket over a log well."""
    reset()
    root = empty("Zhuravel", (0, 0, 0))
    for i in range(4):
        box("Log%d" % i, (0, 0, 0.15 + i * 0.22), (1.3, 1.3, 0.2), mat("log", (0.62, 0.45, 0.30, 1)), root, 0.06)
    cylinder("Water", (0, 0, 0.9), 0.5, 0.04, mat("water", (0.35, 0.6, 0.85, 1)), root, verts=12)
    cylinder("Post", (-2.2, 0, 1.6), 0.12, 3.2, mat("wood", WOOD), root, verts=8)
    cylinder("Sweep", (-1.2, 0, 3.6), 0.06, 5.2, mat("wood", WOOD), root, (0, math.radians(68), 0), 8)
    box("Weight", (-3.4, 0, 3.0), (0.4, 0.3, 0.3), mat("stone", STONE), root, 0.05)
    cylinder("Rope", (0.0, 0, 2.55), 0.015, 2.1, mat("rope", (0.8, 0.72, 0.55, 1)), root, verts=6)
    cylinder("Bucket", (0.0, 0, 1.45), 0.16, 0.26, mat("bucket", (0.55, 0.38, 0.24, 1)), root, verts=12)
    export("zhuravel")


def build_pumpkin():
    """A round orange pumpkin (гарбуз) with ribs and a stem."""
    reset()
    root = empty("Pumpkin", (0, 0, 0))
    for i in range(8):
        a = math.tau * i / 8
        sphere("Rib%d" % i, (math.cos(a) * 0.14, math.sin(a) * 0.14, 0.28), (0.2, 0.2, 0.26), mat("pumpkin", PUMPKIN), root, 12)
    cylinder("Stem", (0, 0, 0.58), 0.04, 0.16, mat("stem", STEM), root, verts=6)
    export("pumpkin")


def build_wheat():
    """A clump of ripe wheat stalks with heavy ears; planted by the hundred in fields."""
    reset()
    root = empty("Wheat", (0, 0, 0))
    for i in range(7):
        a = math.tau * i / 7
        r = 0.12 if i else 0.0
        x, y = math.cos(a) * r, math.sin(a) * r
        h = 0.9 + 0.12 * ((i * 37) % 3)
        cylinder("Stalk%d" % i, (x, y, h / 2), 0.012, h, mat("wheat", WHEAT), root, verts=5)
        sphere("Ear%d" % i, (x, y, h + 0.08), (0.035, 0.035, 0.11), mat("wheat_ear", (0.88, 0.66, 0.28, 1)), root, 6)
    export("wheat")


def build_gate():
    """A painted wooden yard gate (хвіртка) in blue and yellow, with a little roof."""
    reset()
    root = empty("Gate", (0, 0, 0))
    for x in (-0.9, 0.9):
        box("Post%+.0f" % x, (x, 0, 0.9), (0.18, 0.18, 1.8), mat("wood", WOOD), root, 0.03)
    for i in range(7):
        box("Plank%d" % i, (-0.66 + i * 0.22, 0, 0.6), (0.16, 0.06, 0.9), mat("ua_blue" if i % 2 == 0 else "ua_yellow", UA_BLUE if i % 2 == 0 else UA_YELLOW), root, 0.02)
    box("Rail", (0, 0, 1.05), (1.7, 0.08, 0.08), mat("wood", WOOD), root, 0.01)
    bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=1.4, radius2=0.05, depth=0.5, location=(0, 0, 2.05), rotation=(0, 0, math.radians(45)))
    o = bpy.context.active_object
    o.scale = (1.0, 0.35, 1.0)
    finish(o, "Roof", mat("thatch", THATCH), root, bevel=0.03)
    export("gate")


def build_pot_fence():
    """A wicker fence section with clay pots hung upside down on its posts (глечики на тину)."""
    reset()
    root = empty("PotFence", (0, 0, 0))
    for x in (-1.0, -0.5, 0.0, 0.5, 1.0):
        cylinder("Post%+.0f" % (x * 10), (x, 0, 0.5), 0.04, 1.05, mat("wood", WOOD), root, verts=8)
    for z in (0.25, 0.45, 0.65):
        bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.035, depth=2.1, location=(0, 0, z), rotation=(0, math.radians(90), 0))
        finish(bpy.context.active_object, "Weave%.0f" % (z * 100), mat("wicker", (0.70, 0.55, 0.36, 1)), root, bevel=0.0)
    for x in (-1.0, 0.0, 1.0):
        sphere("Pot%+.0f" % x, (x, 0, 1.12), (0.13, 0.13, 0.15), mat("clay", CLAY), root, 12)
        cylinder("Neck%+.0f" % x, (x, 0, 0.98), 0.07, 0.08, mat("clay", CLAY), root, verts=10)
    export("pot_fence")


# --- England: the town's own things ------------------------------------------------------

OAK = (0.24, 0.48, 0.26, 1)
HEDGE = (0.22, 0.45, 0.24, 1)
PILLAR_RED = (0.82, 0.12, 0.14, 1)
CREAM_STUCCO = (0.95, 0.90, 0.78, 1)
IRON = (0.12, 0.12, 0.14, 1)


def build_oak():
    """A big English oak: a wide, dark, lumpy crown on a thick trunk. About 7 m."""
    reset()
    root = empty("Oak", (0, 0, 0))
    cylinder("Trunk", (0, 0, 1.3), 0.38, 2.6, mat("wood", WOOD), root, verts=10)
    for x, y, z, r in ((0, 0, 3.9, 1.9), (1.5, 0.4, 3.3, 1.3), (-1.5, -0.3, 3.4, 1.35), (0.4, -1.4, 3.5, 1.2), (-0.3, 1.4, 3.6, 1.2), (0.2, 0.1, 5.1, 1.2)):
        sphere("Leaves%+.0f%+.0f" % (x * 10, y * 10), (x, y, z), (r, r, r * 0.85), mat("oak", OAK), root, 14)
    export("oak")


def build_hedge():
    """A trimmed box hedge, 2 m long, rounded on top."""
    reset()
    root = empty("Hedge", (0, 0, 0))
    box("Hedge", (0, 0, 0.55), (2.0, 0.8, 1.1), mat("hedge", HEDGE), root, 0.25)
    export("hedge")


def build_phone_box():
    """A red telephone box with a domed roof and many little window panes."""
    reset()
    root = empty("PhoneBox", (0, 0, 0))
    red = mat("pillar_red", PILLAR_RED)
    box("Base", (0, 0, 0.08), (1.1, 1.1, 0.16), red, root, 0.02)
    box("Box", (0, 0, 1.3), (1.0, 1.0, 2.3), red, root, 0.04)
    for (dx, dy, rz) in ((0, 0.51, 0), (0, -0.51, 0), (0.51, 0, 90), (-0.51, 0, 90)):
        for row in range(5):
            for col in range(3):
                x = dx + (col - 1) * 0.22 * (0 if dx else 1)
                y = dy + (col - 1) * 0.22 * (1 if dx else 0)
                box("Pane%d%d%+.0f%+.0f" % (row, col, dx * 10, dy * 10), (x, y, 0.75 + row * 0.27), (0.18 if not dx else 0.03, 0.03 if not dx else 0.18, 0.2), mat("glass", GLASS), root, 0.0)
        box("Sign%+.0f%+.0f" % (dx * 10, dy * 10), (dx * 1.02, dy * 1.02, 2.3), (0.7 if not dx else 0.03, 0.03 if not dx else 0.7, 0.16), mat("trim", TRIM), root, 0.0)
    sphere("Dome", (0, 0, 2.48), (0.6, 0.6, 0.22), red, root, 16)
    export("phone_box")


def build_post_box():
    """A red pillar post box with a black base and a dark letter slot."""
    reset()
    root = empty("PostBox", (0, 0, 0))
    red = mat("pillar_red", PILLAR_RED)
    cylinder("Base", (0, 0, 0.1), 0.34, 0.2, mat("iron", IRON), root, verts=18)
    cylinder("Body", (0, 0, 0.75), 0.3, 1.1, red, root, verts=18)
    sphere("Cap", (0, 0, 1.32), (0.34, 0.34, 0.16), red, root, 18)
    box("Slot", (0, 0.29, 1.1), (0.3, 0.04, 0.06), mat("iron", IRON), root, 0.0)
    box("Plate", (0, 0.29, 0.8), (0.24, 0.03, 0.2), mat("trim", TRIM), root, 0.0)
    export("post_box")


def build_double_decker():
    """A red double-decker bus: two rows of windows, black wheels. About 8 m long."""
    reset()
    root = empty("DoubleDecker", (0, 0, 0))
    red = mat("bus_red", (0.85, 0.16, 0.16, 1))
    box("Body", (0, 0, 2.2), (2.4, 7.6, 3.6), red, root, 0.25)
    box("Band", (0, 0, 2.1), (2.44, 7.64, 0.18), mat("trim", TRIM), root, 0.02)
    for x in (-1.21, 1.21):
        for row, z in enumerate((1.5, 3.1)):
            for i in range(6):
                box("Win%+.0f%d%d" % (x, row, i), (x, -3.0 + i * 1.15, z), (0.04, 0.9, 0.7), mat("glass", GLASS), root, 0.02)
    for z in (1.6, 3.1):
        box("Front%.0f" % z, (0, 3.81, z), (2.0, 0.04, 0.8), mat("glass", GLASS), root, 0.02)
    box("Destination", (0, 3.82, 3.75), (1.2, 0.04, 0.28), mat("dest", (0.15, 0.15, 0.15, 1)), root, 0.0)
    for x, y in ((-1.1, 2.6), (1.1, 2.6), (-1.1, -2.6), (1.1, -2.6)):
        wheel("Wheel%+.0f%+.0f" % (x, y), (x, y, 0.5), 0.5, 0.35, root)
    lights(root, 3.82, 0.8, 0.8)
    export("double_decker")


def build_bench():
    """A park bench: wooden slats on black iron legs."""
    reset()
    root = empty("Bench", (0, 0, 0))
    for x in (-0.8, 0.8):
        box("Leg%+.0f" % x, (x, 0, 0.35), (0.08, 0.5, 0.7), mat("iron", IRON), root, 0.02)
        box("Arm%+.0f" % x, (x, 0, 0.75), (0.08, 0.5, 0.06), mat("iron", IRON), root, 0.02)
    for i in range(3):
        box("Seat%d" % i, (0, -0.15 + i * 0.15, 0.48), (1.8, 0.12, 0.05), mat("wood", WOOD), root, 0.01)
    for i in range(2):
        box("Back%d" % i, (0, -0.27, 0.7 + i * 0.18), (1.8, 0.05, 0.12), mat("wood", WOOD), root, 0.01)
    export("bench")


def build_iron_fence():
    """Black iron railings with spear tips, 2 m long."""
    reset()
    root = empty("IronFence", (0, 0, 0))
    iron = mat("iron", IRON)
    for i in range(11):
        x = -1.0 + i * 0.2
        cylinder("Bar%d" % i, (x, 0, 0.5), 0.02, 1.0, iron, root, verts=6)
        bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.045, radius2=0.0, depth=0.12, location=(x, 0, 1.06))
        finish(bpy.context.active_object, "Tip%d" % i, mat("gold", (0.85, 0.7, 0.3, 1)), root)
    for z in (0.15, 0.85):
        box("Rail%.0f" % (z * 10), (0, 0, z), (2.05, 0.04, 0.05), iron, root, 0.0)
    export("iron_fence")


def build_terrace():
    """A row of three joined English terrace houses in different colours, with bay windows."""
    reset()
    root = empty("Terrace", (0, 0, 0))
    walls = (BRICK, CREAM_STUCCO, (0.60, 0.42, 0.36, 1))
    doors = ((0.22, 0.36, 0.62, 1), (0.20, 0.45, 0.30, 1), (0.75, 0.20, 0.22, 1))
    for i in range(3):
        x = -4.0 + i * 4.0
        box("Wall%d" % i, (x, 0, 2.3), (4.0, 4.4, 4.6), mat("terrace_wall%d" % i, walls[i]), root, 0.04)
        box("Door%d" % i, (x + 1.1, 2.22, 1.0), (0.9, 0.08, 2.0), mat("terrace_door%d" % i, doors[i]), root, 0.03)
        box("Bay%d" % i, (x - 0.7, 2.4, 1.2), (1.8, 0.5, 1.8), mat("terrace_wall%d" % i, walls[i]), root, 0.04)
        box("BayGlass%d" % i, (x - 0.7, 2.66, 1.3), (1.5, 0.04, 1.2), mat("glass", GLASS), root, 0.01)
        box("BayRoof%d" % i, (x - 0.7, 2.4, 2.2), (2.0, 0.7, 0.15), mat("slate", SLATE), root, 0.02)
        for wx in (-0.9, 0.9):
            box("Frame%d%+.0f" % (i, wx), (x + wx, 2.21, 3.4), (0.8, 0.06, 1.0), mat("trim", TRIM), root, 0.02)
            box("Pane%d%+.0f" % (i, wx), (x + wx, 2.23, 3.4), (0.62, 0.05, 0.8), mat("glass", GLASS), root, 0.01)
        box("Chimney%d" % i, (x + 1.2, -0.4, 6.4), (0.6, 0.6, 1.2), mat("brick", BRICK), root, 0.03)
        for k in (-0.12, 0.12):
            cylinder("Pot%d%+.0f" % (i, k * 100), (x + 1.2 + k, -0.4, 7.1), 0.08, 0.25, mat("clay", CLAY), root, verts=8)
    for sy in (-1, 1):
        box("RoofSide%+d" % sy, (0, sy * 1.15, 5.15), (12.3, 2.6, 0.18), mat("slate", SLATE), root, 0.04, (math.radians(-35 * sy), 0, 0))
    export("terrace")


def build_poppies():
    """A wild meadow patch: red poppies and blue cornflowers among a few green leaves."""
    reset()
    root = empty("Poppies", (0, 0, 0))
    spots = ((0, 0), (0.35, 0.15), (-0.3, 0.25), (0.15, -0.35), (-0.25, -0.25), (0.45, -0.2), (-0.5, 0.0))
    for i, (x, y) in enumerate(spots):
        h = 0.45 + 0.08 * (i % 3)
        cylinder("Stem%d" % i, (x, y, h / 2), 0.012, h, mat("stem", STEM), root, verts=5)
        colour = (0.30, 0.45, 0.90, 1) if i % 3 == 2 else (0.90, 0.16, 0.14, 1)
        sphere("Bloom%d" % i, (x, y, h + 0.03), (0.09, 0.09, 0.05), mat("bloom%d" % (i % 3 == 2), colour), root, 10)
        sphere("Middle%d" % i, (x, y, h + 0.07), (0.025,) * 3, mat("stripe", DARK), root, 6)
    for i in range(4):
        a = math.tau * i / 4
        sphere("Leaf%d" % i, (math.cos(a) * 0.2, math.sin(a) * 0.2, 0.06), (0.16, 0.08, 0.05), mat("leaf", LEAF), root, 8)
    export("poppies")


def build_flower_bed():
    """A neat English flower bed: a dark soil border with rows of tulips in pink, yellow and red."""
    reset()
    root = empty("FlowerBed", (0, 0, 0))
    box("Soil", (0, 0, 0.08), (2.0, 0.9, 0.16), mat("soil", (0.40, 0.28, 0.20, 1)), root, 0.04)
    colours = ((0.95, 0.45, 0.62, 1), (0.98, 0.82, 0.22, 1), (0.88, 0.18, 0.20, 1))
    for i in range(6):
        for j in range(2):
            x, y = -0.75 + i * 0.3, -0.18 + j * 0.36
            cylinder("Stem%d%d" % (i, j), (x, y, 0.3), 0.012, 0.3, mat("stem", STEM), root, verts=5)
            sphere("Tulip%d%d" % (i, j), (x, y, 0.48), (0.06, 0.06, 0.09), mat("tulip%d" % ((i + j) % 3), colours[(i + j) % 3]), root, 8)
    export("flower_bed")


def build_bush():
    """A round garden bush, three soft lumps."""
    reset()
    root = empty("Bush", (0, 0, 0))
    for x, y, z, r in ((0, 0, 0.5, 0.6), (0.45, 0.1, 0.38, 0.42), (-0.42, -0.1, 0.4, 0.45)):
        sphere("Lump%+.0f" % (x * 10), (x, y, z), (r, r, r * 0.85), mat("bush", (0.30, 0.56, 0.30, 1)), root, 12)
    export("bush")


def build_boy():
    """The hero: an original little boy, about 1.1 m. Toddler proportions (a big round head), big
    friendly eyes, rosy cheeks, a tuft of brown hair, a sunny yellow T-shirt with a blue star,
    blue shorts, red trainers with white soles, and a small orange backpack.
    Joints: LegL/LegR (hips), ArmL/ArmR (shoulders), Head (neck)."""
    reset()
    skin, hair = mat("skin", (0.98, 0.82, 0.70, 1)), mat("hair", (0.45, 0.28, 0.16, 1))
    shirt, star = mat("tshirt", (1.0, 0.82, 0.22, 1)), mat("star", (0.25, 0.50, 0.88, 1))
    shorts, shoe = mat("shorts", (0.26, 0.42, 0.78, 1)), mat("shoe", (0.88, 0.22, 0.22, 1))
    sole, white = mat("sole", (0.98, 0.98, 0.96, 1)), mat("eye_white", (1.0, 1.0, 1.0, 1))
    dark, cheek = mat("eye_dark", (0.18, 0.12, 0.10, 1)), mat("cheek", (0.96, 0.62, 0.60, 1))
    root = empty("Boy", (0, 0, 0))
    for side, x in (("L", -0.1), ("R", 0.1)):
        leg = limb("Leg" + side, (x, 0, 0.36), 0.26, 0.065, skin, root, skin)
        cylinder("ShortsLeg" + side, (x, 0, 0.3), 0.085, 0.14, shorts, leg, verts=14)
        sphere("Shoe" + side, (x, 0.04, 0.07), (0.08, 0.13, 0.065), shoe, leg, 14)
        box("Sole" + side, (x, 0.04, 0.02), (0.15, 0.24, 0.03), sole, leg, 0.01)
    body = empty("Body", (0, 0, 0.36), root)
    sphere("Hips", (0, 0, 0.4), (0.2, 0.16, 0.12), shorts, body, 16)
    sphere("Torso", (0, 0, 0.55), (0.21, 0.17, 0.2), shirt, body, 18)
    # A five-point star on the chest.
    for i in range(5):
        a = math.tau * i / 5 + math.pi / 2
        box("StarRay%d" % i, (math.cos(a) * 0.035, 0.165, 0.56 + math.sin(a) * 0.035), (0.03, 0.015, 0.07), star, body, 0.0, (0, -a + math.pi / 2, 0))
    sphere("StarMid", (0, 0.168, 0.56), (0.035, 0.012, 0.035), star, body, 10)
    box("Backpack", (0, -0.2, 0.56), (0.24, 0.1, 0.24), mat("backpack", (0.95, 0.55, 0.2, 1)), body, 0.04)
    for side, x in (("L", -0.23), ("R", 0.23)):
        arm = limb("Arm" + side, (x, 0, 0.7), 0.26, 0.055, skin, root, skin)
        sphere("Sleeve" + side, (x, 0, 0.66), (0.075, 0.075, 0.08), shirt, arm, 12)
    head = empty("Head", (0, 0, 0.76), root)
    sphere("Face", (0, 0, 0.95), (0.25, 0.23, 0.24), skin, head, 28)
    for x in (-1, 1):
        sphere("Ear%+d" % x, (x * 0.24, 0, 0.94), (0.045, 0.03, 0.06), skin, head, 10)
    # Hair: a soft cap with a few tufts and a fringe.
    sphere("HairCap", (0, -0.03, 1.03), (0.26, 0.24, 0.19), hair, head, 24)
    for i, (x, y) in enumerate(((-0.1, 0.15), (0.0, 0.18), (0.1, 0.15))):
        sphere("Fringe%d" % i, (x, y, 1.1), (0.07, 0.05, 0.05), hair, head, 10)
    sphere("Tuft", (0.02, -0.02, 1.22), (0.05, 0.04, 0.07), hair, head, 10)
    for x in (-0.085, 0.085):
        sphere("EyeWhite%+.0f" % (x * 1000), (x, 0.2, 0.96), (0.05, 0.03, 0.06), white, head, 14)
        sphere("Eye%+.0f" % (x * 1000), (x, 0.225, 0.955), (0.035, 0.015, 0.045), dark, head, 12)
        sphere("Shine%+.0f" % (x * 1000), (x + 0.012, 0.24, 0.975), (0.012,) * 3, white, head, 6)
        sphere("Cheek%+.0f" % (x * 1000), (x * 1.7, 0.17, 0.88), (0.045, 0.02, 0.03), cheek, head, 10)
    sphere("Nose", (0, 0.235, 0.91), (0.025, 0.02, 0.02), skin, head, 8)
    bpy.ops.mesh.primitive_torus_add(location=(0, 0.215, 0.86), major_radius=0.045, minor_radius=0.01, rotation=(math.radians(90), 0, 0))
    o = bpy.context.active_object
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="DESELECT")
    bpy.ops.object.mode_set(mode="OBJECT")
    for v in o.data.vertices:
        v.select = v.co.y > -0.005  # local after rotation: keep the lower half as a smile
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.delete(type="VERT")
    bpy.ops.object.mode_set(mode="OBJECT")
    finish(o, "Smile", dark, head)
    export("boy")


# --- Organic modelling: smooth blended bodies ------------------------------------------
# Metaballs melt ellipsoids into one smooth surface (a neck flowing into a head, a belly into
# legs), like a sculpted toy. Colour regions (a cow's patches, a muzzle) are painted onto the
# same surface by face, so there are no stuck-on balls.

_blob_count = [0]


def blob(name, elements, material, parent=None, res=0.025, decimate=0.35, threshold=0.6):
    """elements: (loc, radius) for a ball or (loc, radius, (sx, sy, sz)) for an ellipsoid."""
    _blob_count[0] += 1
    mb = bpy.data.metaballs.new("mb%d" % _blob_count[0])
    mb.resolution = res
    mb.render_resolution = res
    mb.threshold = threshold
    obj = bpy.data.objects.new("mb%d" % _blob_count[0], mb)
    bpy.context.collection.objects.link(obj)
    for el in elements:
        e = mb.elements.new()
        e.co = el[0]
        e.radius = el[1]
        if len(el) > 2:
            e.type = "ELLIPSOID"
            e.size_x, e.size_y, e.size_z = el[2]
        e.stiffness = 2.0
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    o = bpy.context.active_object
    if decimate < 1.0:
        mod = o.modifiers.new("dec", "DECIMATE")
        mod.ratio = decimate
        bpy.ops.object.modifier_apply(modifier=mod.name)
    o.name = name
    o.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    if parent is not None:
        set_parent(o, parent)
    return o


def paint(obj, material, inside):
    """Gives the faces whose centre passes inside(world_point) another material."""
    if material.name not in [m.name for m in obj.data.materials if m]:
        obj.data.materials.append(material)
    idx = [m.name for m in obj.data.materials].index(material.name)
    mw = obj.matrix_world
    for poly in obj.data.polygons:
        if inside(mw @ poly.center):
            poly.material_index = idx


def in_ellipsoid(center, radii):
    cx, cy, cz = center
    rx, ry, rz = radii
    return lambda p: ((p.x - cx) / rx) ** 2 + ((p.y - cy) / ry) ** 2 + ((p.z - cz) / rz) ** 2 < 1.0


def shiny_eye(name, loc, size, parent, look=(0, 1, 0)):
    """A glossy toy eye: dark, with a white sparkle up and to the side."""
    sphere(name, loc, (size, size * 0.7, size), mat("eye", DARK), parent, 14)
    sphere(name + "Shine", (loc[0] + size * 0.35, loc[1] + size * 0.6, loc[2] + size * 0.35), (size * 0.32,) * 3, mat("shine", (1, 1, 1, 1)), parent, 8)


def build_cow():
    """A friendly dairy cow: one smooth body with black patches, a big pink muzzle with
    nostrils, floppy ears, short horns, a pink udder, dark hooves and a tufted tail."""
    reset()
    root = empty("Cow", (0, 0, 0))
    white, black = mat("cow_white", (0.97, 0.95, 0.91, 1)), mat("cow_black", (0.17, 0.15, 0.15, 1))
    pink, hoof = mat("cow_pink", (0.96, 0.72, 0.72, 1)), mat("hoof", (0.25, 0.20, 0.18, 1))
    leg_h = 0.42
    body = blob("Body", [
        ((0, 0.3, 0.86), 0.72, (0.95, 1.1, 0.9)),   # chest
        ((0, -0.05, 0.82), 0.74, (1.0, 1.2, 0.9)),  # belly
        ((0, -0.42, 0.86), 0.7, (0.95, 1.0, 0.9)),  # hips
        ((0, 0.68, 1.02), 0.4, (0.85, 1.0, 1.0)),    # neck
    ] + [((x, y, 0.36), 0.17, (1.0, 1.0, 1.9)) for x in (-0.21, 0.21) for y in (0.3, -0.42)]
      + [((x, y, 0.13), 0.13, (1.0, 1.0, 1.7)) for x in (-0.21, 0.21) for y in (0.3, -0.42)],
        white, root, decimate=0.6)
    for c, r in (((0.38, 0.0, 1.0), (0.3, 0.38, 0.35)), ((-0.38, -0.4, 0.95), (0.3, 0.3, 0.35)),
                 ((0.1, -0.5, 1.3), (0.25, 0.25, 0.15)), ((-0.35, 0.35, 0.95), (0.22, 0.25, 0.3))):
        paint(body, black, in_ellipsoid(c, r))
    paint(body, hoof, lambda p: p.z < 0.09)
    # The head: its own smooth shape (a forehead and a wide muzzle), so it reads clearly.
    head = blob("Head", [((0, 0.95, 1.2), 0.38, (0.95, 1.0, 1.0)), ((0, 1.14, 1.06), 0.34, (1.1, 0.95, 0.8))], white, root, decimate=0.6)
    paint(head, pink, in_ellipsoid((0, 1.26, 1.03), (0.3, 0.14, 0.2)))
    paint(head, black, in_ellipsoid((0.14, 0.95, 1.38), (0.14, 0.14, 0.12)))
    for x in (-0.065, 0.065):
        sphere("Nostril%+.0f" % (x * 100), (x, 1.31, 1.04), (0.03, 0.02, 0.04), black, root, 8)
    for x in (-0.12, 0.12):
        shiny_eye("Eye%+.0f" % (x * 100), (x, 1.11, 1.26), 0.04, root)
    for side in (-1, 1):
        ear = sphere("Ear%+d" % side, (side * 0.3, 0.92, 1.26), (0.13, 0.05, 0.065), white, root, 12)
        ear.rotation_euler = (0, math.radians(-25 * side), 0)
        sphere("EarIn%+d" % side, (side * 0.31, 0.95, 1.26), (0.09, 0.02, 0.04), pink, ear, 10)
        bpy.ops.mesh.primitive_cone_add(vertices=10, radius1=0.03, radius2=0.01, depth=0.1, location=(side * 0.13, 0.9, 1.43), rotation=(0, math.radians(30 * side), 0))
        finish(bpy.context.active_object, "Horn%+d" % side, mat("horn", (0.96, 0.9, 0.74, 1)), root)
    udder = blob("Udder", [((0, -0.18, 0.5), 0.13, (1.2, 1.0, 0.7))] + [((x, y, 0.42), 0.04) for x in (-0.06, 0.06) for y in (-0.12, -0.24)], pink, root)
    tail = empty("Tail", (0, -0.62, 1.0), root)
    cylinder("TailRope", (0, -0.75, 0.78), 0.025, 0.45, white, tail, (math.radians(-15), 0, 0), 8)
    blob("TailTuft", [((0, -0.8, 0.54), 0.08, (1.0, 1.0, 1.6))], black, tail)
    export("cow")


def build_sheep():
    """A fluffy sheep: a cloud of bumpy wool, a dark face and legs, soft ears."""
    reset()
    root = empty("Sheep", (0, 0, 0))
    wool, face = mat("wool", (0.98, 0.97, 0.93, 1)), mat("sheep_face", (0.24, 0.21, 0.21, 1))
    puffs = [((x, y, z), 0.32) for x, y, z in (
        (0, 0.2, 0.72), (0, -0.2, 0.72), (0.2, 0, 0.68), (-0.2, 0, 0.68), (0.15, 0.3, 0.8), (-0.15, 0.3, 0.8),
        (0.15, -0.3, 0.8), (-0.15, -0.3, 0.8), (0, 0, 0.88), (0, 0.38, 0.62), (0, -0.4, 0.64), (0.2, 0.15, 0.85),
        (-0.2, -0.15, 0.85))]
    blob("Wool", puffs, wool, root, decimate=0.5)
    blob("Legs", [((x, y, z), 0.12, (1, 1, 1.8)) for x in (-0.15, 0.15) for y in (0.25, -0.28) for z in (0.14, 0.4)], face, root)
    head = blob("Face", [((0, 0.6, 0.85), 0.27, (0.85, 1.1, 1.0)), ((0, 0.75, 0.78), 0.2, (0.85, 1.0, 0.8))], face, root)
    blob("Topknot", [((0, 0.55, 1.0), 0.2), ((0.06, 0.6, 0.98), 0.15), ((-0.06, 0.6, 0.98), 0.15)], wool, root)
    for x in (-0.08, 0.08):
        shiny_eye("Eye%+.0f" % (x * 100), (x, 0.73, 0.89), 0.03, root)
    for side in (-1, 1):
        ear = sphere("Ear%+d" % side, (side * 0.17, 0.56, 0.9), (0.09, 0.035, 0.045), face, root, 10)
        ear.rotation_euler = (0, math.radians(25 * side), 0)
    export("sheep")


def build_pig():
    """A round pink pig: plump body, a flat snout with nostrils, folded ears, a curly tail."""
    reset()
    root = empty("Pig", (0, 0, 0))
    pink, dark_pink = mat("pig_pink", (0.97, 0.72, 0.75, 1)), mat("snout", (0.92, 0.55, 0.62, 1))
    body = blob("Body", [((0, 0.12, 0.42), 0.5, (0.95, 1.1, 0.9)), ((0, -0.18, 0.42), 0.5, (0.95, 1.0, 0.9)),
                         ((0, 0.42, 0.5), 0.38, (0.95, 0.9, 0.95))]
                + [((x, y, 0.12), 0.11, (1, 1, 1.6)) for x in (-0.14, 0.14) for y in (0.2, -0.25)], pink, root, decimate=0.6)
    paint(body, mat("trotter", (0.55, 0.38, 0.38, 1)), lambda p: p.z < 0.05)
    cylinder("Snout", (0, 0.66, 0.46), 0.1, 0.08, dark_pink, root, (math.radians(90), 0, 0), 18)
    for x in (-0.035, 0.035):
        sphere("Nostril%+.0f" % (x * 1000), (x, 0.705, 0.46), (0.018, 0.01, 0.028), mat("eye", DARK), root, 8)
    for x in (-0.1, 0.1):
        shiny_eye("Eye%+.0f" % (x * 100), (x, 0.6, 0.6), 0.03, root)
    for side in (-1, 1):
        bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=0.08, radius2=0.0, depth=0.14, location=(side * 0.14, 0.45, 0.72), rotation=(math.radians(25), math.radians(-20 * side), 0))
        finish(bpy.context.active_object, "Ear%+d" % side, pink, root, bevel=0.02)
    bpy.ops.mesh.primitive_torus_add(location=(0, -0.48, 0.5), major_radius=0.06, minor_radius=0.015, rotation=(0, math.radians(90), 0))
    finish(bpy.context.active_object, "Tail", pink, root)
    export("pig")


def build_duck():
    """A little yellow duck: a teardrop body with wings, a round head, an orange bill and feet."""
    reset()
    root = empty("Duck", (0, 0, 0))
    yellow, orange = mat("duck_yellow", (1.0, 0.86, 0.3, 1)), mat("duck_orange", (0.98, 0.55, 0.15, 1))
    blob("Body", [((0, 0.02, 0.24), 0.36, (1.0, 1.25, 0.85)), ((0, -0.25, 0.32), 0.22, (0.8, 1.0, 0.8))], yellow, root)
    for side in (-1, 1):
        blob("Wing%+d" % side, [((side * 0.17, -0.05, 0.36), 0.18, (0.4, 1.2, 0.7))], mat("duck_wing", (0.97, 0.78, 0.25, 1)), root)
    blob("Head", [((0, 0.2, 0.62), 0.27)], yellow, root)
    blob("Bill", [((0, 0.36, 0.58), 0.13, (1.2, 1.3, 0.45))], orange, root)
    for x in (-0.07, 0.07):
        shiny_eye("Eye%+.0f" % (x * 100), (x, 0.3, 0.68), 0.028, root)
    for x in (-0.08, 0.08):
        blob("Foot%+.0f" % (x * 100), [((x, 0.08, 0.03), 0.09, (1.0, 1.4, 0.35))], orange, root)
    export("duck")


def build_dog():
    """A friendly puppy: tan body, a lighter muzzle, a black nose, floppy brown ears, a waggy tail."""
    reset()
    root = empty("Dog", (0, 0, 0))
    tan, light = mat("dog_tan", (0.84, 0.62, 0.40, 1)), mat("dog_light", (0.97, 0.88, 0.74, 1))
    brown = mat("dog_brown", (0.50, 0.32, 0.20, 1))
    body = blob("Body", [((0, 0, 0.5), 0.42, (0.85, 1.25, 0.85))]
                + [((x, y, z), 0.13, (1, 1, 1.6)) for x in (-0.13, 0.13) for y in (0.2, -0.22) for z in (0.12, 0.3)], tan, root)
    paint(body, light, in_ellipsoid((0, 0.15, 0.4), (0.18, 0.25, 0.15)))
    paint(body, light, lambda p: p.z < 0.08)
    head = blob("Head", [((0, 0.35, 0.82), 0.36), ((0, 0.52, 0.74), 0.22, (0.9, 1.1, 0.8))], tan, root)
    paint(head, light, in_ellipsoid((0, 0.58, 0.72), (0.15, 0.12, 0.12)))
    sphere("Nose", (0, 0.65, 0.76), (0.045, 0.035, 0.035), mat("eye", DARK), root, 10)
    for x in (-0.09, 0.09):
        shiny_eye("Eye%+.0f" % (x * 100), (x, 0.52, 0.88), 0.035, root)
    for side in (-1, 1):
        blob("Ear%+d" % side, [((side * 0.2, 0.32, 0.85), 0.14, (0.5, 0.8, 1.4))], brown, root)
    tail = empty("Tail", (0, -0.32, 0.6), root)
    blob("TailFluff", [((0, -0.38, 0.68), 0.09, (1, 1, 2.0))], tan, tail)
    export("dog")


def build_cat():
    """A soft grey cat sitting up: pointy ears with pink inside, a pink nose, whiskers, a long tail."""
    reset()
    root = empty("Cat", (0, 0, 0))
    grey, light, pink = mat("cat_grey", (0.56, 0.53, 0.52, 1)), mat("cat_light", (0.92, 0.92, 0.94, 1)), mat("nose", PINK)
    body = blob("Body", [((0, 0, 0.32), 0.42, (0.9, 0.9, 1.1)), ((0, 0.05, 0.12), 0.3, (1.1, 1.2, 0.5))], grey, root)
    paint(body, light, in_ellipsoid((0, 0.18, 0.36), (0.15, 0.15, 0.22)))
    head = blob("Head", [((0, 0.08, 0.68), 0.36, (1.05, 0.95, 0.9))], grey, root)
    paint(head, light, in_ellipsoid((0, 0.26, 0.62), (0.12, 0.08, 0.08)))
    sphere("Nose", (0, 0.29, 0.66), (0.025, 0.015, 0.018), pink, root, 8)
    for x in (-0.08, 0.08):
        shiny_eye("Eye%+.0f" % (x * 100), (x, 0.25, 0.72), 0.035, root)
    for side in (-1, 1):
        bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=0.08, radius2=0.0, depth=0.15, location=(side * 0.12, 0.06, 0.88), rotation=(0, math.radians(15 * side), math.radians(45)))
        finish(bpy.context.active_object, "Ear%+d" % side, grey, root, bevel=0.015)
        for k in (-1, 1):
            w = box("Whisker%+d%+d" % (side, k), (side * 0.14, 0.27, 0.64 + k * 0.02), (0.18, 0.006, 0.006), mat("whisker", (0.98, 0.98, 0.98, 1)), root, 0.0, (0, math.radians(8 * k * side), 0))
    tail = empty("Tail", (0, -0.25, 0.15), root)
    blob("TailCurve", [((0.05 * i, -0.3 - 0.02 * i, 0.12 + 0.07 * i), 0.08) for i in range(6)], grey, tail)
    export("cat")


def build_lion():
    """A cuddly lion: golden body, a big round mane, a light muzzle, a tufted tail."""
    reset()
    root = empty("Lion", (0, 0, 0))
    gold, mane, light = mat("lion_gold", (0.95, 0.74, 0.36, 1)), mat("mane", (0.78, 0.44, 0.18, 1)), mat("lion_light", (0.99, 0.9, 0.7, 1))
    blob("Body", [((0, -0.05, 0.62), 0.55, (0.85, 1.3, 0.85))]
         + [((x, y, z), 0.17, (1, 1, 1.6)) for x in (-0.18, 0.18) for y in (0.3, -0.35) for z in (0.14, 0.38)], gold, root)
    blob("Mane", [((math.cos(a) * 0.3, 0.42, 1.0 + math.sin(a) * 0.3), 0.22) for a in [math.tau * i / 12 for i in range(12)]], mane, root, decimate=0.5)
    head = blob("Head", [((0, 0.5, 1.0), 0.42), ((0, 0.68, 0.92), 0.24, (1.1, 0.9, 0.8))], gold, root)
    paint(head, light, in_ellipsoid((0, 0.75, 0.9), (0.16, 0.1, 0.12)))
    sphere("Nose", (0, 0.82, 0.96), (0.05, 0.03, 0.035), mat("lion_nose", (0.45, 0.25, 0.2, 1)), root, 10)
    for x in (-0.1, 0.1):
        shiny_eye("Eye%+.0f" % (x * 100), (x, 0.73, 1.08), 0.04, root)
    for side in (-1, 1):
        sphere("Ear%+d" % side, (side * 0.22, 0.48, 1.24), (0.07, 0.04, 0.07), gold, root, 10)
    tail = empty("Tail", (0, -0.55, 0.75), root)
    blob("TailRope", [((0, -0.6 - 0.05 * i, 0.72 - 0.06 * i), 0.06) for i in range(5)], gold, tail)
    blob("TailTuft", [((0, -0.88, 0.42), 0.1)], mane, tail)
    export("lion")


def build_hen():
    """A plump white hen: red comb and wattle, a yellow beak, yellow legs."""
    reset()
    root = empty("Hen", (0, 0, 0))
    white, red, yellow = mat("hen_white", (0.98, 0.97, 0.94, 1)), mat("comb", (0.88, 0.18, 0.18, 1)), mat("beak", (0.98, 0.72, 0.2, 1))
    blob("Body", [((0, 0, 0.36), 0.42, (0.9, 1.2, 0.9)), ((0, -0.28, 0.5), 0.24, (0.7, 0.8, 1.2))], white, root)
    blob("Head", [((0, 0.25, 0.78), 0.24)], white, root)
    blob("Comb", [((0, 0.22 + 0.04 * i, 0.94 - 0.01 * i), 0.06) for i in range(3)], red, root)
    blob("Wattle", [((0, 0.36, 0.68), 0.06, (0.8, 0.6, 1.3))], red, root)
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.04, radius2=0.0, depth=0.1, location=(0, 0.4, 0.78), rotation=(math.radians(-90), 0, 0))
    finish(bpy.context.active_object, "Beak", yellow, root)
    for x in (-0.07, 0.07):
        shiny_eye("Eye%+.0f" % (x * 100), (x, 0.34, 0.83), 0.025, root)
        cylinder("Leg%+.0f" % (x * 100), (x, 0, 0.12), 0.025, 0.24, yellow, root, verts=6)
        blob("Foot%+.0f" % (x * 100), [((x, 0.05, 0.02), 0.06, (1.0, 1.6, 0.4))], yellow, root)
    export("hen")


SKIN = (0.92, 0.70, 0.56, 1)


def person(root, c):
    """A friendly townsperson in soft, rounded shapes (about 1.75 m, a big head).
    c: dict of colours (shirt, trousers, shoes, hair, skin) and options (belly, beard, hair_style).
    Joints: LegL/LegR (hips), ArmL/ArmR (shoulders), Head (neck)."""
    skin = mat("skin", c.get("skin", SKIN))
    shirt, trousers = mat("shirt_" + c["name"], c["shirt"]), mat("trousers_" + c["name"], c["trousers"])
    shoes, hair = mat("shoes", c.get("shoes", (0.30, 0.22, 0.18, 1))), mat("hair_" + c["name"], c["hair"])
    belly = c.get("belly", 1.0)
    for side, x in (("L", -0.12), ("R", 0.12)):
        leg = empty("Leg" + side, (x, 0, 0.82), root)
        blob("LegShape" + side, [((x, 0, 0.6), 0.2, (1, 1, 2.2)), ((x, 0, 0.3), 0.18, (1, 1, 2.2))], trousers, leg)
        blob("Shoe" + side, [((x, 0.05, 0.07), 0.16, (0.9, 1.5, 0.6))], shoes, leg)
    torso = blob("Torso", [((0, 0, 0.98), 0.48 * belly, (1.0, 0.85 * belly, 0.85)), ((0, 0, 1.24), 0.44, (1.05, 0.75, 0.8))], shirt, root, decimate=0.6)
    for side, x in (("L", -0.3), ("R", 0.3)):
        arm = empty("Arm" + side, (x, 0, 1.34), root)
        blob("Sleeve" + side, [((x, 0, 1.28), 0.17), ((x * 1.05, 0, 1.08), 0.15, (1, 1, 1.5))], shirt, arm)
        blob("Hand" + side, [((x * 1.07, 0.02, 0.9), 0.13)], skin, arm)
    head = empty("Head", (0, 0, 1.42), root)
    blob("Neck", [((0, 0, 1.42), 0.14)], skin, head)
    face = blob("Face", [((0, 0, 1.62), 0.42, (1.0, 0.95, 1.0))], skin, head, decimate=0.6)
    blob("Nose", [((0, 0.25, 1.58), 0.08)], skin, head)
    for x in (-1, 1):
        blob("Ear%+d" % x, [((x * 0.25, 0, 1.6), 0.08, (0.6, 1, 1.2))], skin, head)
        shiny_eye("Eye%+d" % x, (x * 0.085, 0.235, 1.67), 0.034, head)
        sphere("Cheek%+d" % x, (x * 0.15, 0.215, 1.56), (0.05, 0.015, 0.032), mat("cheek", (0.95, 0.52, 0.5, 1)), head, 8)
        box("Brow%+d" % x, (x * 0.085, 0.245, 1.735), (0.065, 0.015, 0.018), hair, head, 0.005)
    bpy.ops.mesh.primitive_torus_add(location=(0, 0.25, 1.51), major_radius=0.055, minor_radius=0.013, rotation=(math.radians(90), 0, 0))
    smile = bpy.context.active_object
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.object.mode_set(mode="OBJECT")
    for v in smile.data.vertices:
        v.select = v.co.y > 0.0
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.delete(type="VERT")
    bpy.ops.object.mode_set(mode="OBJECT")
    finish(smile, "Smile", mat("mouth", (0.45, 0.2, 0.2, 1)), head)
    style = c.get("hair_style", "short")
    if style == "short":
        blob("Hair", [((0, -0.04, 1.74), 0.42, (1.02, 1.0, 0.7)), ((0, 0.12, 1.78), 0.22, (1.3, 0.6, 0.5))], hair, head)
    elif style == "bun":
        blob("Hair", [((0, -0.05, 1.72), 0.43, (1.02, 1.0, 0.75)), ((0, -0.2, 1.9), 0.2)], hair, head)
    elif style == "bald":
        blob("Hair", [((x, -0.05, 1.62), 0.16, (0.6, 1.2, 0.8)) for x in (-0.22, 0.22)], hair, head)
    if c.get("beard"):
        blob("Beard", [((0, 0.12, 1.46), 0.3, (1.0, 0.7, 0.75)), ((0, 0.18, 1.4), 0.2)], hair, head)
        blob("Moustache", [((x, 0.25, 1.54), 0.07, (1.2, 0.6, 0.5)) for x in (-0.05, 0.05)], hair, head)
    return head, torso


def glasses(head, z=1.67):
    for x in (-0.085, 0.085):
        bpy.ops.mesh.primitive_torus_add(location=(x, 0.24, z), major_radius=0.055, minor_radius=0.01, rotation=(math.radians(90), 0, 0))
        finish(bpy.context.active_object, "Glasses%+.0f" % (x * 100), mat("glasses", DARK), head)
    box("Bridge", (0, 0.245, z), (0.06, 0.01, 0.01), mat("glasses", DARK), head, 0.0)


def build_postman():
    """The postman: navy uniform with red trim, a red cap, a brown satchel full of letters."""
    reset()
    root = empty("Postman", (0, 0, 0))
    head, torso = person(root, {"name": "postman", "shirt": (0.24, 0.36, 0.64, 1), "trousers": (0.18, 0.24, 0.42, 1), "hair": (0.40, 0.26, 0.16, 1)})
    paint(torso, mat("trim_red", (0.82, 0.2, 0.2, 1)), lambda p: abs(p.z - 1.36) < 0.025)
    for i in range(3):
        sphere("Button%d" % i, (0, 0.23, 1.25 - i * 0.12), (0.022,) * 3, mat("brass", (0.95, 0.78, 0.3, 1)), torso, 8)
    blob("Cap", [((0, 0.0, 1.86), 0.36, (1.05, 1.05, 0.45))], mat("cap_red", (0.82, 0.18, 0.2, 1)), head)
    blob("Peak", [((0, 0.24, 1.8), 0.2, (1.1, 0.8, 0.18))], mat("peak", (0.15, 0.15, 0.18, 1)), head)
    blob("Satchel", [((0.3, 0.05, 0.98), 0.24, (0.5, 1.0, 0.9))], mat("bag", (0.58, 0.40, 0.24, 1)), root)
    box("Strap", (0, 0.18, 1.18), (0.07, 0.02, 0.8), mat("bag", (0.58, 0.40, 0.24, 1)), root, 0.0, (0, math.radians(-40), 0))
    box("Letter", (0.3, 0.12, 1.12), (0.18, 0.02, 0.12), mat("letter", (0.98, 0.98, 0.96, 1)), root, 0.005)
    export("postman")


def build_baker():
    """The baker: round and cheerful, white jacket and apron, a tall puffy chef's hat, a rolling pin."""
    reset()
    root = empty("Baker", (0, 0, 0))
    head, torso = person(root, {"name": "baker", "shirt": (0.98, 0.97, 0.94, 1), "trousers": (0.30, 0.30, 0.34, 1), "hair": (0.75, 0.45, 0.25, 1), "belly": 1.18, "hair_style": "bun"})
    paint(torso, mat("apron", (0.95, 0.62, 0.42, 1)), lambda p: p.y > 0.1 and p.z < 1.2)
    blob("Hat", [((0, -0.02, 1.9), 0.3, (1, 1, 0.7)), ((0.1, 0.05, 2.02), 0.26), ((-0.1, 0.0, 2.04), 0.26), ((0, -0.08, 2.08), 0.26)], mat("hat_white", (1, 1, 1, 1)), head)
    cylinder("HatBand", (0, -0.02, 1.84), 0.25, 0.1, mat("hat_white", (1, 1, 1, 1)), head, verts=20)
    export("baker")


def build_toy_maker():
    """The toy maker: a purple coat with big yellow buttons, round glasses, a bright striped beanie."""
    reset()
    root = empty("ToyMaker", (0, 0, 0))
    head, torso = person(root, {"name": "toy", "shirt": (0.56, 0.42, 0.80, 1), "trousers": (0.24, 0.26, 0.40, 1), "hair": (0.85, 0.80, 0.70, 1), "hair_style": "short"})
    for i in range(3):
        sphere("Button%d" % i, (0, 0.25, 1.28 - i * 0.14), (0.04, 0.02, 0.04), mat("button", (0.98, 0.82, 0.2, 1)), torso, 10)
    glasses(head)
    beanie = blob("Beanie", [((0, -0.02, 1.84), 0.4, (1.05, 1.05, 0.6))], mat("beanie", (0.95, 0.35, 0.3, 1)), head)
    paint(beanie, mat("beanie2", (0.98, 0.85, 0.3, 1)), lambda p: p.z < 1.8)
    blob("Pompom", [((0, -0.02, 2.02), 0.12)], mat("beanie2", (0.98, 0.85, 0.3, 1)), head)
    export("toy_maker")


def build_farmer():
    """The farmer: blue dungarees over a red checked shirt, a wide straw hat, rosy cheeks."""
    reset()
    root = empty("Farmer", (0, 0, 0))
    head, torso = person(root, {"name": "farmer", "shirt": (0.86, 0.30, 0.26, 1), "trousers": (0.28, 0.42, 0.66, 1), "hair": (0.55, 0.35, 0.2, 1), "beard": False})
    paint(torso, mat("trousers_farmer", (0.28, 0.42, 0.66, 1)), lambda p: p.z < 1.12 or (abs(p.x) < 0.14 and p.y > 0.1 and p.z < 1.3))
    straw = mat("straw", (0.96, 0.84, 0.48, 1))
    cylinder("Brim", (0, 0, 1.84), 0.5, 0.04, straw, head, verts=28)
    blob("Crown", [((0, 0, 1.92), 0.28, (1, 1, 0.75))], straw, head)
    cylinder("HatBand", (0, 0, 1.88), 0.19, 0.06, mat("band", (0.82, 0.25, 0.22, 1)), head, verts=20)
    export("farmer")


def build_clock_maker():
    """The clock maker: a brown waistcoat with a gold watch chain, a white beard, round glasses, a flat cap."""
    reset()
    root = empty("ClockMaker", (0, 0, 0))
    head, torso = person(root, {"name": "clock", "shirt": (0.95, 0.93, 0.88, 1), "trousers": (0.30, 0.28, 0.32, 1), "hair": (0.95, 0.95, 0.95, 1), "beard": True, "hair_style": "bald"})
    paint(torso, mat("waistcoat", (0.50, 0.32, 0.20, 1)), lambda p: p.z < 1.3 and not (abs(p.x) < 0.07 and p.y > 0.1))
    box("Chain", (0.08, 0.24, 1.08), (0.16, 0.01, 0.012), mat("brass", (0.95, 0.78, 0.3, 1)), torso, 0.0, (0, math.radians(15), 0))
    glasses(head)
    blob("FlatCap", [((0, 0.02, 1.82), 0.38, (1.08, 1.1, 0.35)), ((0, 0.2, 1.8), 0.2, (1.2, 0.8, 0.2))], mat("flatcap", (0.35, 0.40, 0.50, 1)), head)
    export("clock_maker")


def skirt(root, colour, length=0.55, name="Skirt"):
    """A soft bell skirt from the waist down (over the legs)."""
    return blob(name, [((0, 0, 0.92), 0.46, (1.0, 0.85, 0.6)), ((0, 0, 0.92 - length * 0.6), 0.5, (1.15, 1.0, 0.7))], mat(name.lower(), colour), root)


def build_grandma():
    """A Ukrainian grandma (бабуся): a flowered headscarf, a long red skirt, a white embroidered
    blouse, a basket."""
    reset()
    root = empty("Grandma", (0, 0, 0))
    head, torso = person(root, {"name": "grandma", "shirt": (0.98, 0.97, 0.93, 1), "trousers": (0.80, 0.22, 0.22, 1), "hair": (0.85, 0.85, 0.85, 1), "belly": 1.1, "hair_style": "bun"})
    paint(torso, mat("embroidery", EMBROIDERY), lambda p: abs(p.z - 1.3) < 0.03 or (abs(p.x) < 0.04 and p.y > 0.1))
    skirt(root, (0.80, 0.22, 0.22, 1), 0.6)
    scarf = blob("Scarf", [((0, -0.03, 1.72), 0.44, (1.08, 1.05, 0.85)), ((0, -0.12, 1.5), 0.25, (1.2, 0.8, 0.8))], mat("scarf", (0.25, 0.45, 0.85, 1)), head)
    paint(scarf, mat("scarf_flower", (0.98, 0.82, 0.2, 1)), lambda p: (int(p.x * 12) + int(p.z * 12)) % 3 == 0)
    blob("Basket", [((0.33, 0.12, 0.85), 0.2, (1.1, 0.8, 0.6))], mat("wicker", (0.70, 0.55, 0.36, 1)), root)
    export("grandma")


def build_girl():
    """A little girl in a vyshyvanka dress with two plaits and a flower wreath (вінок)."""
    reset()
    root = empty("Girl", (0, 0, 0))
    head, torso = person(root, {"name": "girl", "shirt": (0.98, 0.97, 0.93, 1), "trousers": (0.98, 0.80, 0.70, 1), "hair": (0.55, 0.35, 0.18, 1), "hair_style": "short"})
    paint(torso, mat("embroidery", EMBROIDERY), lambda p: abs(p.z - 1.3) < 0.03 or abs(p.z - 1.0) < 0.03)
    skirt(root, (0.98, 0.97, 0.93, 1), 0.45, "Dress")
    for x in (-0.22, 0.22):
        blob("Plait%+.0f" % (x * 10), [((x, -0.08, 1.55 - 0.08 * i), 0.07) for i in range(4)], mat("hair_girl", (0.55, 0.35, 0.18, 1)), head)
    for i in range(8):
        a = math.tau * i / 8
        sphere("Flower%d" % i, (math.cos(a) * 0.24, math.sin(a) * 0.22 - 0.02, 1.84), (0.06,) * 3, mat("wreath%d" % (i % 3), [(0.90, 0.2, 0.2, 1), (0.98, 0.82, 0.2, 1), (0.35, 0.55, 0.95, 1)][i % 3]), head, 8)
    root.scale = (0.72, 0.72, 0.72)
    export("girl")


def build_man():
    """An English gentleman out for a walk: a green jacket, a flat cap, a newspaper."""
    reset()
    root = empty("Man", (0, 0, 0))
    head, torso = person(root, {"name": "man", "shirt": (0.30, 0.48, 0.34, 1), "trousers": (0.30, 0.30, 0.36, 1), "hair": (0.35, 0.25, 0.18, 1)})
    blob("FlatCap", [((0, 0.02, 1.82), 0.38, (1.08, 1.1, 0.35)), ((0, 0.2, 1.8), 0.2, (1.2, 0.8, 0.2))], mat("tweed", (0.55, 0.45, 0.35, 1)), head)
    box("Paper", (0.32, 0.1, 0.95), (0.06, 0.2, 0.3), mat("paper", (0.95, 0.94, 0.9, 1)), root, 0.01)
    export("man")


def build_woman():
    """An English lady with a red umbrella, a blue coat and a yellow hat."""
    reset()
    root = empty("Woman", (0, 0, 0))
    head, torso = person(root, {"name": "woman", "shirt": (0.28, 0.42, 0.75, 1), "trousers": (0.95, 0.88, 0.78, 1), "hair": (0.75, 0.45, 0.25, 1), "hair_style": "bun"})
    skirt(root, (0.28, 0.42, 0.75, 1), 0.5, "Coat")
    blob("Hat", [((0, 0, 1.84), 0.32, (1.1, 1.1, 0.5))], mat("hat_yellow", (0.98, 0.82, 0.25, 1)), head)
    cylinder("Brim", (0, 0, 1.8), 0.36, 0.03, mat("hat_yellow", (0.98, 0.82, 0.25, 1)), head, verts=24)
    cylinder("Umbrella", (0.33, 0.05, 0.6), 0.03, 1.0, mat("umbrella", (0.85, 0.2, 0.22, 1)), root, verts=8)
    export("woman")


BUILDERS = {
    "tygrytsa": build_tygrytsa,
    "hata": build_hata,
    "tree": build_tree,
    "sunflower": build_sunflower,
    "fence": build_fence,
    "well": build_well,
    "postman": build_postman,
    "ferry": build_ferry,
    "english_house": build_english_house,
    "bakery": lambda: build_shop("bakery", (0.96, 0.66, 0.30, 1)),
    "cafe": lambda: build_shop("cafe", (0.45, 0.68, 0.55, 1)),
    "toy_shop": lambda: build_shop("toy_shop", (0.55, 0.45, 0.82, 1)),
    "clock_tower": build_clock_tower,
    "bus_stop": build_bus_stop,
    "barn": build_barn,
    "lamp": build_lamp,
    "baker": build_baker,
    "toy_maker": build_toy_maker,
    "duck": build_duck,
    "farmer": build_farmer,
    "clock_maker": build_clock_maker,
    "poplar": build_poplar,
    "cherry_tree": build_cherry_tree,
    "willow": build_willow,
    "haystack": build_haystack,
    "stork_nest": build_stork_nest,
    "zhuravel": build_zhuravel,
    "pumpkin": build_pumpkin,
    "wheat": build_wheat,
    "gate": build_gate,
    "pot_fence": build_pot_fence,
    "oak": build_oak,
    "hedge": build_hedge,
    "phone_box": build_phone_box,
    "post_box": build_post_box,
    "double_decker": build_double_decker,
    "bench": build_bench,
    "iron_fence": build_iron_fence,
    "terrace": build_terrace,
    "poppies": build_poppies,
    "flower_bed": build_flower_bed,
    "bush": build_bush,
    "boy": build_boy,
    "grandma": build_grandma,
    "girl": build_girl,
    "man": build_man,
    "woman": build_woman,
    "cat": build_cat,
    "lion": build_lion,
    "hen": build_hen,
}

# BUILD_ONLY="poplar oak" builds just those (all when unset).
_only = os.environ.get("BUILD_ONLY", "").split()
for _name, _build in BUILDERS.items():
    if not _only or _name in _only:
        _build()
