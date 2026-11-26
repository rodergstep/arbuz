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
    """Tygrytsa: an original, round, cheerful tigress in a vyshyvanka. About 1.15 m tall."""
    reset()
    o, c, d = mat("fur", ORANGE), mat("cream", CREAM), mat("stripe", DARK)
    s, e = mat("shirt", SHIRT), mat("embroidery", EMBROIDERY)
    root = empty("Tygrytsa", (0, 0, 0))
    # Legs (hip joints) under a round body
    limb("LegL", (-0.13, 0, 0.32), 0.24, 0.085, o, root, c)
    limb("LegR", (0.13, 0, 0.32), 0.24, 0.085, o, root, c)
    body = empty("Body", (0, 0, 0.3), root)
    sphere("Belly", (0, 0, 0.45), (0.3, 0.27, 0.27), o, body)
    sphere("Tummy", (0, 0.12, 0.42), (0.18, 0.16, 0.18), c, body)
    # Vyshyvanka: white shirt over the chest, red embroidery at the collar, down the front, cuffs
    sphere("Shirt", (0, 0, 0.62), (0.31, 0.28, 0.24), s, body)
    bpy.ops.mesh.primitive_torus_add(location=(0, 0, 0.78), major_radius=0.17, minor_radius=0.035)
    finish(bpy.context.active_object, "Collar", e, body)
    for i, z in enumerate((0.74, 0.66, 0.58, 0.5)):
        box("Diamond%d" % i, (0, 0.27, z), (0.06, 0.03, 0.06), e if i % 2 == 0 else mat("embroidery_dark", EMBROIDERY_DARK), body, 0.0, (0, math.radians(45), 0))
    for x in (-0.22, 0.22):
        box("Stripe%+.0f" % (x * 10), (x * 1.25, 0.02, 0.4), (0.04, 0.12, 0.05), d, body, 0.01)
    # Arms (shoulder joints) with shirt sleeves and embroidered cuffs
    for side, x in (("L", -0.3), ("R", 0.3)):
        arm = limb("Arm" + side, (x, 0, 0.75), 0.3, 0.07, s, root, o)
        bpy.ops.mesh.primitive_torus_add(location=(x, 0, 0.53), major_radius=0.075, minor_radius=0.022)
        finish(bpy.context.active_object, "Cuff" + side, e, arm)
    # Head
    head = empty("Head", (0, 0, 0.98), root)
    sphere("Skull", (0, 0, 1.02), (0.3, 0.27, 0.27), o, head, 24)
    sphere("Muzzle", (0, 0.2, 0.95), (0.16, 0.11, 0.1), c, head)
    sphere("Nose", (0, 0.31, 0.99), (0.045, 0.03, 0.035), mat("nose", PINK), head, 12)
    for x in (-0.11, 0.11):
        sphere("Eye%+.0f" % (x * 100), (x, 0.24, 1.08), (0.045, 0.03, 0.055), d, head, 12)
        sphere("Shine%+.0f" % (x * 100), (x + 0.012, 0.268, 1.1), (0.014,) * 3, c, head, 8)
        sphere("Cheek%+.0f" % (x * 100), (x * 1.7, 0.16, 0.95), (0.08, 0.06, 0.07), c, head)
        ear = sphere("Ear%+.0f" % (x * 100), (x * 1.7, 0, 1.27), (0.09, 0.05, 0.09), o, head, 14)
        sphere("EarIn%+.0f" % (x * 100), (x * 1.7, 0.03, 1.27), (0.05, 0.02, 0.05), c, ear, 10)
    for i, x in enumerate((-0.07, 0.0, 0.07)):
        box("HeadStripe%d" % i, (x, 0.12, 1.25), (0.025, 0.08, 0.09 if i == 1 else 0.06), d, head, 0.008)
    # Tail: a curve of three pieces from the tail base, dark tip
    tail = empty("Tail", (0, -0.27, 0.42), root)
    for i in range(3):
        z = 0.42 + 0.09 * i
        y = -0.3 - 0.1 * i
        cylinder("Tail%d" % i, (0, y, z), 0.045, 0.16, o if i < 2 else d, tail, (math.radians(-55 + 15 * i), 0, 0), 12)
    export("tygrytsa")


