class_name CardStage
extends Node3D
## The learning card's little theatre: while a sentence is spoken ("The car goes over the
## bridge."), the card's picture shows that sentence happening, as a small looping scene in its
## own world. Scenes are data: content/words/scenes.csv (sentence, ground, actors, zoom), see
## docs/contracts/card-scenes.md. Each actor is "thing action x z [more]", separated by ";".

const SCENES_PATH: String = "res://content/words/scenes.csv"
const CAMERA_OFFSET: Vector3 = Vector3(0, 2.4, 5.2)
const LOOK_AT: Vector3 = Vector3(0, 0.6, 0)
const PAINTED_SKY: Shader = preload("res://game/art/painted_sky.gdshader")
const GRASS: Color = Color(0.55, 0.78, 0.4)
const WATER: Color = Color(0.24, 0.5, 0.78)
## Things that walk with a bob and wave their arms (characters and animals).
const WALKERS: Array[String] = [
	"tygrytsa",
	"baker",
	"postman",
	"farmer",
	"toymaker",
	"clockmaker",
	"dog",
	"cat",
	"lion",
	"cow",
	"sheep",
	"pig",
	"duck",
	"hen"
]

static var _scenes: Dictionary[String, PackedStringArray] = {}
static var _loaded: bool = false

var _actors: Array[Dictionary] = []
var _time: float = 0.0
var _has_bridge: bool = false


## True when this sentence has a scene.
static func has_scene(sentence: String) -> bool:
	_load()
	return _scenes.has(sentence.strip_edges())


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var file: FileAccess = FileAccess.open(SCENES_PATH, FileAccess.READ)
	if file == null:
		push_warning("CardStage: cannot open %s" % SCENES_PATH)
		return
	file.get_csv_line()
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() >= 3 and not row[0].is_empty():
			_scenes[row[0].strip_edges()] = row


## Builds the scene for a sentence (replacing the last one) and points the camera at it.
func show_sentence(sentence: String, camera: Camera3D) -> void:
	_load()
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_actors.clear()
	_time = 0.0
	var row: PackedStringArray = _scenes.get(sentence.strip_edges(), PackedStringArray())
	if row.is_empty():
		return
	var ground: String = row[1].strip_edges()
	_build_ground(ground)
	_has_bridge = row[2].contains("bridge ")
	for spec: String in row[2].split(";", false):
		var parts: PackedStringArray = spec.strip_edges().split(" ", false)
		if parts.size() >= 4:
			_add_actor(parts)
	var zoom: float = float(row[3]) if row.size() > 3 and not row[3].strip_edges().is_empty() else 1.0
	camera.look_at_from_position(CAMERA_OFFSET * zoom, LOOK_AT * zoom)


func _process(delta: float) -> void:
	_time += delta
	for actor: Dictionary in _actors:
		_animate(actor)


# --- grounds -------------------------------------------------------------------------


