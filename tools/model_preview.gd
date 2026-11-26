extends SceneTree
## Dev helper: shows every model in assets/models in the painted look and saves
## build/shots/models.png. Run: godot --path . --script res://tools/model_preview.gd

## Pass model names after `--` to preview only those; default: the first four.
const MODELS: Array[String] = ["tygrytsa", "car_hatchback", "car_jeep", "car_van"]

var _frame: int = 0


func _initialize() -> void:
	var world: Node3D = Node3D.new()
	root.add_child(world)
	var env: WorldEnvironment = WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.85, 0.9, 0.95)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.56, 0.62, 0.82)
	env.environment.ambient_light_energy = 0.42
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.add_child(env)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.86, 0.66)
	sun.rotation_degrees = Vector3(-45, -30, 0)
	sun.shadow_enabled = true
	world.add_child(sun)
	var ground: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(30, 30)
	plane.material = PaintedMaterials.make(Color(0.5, 0.72, 0.38))
	ground.mesh = plane
	world.add_child(ground)
	var names: Array[String] = MODELS.duplicate()
	if not OS.get_cmdline_user_args().is_empty():
		names = []
		for arg: String in OS.get_cmdline_user_args():
			names.append(arg)
	var x: float = -6.0
	for model_name: String in names:
		var model: Node3D = ModelPainter.load_model(model_name)
		model.position = Vector3(x, 0, 0)
		model.rotation_degrees.y = 200.0
		world.add_child(model)
		x += 4.0 if model_name in ["tygrytsa", "sunflower"] else 5.5
	var cam: Camera3D = Camera3D.new()
	cam.fov = 50.0
	world.add_child(cam)
	cam.look_at_from_position(Vector3(0.5, 4.5, 9.5), Vector3(0.5, 0.8, 0))


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 30:
		var path: String = ProjectSettings.globalize_path("res://build/shots/models.png")
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		var err: Error = root.get_viewport().get_texture().get_image().save_png(path)
		print("saved " if err == OK else "could not save ", path, " ", error_string(err))
		return true
	return false