def wheel(name, loc, radius, width, parent):
    w = cylinder(name, loc, radius, width, mat("tyre", TYRE), parent, (0, math.radians(90), 0), 22)
    cylinder(name + "_hub", (loc[0] + math.copysign(width / 2, loc[0]), loc[1], loc[2]), radius * 0.45, 0.02, mat("hub", CHROME), parent, (0, math.radians(90), 0), 16)
    return w


def lights(parent, y, z, x=0.55):
    for sx in (-x, x):
        sphere("Light%+.0f" % (sx * 10), (sx, y, z), (0.12, 0.05, 0.1), mat("light", LIGHT), parent, 12)


def build_hatchback():
    """A round little hatchback: soft bubble body, big friendly headlights."""
    reset()
    root = empty("CarHatchback", (0, 0, 0))
    paint = mat("paint", (0.93, 0.40, 0.33, 1))
    sphere("Body", (0, 0, 0.62), (0.9, 1.45, 0.42), paint, root, 24)
    sphere("Cabin", (0, -0.15, 1.02), (0.72, 0.85, 0.42), mat("glass", GLASS), root, 20)
    sphere("Roof", (0, -0.2, 1.22), (0.62, 0.65, 0.14), paint, root, 20)
    for x, y in ((-0.82, 0.85), (0.82, 0.85), (-0.82, -0.85), (0.82, -0.85)):
        wheel("Wheel%+.0f%+.0f" % (x, y), (x, y, 0.35), 0.34, 0.28, root)
    lights(root, 1.38, 0.72, 0.45)
    box("Bumper", (0, 1.42, 0.45), (1.2, 0.12, 0.14), mat("chrome", CHROME), root, 0.05)
    export("car_hatchback")


def build_jeep():
    """A small sturdy jeep: chunky box, high wheels, spare tyre on the back, roll bar."""
    reset()
    root = empty("CarJeep", (0, 0, 0))
    paint = mat("paint", (0.42, 0.65, 0.42, 1))
    box("Body", (0, 0, 0.78), (1.75, 2.9, 0.62), paint, root, 0.12)
    box("Hood", (0, 0.95, 1.1), (1.6, 0.95, 0.06), paint, root, 0.03)
    box("Windshield", (0, 0.42, 1.38), (1.55, 0.08, 0.55), mat("glass", GLASS), root, 0.03)
    bpy.ops.mesh.primitive_torus_add(location=(0, -0.45, 1.1), major_radius=0.75, minor_radius=0.05, rotation=(math.radians(90), 0, math.radians(90)))
    finish(bpy.context.active_object, "RollBar", mat("chrome", CHROME), root)
    for x, y in ((-0.9, 0.95), (0.9, 0.95), (-0.9, -0.95), (0.9, -0.95)):
        wheel("Wheel%+.0f%+.0f" % (x, y), (x, y, 0.42), 0.42, 0.34, root)
    cylinder("Spare", (0, -1.55, 0.9), 0.36, 0.22, mat("tyre", TYRE), root, (math.radians(90), 0, 0), 20)
    lights(root, 1.46, 0.85, 0.55)
    export("car_jeep")


def build_van():
    """A tiny van: tall rounded box, big windows, a cheerful stripe."""
    reset()
    root = empty("CarVan", (0, 0, 0))
    paint = mat("paint", (0.45, 0.68, 0.92, 1))
    box("Body", (0, 0, 1.0), (1.75, 3.0, 1.35), paint, root, 0.3)
    box("Windscreen", (0, 1.45, 1.35), (1.45, 0.1, 0.5), mat("glass", GLASS), root, 0.05)
    for x in (-0.875, 0.875):
        box("Window%+.0f" % x, (x, -0.2, 1.38), (0.06, 1.9, 0.45), mat("glass", GLASS), root, 0.04)
        box("Stripe%+.0f" % x, (x, 0, 0.85), (0.05, 2.8, 0.14), mat("cream", CREAM), root, 0.02)
    for x, y in ((-0.85, 0.95), (0.85, 0.95), (-0.85, -0.95), (0.85, -0.95)):
        wheel("Wheel%+.0f%+.0f" % (x, y), (x, y, 0.35), 0.33, 0.28, root)
    lights(root, 1.5, 0.75, 0.55)
    export("car_van")


