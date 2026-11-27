"""Brings a free CC0 model (Kenney, Quaternius) into the game's format.

Run: Blender --background --factory-startup --disable-autoexec --python tools/blender/import_cc0.py -- \
       <source .glb/.gltf/.blend/.fbx> <name> [length_m] [yaw_deg]
Writes assets/models/<name>.glb.

What it does: a model coloured by a palette texture (Kenney) gets one plain material per colour
(each face takes the colour under its UVs), because the game repaints every material with its
painted shader by colour. The model is scaled so its longest side is length_m (when given),
turned by yaw_deg, stood on the ground, and faces Blender +Y like our own models.
Sources and licences: assets/models/CREDITS.md.
"""
import os
import sys

import bpy

argv = sys.argv[sys.argv.index("--") + 1:]
src, name = argv[0], argv[1]
length = float(argv[2]) if len(argv) > 2 else 0.0
yaw = float(argv[3]) if len(argv) > 3 else 0.0
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "models", name + ".glb")

bpy.ops.wm.read_factory_settings(use_empty=True)
ext = os.path.splitext(src)[1].lower()
if ext in (".glb", ".gltf"):
    bpy.ops.import_scene.gltf(filepath=src)
elif ext == ".fbx":
    bpy.ops.import_scene.fbx(filepath=src)
elif ext == ".blend":
    with bpy.data.libraries.load(src, link=False) as (data_from, data_to):
        data_to.objects = list(data_from.objects)
    for o in data_to.objects:
        if o is not None:
            bpy.context.collection.objects.link(o)

_mats = {}


def to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def flat_material(rgb, srgb=False):
    # Similar colours share one material (fewer draw calls); texture pixels are sRGB.
    if srgb:
        rgb = tuple(round(c * 20) / 20 for c in rgb)
        rgb = tuple(to_linear(c) for c in rgb)
    key = tuple(round(c * 64) / 64 for c in rgb)
    if key not in _mats:
        m = bpy.data.materials.new("c%02x%02x%02x" % tuple(int(c * 255) for c in key))
        m.use_nodes = True
        m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*key, 1.0)
        m.diffuse_color = (*key, 1.0)
        _mats[key] = m
    return _mats[key]


def texture_of(material):
    if material is None or not material.use_nodes:
        return None
    for node in material.node_tree.nodes:
        if node.type == "TEX_IMAGE" and node.image is not None:
            return node.image
    return None


def base_colour(material):
    if material is None:
        return (0.8, 0.8, 0.8)
    if material.use_nodes and "Principled BSDF" in material.node_tree.nodes:
        c = material.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value
        return (c[0], c[1], c[2])
    return tuple(material.diffuse_color[:3])


meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
for obj in meshes:
    me = obj.data
    old = list(me.materials)
    uv = me.uv_layers.active
    pixels_cache = {}
    new_index = {}
    face_mats = []
    for poly in me.polygons:
        m = old[poly.material_index] if poly.material_index < len(old) else None
        img = texture_of(m)
        if img is not None and uv is not None:
            if img.name not in pixels_cache:
                pixels_cache[img.name] = (list(img.pixels[:]), img.size[0], img.size[1])
            px, w, h = pixels_cache[img.name]
            u = sum(uv.data[li].uv[0] for li in poly.loop_indices) / poly.loop_total
            v = sum(uv.data[li].uv[1] for li in poly.loop_indices) / poly.loop_total
            x = min(w - 1, max(0, int((u % 1.0) * w)))
            y = min(h - 1, max(0, int((v % 1.0) * h)))
            i = (y * w + x) * 4
            face_mats.append(flat_material((px[i], px[i + 1], px[i + 2]), True))
        else:
            face_mats.append(flat_material(base_colour(m)))
    me.materials.clear()
    for fm in face_mats:
        if fm.name not in new_index:
            me.materials.append(fm)
            new_index[fm.name] = len(me.materials) - 1
    for poly, fm in zip(me.polygons, face_mats):
        poly.material_index = new_index[fm.name]

# Scale, turn and stand on the ground (all top-level objects together).
bpy.context.view_layer.update()
pts = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
lo = [min(p[i] for p in pts) for i in range(3)]
hi = [max(p[i] for p in pts) for i in range(3)]
size = max(hi[i] - lo[i] for i in range(3))
scale = length / size if length > 0 else 1.0
bpy.ops.object.empty_add(location=(0, 0, 0))
pivot = bpy.context.active_object
pivot.name = name
cx, cy = (lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2
for o in bpy.context.scene.objects:
    if o.parent is None and o is not pivot:
        o.location.x -= cx
        o.location.y -= cy
        o.location.z -= lo[2]
        o.parent = pivot
import math
pivot.scale = (scale, scale, scale)
pivot.rotation_euler = (0, 0, math.radians(yaw))
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", export_apply=True, export_yup=True, export_animations=True)
print("wrote", OUT, "materials:", len(_mats), "scale:", round(scale, 3))
