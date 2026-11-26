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


build_tygrytsa()
build_hatchback()
build_jeep()
build_van()