WALL = (0.97, 0.95, 0.90, 1)
THATCH = (0.80, 0.63, 0.34, 1)
SHUTTER = (0.36, 0.58, 0.82, 1)
WOOD = (0.55, 0.38, 0.24, 1)
LEAF = (0.32, 0.60, 0.34, 1)
PETAL = (1.0, 0.80, 0.18, 1)
SEEDS = (0.40, 0.25, 0.14, 1)
STEM = (0.38, 0.62, 0.30, 1)
FLOWER_RED = (0.88, 0.30, 0.32, 1)
STONE = (0.72, 0.70, 0.66, 1)


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


def build_postman():
    """A friendly English postman: blue uniform, red cap, big satchel. About 1.7 m."""
    reset()
    root = empty("Postman", (0, 0, 0))
    blue, skin = mat("uniform", (0.25, 0.38, 0.66, 1)), mat("skin", (0.96, 0.80, 0.68, 1))
    red, bag = mat("cap", (0.80, 0.18, 0.20, 1)), mat("bag", (0.58, 0.40, 0.24, 1))
    limb("LegL", (-0.12, 0, 0.75), 0.68, 0.09, mat("trousers", (0.18, 0.24, 0.40, 1)), root, mat("shoe", DARK))
    limb("LegR", (0.12, 0, 0.75), 0.68, 0.09, mat("trousers", (0.18, 0.24, 0.40, 1)), root, mat("shoe", DARK))
    body = empty("Body", (0, 0, 0.75), root)
    sphere("Torso", (0, 0, 1.05), (0.3, 0.22, 0.38), blue, body)
    for i, z in enumerate((1.25, 1.1, 0.95)):
        sphere("Button%d" % i, (0, 0.21, z), (0.025,) * 3, mat("gold", (0.95, 0.80, 0.30, 1)), body, 8)
    # Satchel on a strap
    box("Satchel", (0.3, 0.1, 0.85), (0.12, 0.34, 0.3), bag, body, 0.04)
    box("Strap", (0.05, 0.12, 1.15), (0.05, 0.04, 0.7), bag, body, 0.01, (0, math.radians(-35), 0))
    for side, x in (("L", -0.33), ("R", 0.33)):
        limb("Arm" + side, (x, 0, 1.33), 0.5, 0.075, blue, root, skin)
    head = empty("Head", (0, 0, 1.55), root)
    sphere("Face", (0, 0, 1.6), (0.2, 0.19, 0.22), skin, head, 20)
    sphere("NoseP", (0, 0.19, 1.6), (0.035, 0.03, 0.035), skin, head, 10)
    for x in (-0.07, 0.07):
        sphere("EyeP%+.0f" % (x * 100), (x, 0.17, 1.66), (0.025, 0.015, 0.03), mat("eye", DARK), head, 8)
    sphere("Smile", (0, 0.17, 1.52), (0.06, 0.02, 0.015), mat("mouth", (0.75, 0.35, 0.35, 1)), head, 10)
    cylinder("Cap", (0, 0, 1.8), 0.2, 0.12, red, head, verts=18)
    box("Visor", (0, 0.17, 1.75), (0.28, 0.14, 0.03), mat("cap_dark", (0.20, 0.12, 0.12, 1)), head, 0.02)
    export("postman")


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