func _build_ground(kind: String) -> void:
	# The same light as the town (golden morning, painted sky), so the scene looks like the game.
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky: Sky = Sky.new()
	var sky_mat: ShaderMaterial = ShaderMaterial.new()
	sky_mat.shader = PAINTED_SKY
	sky.sky_material = sky_mat
	sky.process_mode = Sky.PROCESS_MODE_QUALITY
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.56, 0.62, 0.82)
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.92
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	env.adjustment_contrast = 1.04
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.86, 0.66)
	sun.light_energy = 0.95
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.shadow_enabled = true
	var floor_color: Color = GRASS
	match kind:
		"night":
			env.background_mode = Environment.BG_COLOR
			env.background_color = Color(0.12, 0.16, 0.32)
			env.ambient_light_color = Color(0.45, 0.5, 0.75)
			sun.light_energy = 0.25
			floor_color = Color(0.22, 0.38, 0.28)
			for i: int in 14:
				var star: MeshInstance3D = Blocks.flat_mesh(
					SphereMesh.new(),
					Color(1, 0.95, 0.7),
					Vector3(randf_range(-7, 7), randf_range(3.5, 6.5), -4.0)
				)
				star.scale = Vector3.ONE * 0.08
				add_child(star)
		"kitchen":
			env.background_mode = Environment.BG_COLOR
			env.background_color = Color(0.98, 0.9, 0.78)
			floor_color = Color(0.66, 0.46, 0.3)
			add_child(Blocks.box_mesh(Vector3(14, 6, 0.2), Color(0.95, 0.78, 0.58), Vector3(0, 3, -3.5)))
		"town":
			floor_color = Color(0.62, 0.6, 0.58)
		"sea":
			floor_color = Color(0.86, 0.74, 0.5)
	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	add_child(sun)
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = 9.0
	disc.bottom_radius = 9.0
	disc.height = 0.2
	add_child(Blocks.mesh(disc, floor_color, Vector3(0, -0.1, 0)))
	match kind:
		"river":
			add_child(Blocks.box_mesh(Vector3(3.0, 0.1, 18), WATER, Vector3(0, -0.02, 0)))
		"road":
			add_child(Blocks.box_mesh(Vector3(18, 0.04, 1.9), Color(0.5, 0.5, 0.52), Vector3(0, 0.0, 0)))
			for i: int in 9:
				add_child(
					Blocks.box_mesh(
						Vector3(0.7, 0.05, 0.12), Color(0.98, 0.95, 0.85), Vector3(-8 + i * 2.0, 0.01, 0)
					)
				)
		"sea":
			add_child(Blocks.box_mesh(Vector3(18, 0.1, 9), WATER, Vector3(0, -0.02, -2.0)))
		"grass", "farm", "night":
			for i: int in 10:
				var tuft: MeshInstance3D = Blocks.box_mesh(
					Vector3(0.06, 0.25, 0.06),
					floor_color.darkened(0.15),
					Vector3(randf_range(-6, 6), 0.1, randf_range(-3, 3))
				)
				tuft.rotation.z = randf_range(-0.3, 0.3)
				add_child(tuft)
	if kind == "farm":
		var fence: Node3D = Props.make(&"fence")
		fence.position = Vector3(0, 0, -3.0)
		add_child(fence)


# --- actors --------------------------------------------------------------------------


func _add_actor(parts: PackedStringArray) -> void:
	var thing: String = parts[0]
	var action: String = parts[1]
	var start: Vector3 = Vector3(float(parts[2]), 0, float(parts[3]))
	var extra: PackedStringArray = parts.slice(4)
	if action == "count":
		var n: int = int(extra[0]) if not extra.is_empty() else 3
		for i: int in n:
			var copy: Node3D = _make(thing)
			copy.position = start + Vector3((i - (n - 1) / 2.0) * 1.1, 0, 0)
			add_child(copy)
			_actors.append({"node": copy, "action": "count", "index": i, "n": n})
		return
	var node: Node3D = _make(thing)
	node.position = start
	add_child(node)
	var actor: Dictionary = {"node": node, "action": action, "start": start, "walker": WALKERS.has(thing)}
	if extra.size() >= 2 and extra[0].is_valid_float() and extra[1].is_valid_float():
		actor["end"] = Vector3(float(extra[0]), 0, float(extra[1]))
		actor["speed"] = float(extra[2]) if extra.size() > 2 and extra[2].is_valid_float() else 1.6
	if action == "say" and not extra.is_empty():
		var bubble: Label3D = Blocks.label(" ".join(extra), 2.4, 72)
		bubble.modulate = Color(0.2, 0.2, 0.25)
		bubble.outline_modulate = Color.WHITE
		bubble.no_depth_test = false
		node.add_child(bubble)
		actor["bubble"] = bubble
	if action == "float":
		actor["height"] = float(extra[0]) if not extra.is_empty() else 3.0
	if action == "glow":
		var light: OmniLight3D = OmniLight3D.new()
		light.light_color = Color(1.0, 0.85, 0.55)
		light.omni_range = 5.0
		light.position = Vector3(0, 2.8, 0.4)
		node.add_child(light)
		actor["light"] = light
	node.set_meta("arm_l", node.find_child("ArmL", true, false))
	node.set_meta("arm_r", node.find_child("ArmR", true, false))
	_actors.append(actor)


## A thing facing +z (towards the camera): the models from assets/models face -z, so they are
## turned round inside a holder.
func _make(thing: String) -> Node3D:
	var art: Node3D = Props.make(StringName(thing))
	if not Props.is_model(StringName(thing)):
		return art
	var holder: Node3D = Node3D.new()
	art.rotation.y = PI
	holder.add_child(art)
	return holder


