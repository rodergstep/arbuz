class_name ModelPainter
extends RefCounted
## Loads a .glb model from assets/models and gives every surface the shared painted shader,
## keeping each material's own colour, so imported models match the rest of the world.

const MODELS_DIR: String = "res://assets/models"
## Rigged CC0 models keep their own size in the file (scaling a rig breaks its animations), so
## they are scaled here (from the values printed by tools/blender/import_cc0.py, a little bigger
## so a toddler spots them).
const SCALES: Dictionary[String, float] = {
	"cow": 0.28,
	"pig": 0.165,
	"sheep": 0.27,
	"dog": 0.3,
}
## Their idle animation plays on its own, so animals breathe and look around.
const IDLE_NAMES: Array[String] = ["Idle", "idle", "Idle_2", "Eating"]

static var _merged: Dictionary[String, ArrayMesh] = {}


static func load_model(model_name: String) -> Node3D:
	var scene: PackedScene = load("%s/%s.glb" % [MODELS_DIR, model_name])
	if scene == null:
		push_warning("ModelPainter: missing model %s" % model_name)
		return Node3D.new()
	var model: Node3D = scene.instantiate()
	paint(model)
	if SCALES.has(model_name):
		var holder: Node3D = Node3D.new()
		holder.name = model_name
		model.scale = Vector3.ONE * SCALES[model_name]
		holder.add_child(model)
		_play_idle(model)
		return holder
	return model


## Plays a model's animation by name (when it has one); false when it doesn't.
static func play(model: Node3D, animation: String) -> bool:
	var players: Array[Node] = model.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty() or not (players[0] as AnimationPlayer).has_animation(animation):
		return false
	var player: AnimationPlayer = players[0]
	player.get_animation(animation).loop_mode = Animation.LOOP_LINEAR
	player.play(animation)
	return true


static func _play_idle(model: Node3D) -> void:
	var players: Array[Node] = model.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return
	var player: AnimationPlayer = players[0]
	for idle: String in IDLE_NAMES:
		if player.has_animation(idle):
			player.get_animation(idle).loop_mode = Animation.LOOP_LINEAR
			player.play(idle)
			return


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