def build_baker():
    """The baker: a round, cheerful baker in a white apron and a tall chef's hat. About 1.65 m."""
    reset()
    root = empty("Baker", (0, 0, 0))
    dress, skin = mat("dress", (0.92, 0.55, 0.45, 1)), mat("skin", (0.96, 0.80, 0.68, 1))
    apron, white = mat("apron", (0.99, 0.98, 0.96, 1)), mat("hat", (1.0, 1.0, 1.0, 1))
    limb("LegL", (-0.11, 0, 0.6), 0.55, 0.08, skin, root, mat("shoe", DARK))
    limb("LegR", (0.11, 0, 0.6), 0.55, 0.08, skin, root, mat("shoe", DARK))
    body = empty("Body", (0, 0, 0.6), root)
    sphere("Dress", (0, 0, 0.95), (0.36, 0.3, 0.45), dress, body)
    sphere("Apron", (0, 0.12, 0.92), (0.28, 0.2, 0.36), apron, body)
    for side, x in (("L", -0.34), ("R", 0.34)):
        limb("Arm" + side, (x, 0, 1.22), 0.45, 0.075, dress, root, skin)
    head = empty("Head", (0, 0, 1.45), root)
    sphere("Face", (0, 0, 1.5), (0.2, 0.19, 0.21), skin, head, 20)
    sphere("Cheeks", (0, 0.13, 1.46), (0.15, 0.06, 0.06), mat("blush", (0.95, 0.62, 0.60, 1)), head, 12)
    for x in (-0.07, 0.07):
        sphere("EyeB%+.0f" % (x * 100), (x, 0.17, 1.55), (0.025, 0.015, 0.03), mat("eye", DARK), head, 8)
    sphere("SmileB", (0, 0.17, 1.42), (0.06, 0.02, 0.015), mat("mouth", (0.75, 0.35, 0.35, 1)), head, 10)
    cylinder("HatBand", (0, 0, 1.7), 0.19, 0.12, white, head, verts=18)
    sphere("HatTop", (0, 0, 1.86), (0.26, 0.26, 0.2), white, head, 18)
    export("baker")


def build_toy_maker():
    """The toy maker: a purple coat with big yellow buttons, round glasses, a bright cap. 1.65 m."""
    reset()
    root = empty("ToyMaker", (0, 0, 0))
    coat, skin = mat("coat", (0.55, 0.42, 0.80, 1)), mat("skin", (0.92, 0.74, 0.62, 1))
    button, cap = mat("buttons", (0.98, 0.82, 0.25, 1)), mat("cap", (0.30, 0.70, 0.55, 1))
    limb("LegL", (-0.11, 0, 0.6), 0.55, 0.08, mat("trousers", (0.25, 0.25, 0.32, 1)), root, mat("shoe", DARK))
    limb("LegR", (0.11, 0, 0.6), 0.55, 0.08, mat("trousers", (0.25, 0.25, 0.32, 1)), root, mat("shoe", DARK))
    body = empty("Body", (0, 0, 0.6), root)
    sphere("Coat", (0, 0, 0.98), (0.33, 0.27, 0.42), coat, body)
    for i, z in enumerate((1.15, 0.98, 0.81)):
        sphere("Button%d" % i, (0, 0.27, z), (0.04,) * 3, button, body, 10)
    for side, x in (("L", -0.32), ("R", 0.32)):
        limb("Arm" + side, (x, 0, 1.22), 0.45, 0.075, coat, root, skin)
    head = empty("Head", (0, 0, 1.45), root)
    sphere("Face", (0, 0, 1.5), (0.2, 0.19, 0.21), skin, head, 20)
    for x in (-0.075, 0.075):
        bpy.ops.mesh.primitive_torus_add(location=(x, 0.18, 1.55), major_radius=0.05, minor_radius=0.01, rotation=(math.radians(90), 0, 0))
        finish(bpy.context.active_object, "Glasses%+.0f" % (x * 100), mat("glasses", DARK), head)
        sphere("EyeT%+.0f" % (x * 100), (x, 0.17, 1.55), (0.02, 0.012, 0.025), mat("eye", DARK), head, 8)
    sphere("SmileT", (0, 0.17, 1.42), (0.06, 0.02, 0.015), mat("mouth", (0.75, 0.35, 0.35, 1)), head, 10)
    sphere("Cap", (0, 0, 1.66), (0.21, 0.21, 0.09), cap, head, 18)
    sphere("CapBobble", (0, 0, 1.76), (0.05,) * 3, button, head, 10)
    export("toy_maker")


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