func _animate(actor: Dictionary) -> void:
	var node: Node3D = actor["node"]
	var t: float = _time
	match actor["action"]:
		"stand":
			node.scale = Vector3.ONE * (1.0 + sin(t * 2.0) * 0.015)
		"move", "swim", "kick", "arrive":
			_move(actor, t)
		"say":
			var hop: float = fmod(t, 1.6)
			node.position.y = absf(sin(hop * PI / 0.4)) * 0.25 if hop < 0.4 else 0.0
			(actor["bubble"] as Label3D).visible = fmod(t, 1.6) < 1.1
		"wave":
			_wave(node, t)
		"grow":
			node.scale = Vector3.ONE * (0.85 + 0.25 * (0.5 + 0.5 * sin(t * 1.6)))
		"count":
			var at: float = fmod(t, actor["n"] * 0.9 + 2.0) - actor["index"] * 0.9
			node.visible = at > 0.0
			node.scale = Vector3.ONE * clampf(at * 4.0, 0.0, 1.0)
		"fly":
			var k: float = fmod(t, 5.0) / 5.0
			node.position.y = k * 4.0
			node.position.x = actor["start"].x + sin(t * 1.5) * 0.3
		"spin":
			node.rotation.y = t * 1.5
		"float":
			node.position.y = actor["height"] + sin(t * 1.4) * 0.12
		"eat":
			var bites: int = int(fmod(t, 4.0) / 0.9)
			node.scale = Vector3.ONE * maxf(0.25, 1.0 - bites * 0.25)
		"glow":
			(actor["light"] as OmniLight3D).light_energy = 1.6 + sin(t * 2.0) * 0.3
		"open":
			var leaf: Node3D = node.find_child("Leaf", true, false) as Node3D
			if leaf != null:
				leaf.rotation.y = -1.5 * clampf(0.5 + sin(t * 0.9) * 0.9, 0.0, 1.0)
		"tick":
			var hand: Node3D = node.find_child("Hand", true, false) as Node3D
			if hand != null:
				hand.rotation.z = -floorf(t * 2.0) * TAU / 12.0
			node.rotation.z = sin(t * PI * 2.0) * 0.02


## Along the path from start to end (looping; "arrive" stops at the end for a while), facing
## the way it goes; walkers bob; over a bridge the height follows the deck.
func _move(actor: Dictionary, t: float) -> void:
	var node: Node3D = actor["node"]
	var from: Vector3 = actor["start"]
	var to: Vector3 = actor.get("end", from)
	var length: float = maxf(0.1, from.distance_to(to))
	var trip: float = length / float(actor.get("speed", 1.6))
	var k: float = 0.0
	if actor["action"] == "arrive":
		k = minf(1.0, fmod(t, trip + 2.5) / trip)
		k = 1.0 - pow(1.0 - k, 2.0)
	else:
		k = fmod(t, trip + 0.6) / trip
		node.visible = k <= 1.0
		k = minf(k, 1.0)
	var p: Vector3 = from.lerp(to, k)
	var y: float = 0.0
	if _has_bridge and absf(p.x) < 3.0 and absf(p.z) < 0.8 and actor["action"] != "swim":
		y = Props.bridge_height(p.x) + 0.06
	match actor["action"]:
		"swim":
			node.rotation.z = sin(t * 3.0) * 0.06
		"kick":
			y += absf(sin(k * PI * 3.0)) * 0.6
			node.rotation.x = k * TAU * 2.0
	if actor["walker"] and actor["action"] != "swim":
		y += absf(sin(t * 8.0)) * 0.08
	node.position = Vector3(p.x, y, p.z)
	var dir: Vector3 = to - from
	if dir.length() > 0.01 and actor["action"] != "kick":
		node.rotation.y = atan2(dir.x, dir.z)


func _wave(node: Node3D, t: float) -> void:
	var arm_l: Node3D = node.get_meta("arm_l") as Node3D
	var arm_r: Node3D = node.get_meta("arm_r") as Node3D
	if arm_r == null:
		node.position.y = absf(sin(t * 4.0)) * 0.2
		return
	var w: float = sin(t * 8.0) * 0.4
	arm_r.rotation = Vector3(-2.6, 0.0, w)
	if arm_l != null:
		arm_l.rotation = Vector3(-2.6, 0.0, -w)
