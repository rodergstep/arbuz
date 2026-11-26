class_name ModelPainter
extends RefCounted
## Loads a .glb model from assets/models and gives every surface the shared painted shader,
## keeping each material's own colour, so imported models match the rest of the world.

const MODELS_DIR: String = "res://assets/models"

static var _merged: Dictionary[String, ArrayMesh] = {}


static func load_model(model_name: String) -> Node3D:
	var scene: PackedScene = load("%s/%s.glb" % [MODELS_DIR, model_name])
	if scene == null:
		push_warning("ModelPainter: missing model %s" % model_name)
		return Node3D.new()
	var model: Node3D = scene.instantiate()
	paint(model)
	return model


static func paint(root: Node) -> void:
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_inst: MeshInstance3D = node
		for i: int in mesh_inst.mesh.get_surface_count():
			var original: Material = mesh_inst.get_active_material(i)
			var color: Color = Color.WHITE
			if original is BaseMaterial3D:
				color = (original as BaseMaterial3D).albedo_color
			mesh_inst.set_surface_override_material(i, PaintedMaterials.make(color))


## A static prop as one mesh: all parts merged, one surface per colour, painted. Far fewer draw
## calls than the imported node tree (important for many props on the Intel MacBook).
## Surfaces whose colour is in `sway_colors` sway in the wind (leaves, petals).
## Nodes whose name is in `exclude` are left out (e.g. a model's own door).
static func merged_mesh(
	model_name: String, sway_colors: Array[Color] = [], sway: float = 0.06, exclude: Array[String] = []
) -> ArrayMesh:
	var key: String = "%s|%s|%s|%s" % [model_name, sway_colors, sway, exclude]
	if _merged.has(key):
		return _merged[key]
	var scene: PackedScene = load("%s/%s.glb" % [MODELS_DIR, model_name])
	var out: ArrayMesh = ArrayMesh.new()
	if scene == null:
		push_warning("ModelPainter: missing model %s" % model_name)
		return out
	var model: Node3D = scene.instantiate()
	var groups: Dictionary[String, SurfaceTool] = {}
	var colors: Dictionary[String, Color] = {}
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_inst: MeshInstance3D = node
		if exclude.has(String(mesh_inst.name)):
			continue
		var xform: Transform3D = _relative_transform(mesh_inst, model)
		for i: int in mesh_inst.mesh.get_surface_count():
			var original: Material = mesh_inst.get_active_material(i)
			var color: Color = (
				(original as BaseMaterial3D).albedo_color if original is BaseMaterial3D else Color.WHITE
			)
			var color_key: String = color.to_html()
			if not groups.has(color_key):
				var st: SurfaceTool = SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				groups[color_key] = st
				colors[color_key] = color
			groups[color_key].append_from(mesh_inst.mesh, i, xform)
	model.free()
	for color_key: String in groups:
		var color: Color = colors[color_key]
		var sways: bool = sway_colors.any(func(c: Color) -> bool: return _close(c, color))
		groups[color_key].commit(out)
		out.surface_set_material(
			out.get_surface_count() - 1, PaintedMaterials.make(color, sway if sways else 0.0)
		)
	_merged[key] = out
	return out


static func _close(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) < 0.03


static func _relative_transform(node: Node3D, root: Node3D) -> Transform3D:
	var xform: Transform3D = node.transform
	var parent: Node = node.get_parent()
	while parent != null and parent != root:
		if parent is Node3D:
			xform = (parent as Node3D).transform * xform
		parent = parent.get_parent()
	return xform