def build_cow():
    reset()
    root = empty("Cow", (0, 0, 0))
    white, black = mat("cow_white", (0.97, 0.96, 0.93, 1)), mat("cow_black", (0.15, 0.13, 0.13, 1))
    quadruped(root, white, white, (0.42, 0.65, 0.36), (0, 0.72, 0.95), 0.4, black, 0.08)
    for x, y in ((0.2, 0.1), (-0.25, -0.25), (0.05, -0.4)):
        sphere("Spot%+.0f%+.0f" % (x * 10, y * 10), (x, y, 1.02), (0.16, 0.16, 0.04), black, root, 10)
    sphere("Snout", (0, 0.92, 0.88), (0.15, 0.08, 0.1), mat("snout_pink", (0.95, 0.70, 0.72, 1)), root, 12)
    for x in (-0.13, 0.13):
        cylinder("Horn%+.0f" % (x * 100), (x, 0.7, 1.17), 0.025, 0.12, mat("horn", (0.95, 0.88, 0.7, 1)), root, verts=6)
    eyes(root, (0, 0.72, 0.95))
    export("cow")


def build_sheep():
    reset()
    root = empty("Sheep", (0, 0, 0))
    wool, face = mat("wool", (0.98, 0.97, 0.94, 1)), mat("sheep_face", (0.25, 0.22, 0.22, 1))
    quadruped(root, wool, face, (0.36, 0.5, 0.32), (0, 0.55, 0.8), 0.32, face, 0.06)
    for x, y in ((0.2, 0.2), (-0.2, 0.1), (0.1, -0.25), (-0.15, -0.3), (0, 0.05)):
        sphere("Puff%+.0f%+.0f" % (x * 10, y * 10), (x, y, 0.82), (0.17,) * 3, wool, root, 10)
    eyes(root, (0, 0.55, 0.8), 0.08, 0.2)
    export("sheep")


def build_pig():
    reset()
    root = empty("Pig", (0, 0, 0))
    pink = mat("pig_pink", (0.97, 0.70, 0.74, 1))
    quadruped(root, pink, pink, (0.36, 0.5, 0.3), (0, 0.5, 0.62), 0.22, pink, 0.06)
    cylinder("PigSnout", (0, 0.72, 0.6), 0.08, 0.06, mat("snout", (0.92, 0.55, 0.62, 1)), root, (math.radians(90), 0, 0), 12)
    for x in (-0.13, 0.13):
        sphere("PigEar%+.0f" % (x * 100), (x, 0.5, 0.82), (0.07, 0.03, 0.06), pink, root, 8)
    eyes(root, (0, 0.5, 0.62), 0.08, 0.19)
    export("pig")


def build_duck():
    reset()
    root = empty("Duck", (0, 0, 0))
    yellow = mat("duck_yellow", (0.99, 0.86, 0.30, 1))
    sphere("DuckBody", (0, 0, 0.3), (0.28, 0.36, 0.24), yellow, root, 16)
    sphere("DuckHead", (0, 0.25, 0.62), (0.17,) * 3, yellow, root, 14)
    sphere("Beak", (0, 0.43, 0.6), (0.08, 0.07, 0.03), mat("beak", (0.98, 0.55, 0.18, 1)), root, 10)
    eyes(root, (0, 0.25, 0.62), 0.07, 0.14)
    export("duck")


