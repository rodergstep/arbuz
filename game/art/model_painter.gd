class_name ModelPainter
extends RefCounted
## Loads a .glb model from assets/models and gives every surface the shared painted shader,
## keeping each material's own colour, so imported models match the rest of the world.

const MODELS_DIR: String = "res://assets/models"


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