def build_farmer():
    """The farmer: green overalls, a checked shirt colour, a straw hat. 1.75 m."""
    reset()
    root = empty("Farmer", (0, 0, 0))
    overalls, shirt, skin = mat("overalls", (0.30, 0.48, 0.38, 1)), mat("shirt", (0.85, 0.35, 0.30, 1)), mat("skin", (0.92, 0.74, 0.62, 1))
    limb("LegL", (-0.12, 0, 0.72), 0.65, 0.09, overalls, root, mat("boot", (0.35, 0.25, 0.2, 1)))
    limb("LegR", (0.12, 0, 0.72), 0.65, 0.09, overalls, root, mat("boot", (0.35, 0.25, 0.2, 1)))
    body = empty("Body", (0, 0, 0.72), root)
    sphere("Shirt", (0, 0, 1.1), (0.31, 0.24, 0.36), shirt, body)
    box("Bib", (0, 0.2, 1.0), (0.36, 0.06, 0.4), overalls, body, 0.03)
    for side, x in (("L", -0.33), ("R", 0.33)):
        limb("Arm" + side, (x, 0, 1.36), 0.5, 0.08, shirt, root, skin)
    head = empty("Head", (0, 0, 1.58), root)
    sphere("Face", (0, 0, 1.62), (0.2, 0.19, 0.22), skin, head, 20)
    for x in (-0.07, 0.07):
        sphere("EyeF%+.0f" % (x * 100), (x, 0.17, 1.67), (0.025, 0.015, 0.03), mat("eye", DARK), head, 8)
    sphere("SmileF", (0, 0.17, 1.54), (0.06, 0.02, 0.015), mat("mouth", (0.75, 0.35, 0.35, 1)), head, 10)
    cylinder("HatBrim", (0, 0, 1.8), 0.36, 0.03, mat("straw", (0.93, 0.80, 0.45, 1)), head, verts=20)
    cylinder("HatTop", (0, 0, 1.88), 0.19, 0.16, mat("straw", (0.93, 0.80, 0.45, 1)), head, verts=16)
    export("farmer")


def build_clock_maker():
    """The clock maker: a brown waistcoat, a white beard, round glasses, a flat cap. 1.7 m."""
    reset()
    root = empty("ClockMaker", (0, 0, 0))
    vest, shirt, skin = mat("vest", (0.50, 0.36, 0.26, 1)), mat("shirt", (0.95, 0.93, 0.88, 1)), mat("skin", (0.94, 0.78, 0.66, 1))
    limb("LegL", (-0.12, 0, 0.7), 0.63, 0.08, mat("trousers", (0.30, 0.30, 0.38, 1)), root, mat("shoe", DARK))
    limb("LegR", (0.12, 0, 0.7), 0.63, 0.08, mat("trousers", (0.30, 0.30, 0.38, 1)), root, mat("shoe", DARK))
    body = empty("Body", (0, 0, 0.7), root)
    sphere("Shirt", (0, 0, 1.08), (0.3, 0.23, 0.35), shirt, body)
    sphere("Vest", (0, 0.04, 1.06), (0.31, 0.22, 0.3), vest, body)
    sphere("Watch", (0.12, 0.25, 1.05), (0.05, 0.02, 0.05), mat("gold", (0.95, 0.80, 0.30, 1)), body, 10)
    for side, x in (("L", -0.32), ("R", 0.32)):
        limb("Arm" + side, (x, 0, 1.33), 0.48, 0.075, shirt, root, skin)
    head = empty("Head", (0, 0, 1.55), root)
    sphere("Face", (0, 0, 1.6), (0.2, 0.19, 0.22), skin, head, 20)
    sphere("Beard", (0, 0.1, 1.48), (0.17, 0.12, 0.13), mat("beard", (0.97, 0.97, 0.97, 1)), head, 14)
    for x in (-0.075, 0.075):
        bpy.ops.mesh.primitive_torus_add(location=(x, 0.18, 1.65), major_radius=0.05, minor_radius=0.01, rotation=(math.radians(90), 0, 0))
        finish(bpy.context.active_object, "GlassesC%+.0f" % (x * 100), mat("glasses", DARK), head)
        sphere("EyeC%+.0f" % (x * 100), (x, 0.17, 1.65), (0.02, 0.012, 0.025), mat("eye", DARK), head, 8)
    sphere("CapC", (0, 0.03, 1.77), (0.22, 0.24, 0.07), mat("flatcap", (0.35, 0.40, 0.50, 1)), head, 18)
    export("clock_maker")


build_tygrytsa()
build_hatchback()
build_jeep()
build_van()
build_hata()
build_tree()
build_sunflower()
build_fence()
build_well()
build_postman()
build_ferry()
build_english_house()
build_shop("bakery", (0.96, 0.66, 0.30, 1))
build_shop("cafe", (0.45, 0.68, 0.55, 1))
build_shop("toy_shop", (0.55, 0.45, 0.82, 1))
build_clock_tower()
build_bus_stop()
build_barn()
build_lamp()
build_baker()
build_toy_maker()
build_cow()
build_sheep()
build_pig()
build_duck()
build_farmer()
build_clock_maker()
