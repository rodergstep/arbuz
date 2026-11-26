class_name FestivalDecor
extends Node3D
## The festival on the square (the finale): flag garlands from the clock tower, balloon
## bunches, a table with the baker's cake, the farm animals, and a gentle burst of confetti
## when everybody cheers. Pure decoration: nothing here blocks the way or can be clicked.

const FLAG_COLORS: Array[Color] = [
	Color(0.88, 0.22, 0.24), Color(0.98, 0.82, 0.20), Color(0.25, 0.48, 0.88), Color(0.30, 0.70, 0.36)
]
const TOWER_TOP: Vector3 = Vector3(0, 5.2, 5.4)
const POLES: Array[Vector3] = [Vector3(-8, 0, 10), Vector3(8, 0, 10)]
const POLE_HEIGHT: float = 2.8
const BALLOON_BUNCHES: Array[Vector3] = [Vector3(-9, 0, 7.5), Vector3(9, 0, 7.5)]
const CAKE_TABLE: Vector3 = Vector3(-6.5, 0, 13)
const ANIMALS: Dictionary[String, Vector3] = {
	"cow": Vector3(7, 0, 12.5),
	"sheep": Vector3(9, 0, 12),
	"pig": Vector3(6.5, 0, 14.5),
	"duck": Vector3(8.5, 0, 14)
}

var _time: float = 0.0
var _bunches: Array[Node3D] = []


func _ready() -> void:
	for pole: Vector3 in POLES:
		add_child(
			Blocks.box_mesh(
				Vector3(0.14, POLE_HEIGHT, 0.14),
				Color(0.95, 0.93, 0.88),
				pole + Vector3(0, POLE_HEIGHT / 2.0, 0)
			)
		)
		_garland(TOWER_TOP, pole + Vector3(0, POLE_HEIGHT, 0))
	_garland(POLES[0] + Vector3(0, POLE_HEIGHT, 0), CAKE_TABLE + Vector3(-2, 2.4, 1.5))
	_garland(POLES[1] + Vector3(0, POLE_HEIGHT, 0), ANIMALS["sheep"] + Vector3(2, 2.4, 2))
	for spot: Vector3 in BALLOON_BUNCHES:
		_balloon_bunch(spot)
	_cake_table()
	for animal: String in ANIMALS:
		var model: Node3D = ModelPainter.load_model(animal)
		add_child(model)
		model.position = ANIMALS[animal]
		model.rotation.y = PI + randf_range(-0.4, 0.4)


## A gentle burst of confetti over the square (slow, soft colours, no flashing).
func cheer() -> void:
	var confetti: CPUParticles3D = CPUParticles3D.new()
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(0.16, 0.1)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	quad.material = mat
	confetti.mesh = quad
	confetti.amount = 140
	confetti.lifetime = 4.0
	confetti.one_shot = true
	confetti.explosiveness = 0.85
	confetti.direction = Vector3.UP
	confetti.spread = 50.0
	confetti.initial_velocity_min = 5.0
	confetti.initial_velocity_max = 8.0
	confetti.gravity = Vector3(0, -3.0, 0)
	confetti.damping_min = 1.5
	confetti.damping_max = 2.5
	confetti.angular_velocity_min = -180.0
	confetti.angular_velocity_max = 180.0
	var ramp: Gradient = Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.33, 0.66, 1.0])
	ramp.colors = PackedColorArray(FLAG_COLORS)
	ramp.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	confetti.color_initial_ramp = ramp
	add_child(confetti)
	confetti.position = Vector3(0, 3.0, 10)
	confetti.emitting = true
	confetti.finished.connect(confetti.queue_free)
	Sfx.play(&"tune")


func _process(delta: float) -> void:
	_time += delta
	for i: int in _bunches.size():
		_bunches[i].rotation.z = sin(_time * 1.2 + i) * 0.06


## Little triangle flags hanging along a sagging string between two points.
func _garland(from: Vector3, to: Vector3) -> void:
	var flags: int = int(from.distance_to(to) / 0.7)
	for i: int in flags + 1:
		var k: float = float(i) / maxf(1.0, float(flags))
		var p: Vector3 = from.lerp(to, k) + Vector3(0, -sin(k * PI) * 0.8, 0)
		var flag: PrismMesh = PrismMesh.new()
		flag.size = Vector3(0.34, 0.42, 0.03)
		var inst: MeshInstance3D = Blocks.mesh(
			flag, FLAG_COLORS[i % FLAG_COLORS.size()], p + Vector3(0, -0.22, 0)
		)
		inst.rotation = Vector3(0, atan2(-(to - from).x, -(to - from).z) + PI / 2.0, PI)
		add_child(inst)


func _balloon_bunch(spot: Vector3) -> void:
	var bunch: Node3D = Node3D.new()
	bunch.position = spot
	add_child(bunch)
	_bunches.append(bunch)
	var offsets: Array[Vector3] = [
		Vector3(0, 2.6, 0), Vector3(0.5, 2.3, 0.2), Vector3(-0.5, 2.35, -0.1), Vector3(0.1, 2.2, 0.55)
	]
	for i: int in offsets.size():
		var ball: SphereMesh = SphereMesh.new()
		ball.radius = 0.36
		ball.height = 0.86
		bunch.add_child(Blocks.mesh(ball, FLAG_COLORS[i], offsets[i]))
		var string: MeshInstance3D = Blocks.box_mesh(
			Vector3(0.02, offsets[i].y - 0.3, 0.02), Color(0.95, 0.95, 0.95)
		)
		string.position = offsets[i] * Vector3(0.5, 0, 0.5) + Vector3(0, (offsets[i].y - 0.3) / 2.0, 0)
		bunch.add_child(string)


## A round table with a white cloth and a big layered cake with a cherry on top.
func _cake_table() -> void:
	var top: CylinderMesh = CylinderMesh.new()
	top.top_radius = 1.0
	top.bottom_radius = 1.0
	top.height = 0.1
	add_child(Blocks.mesh(top, Color(0.98, 0.97, 0.94), CAKE_TABLE + Vector3(0, 0.85, 0)))
	add_child(
		Blocks.box_mesh(Vector3(0.16, 0.8, 0.16), Color(0.62, 0.44, 0.30), CAKE_TABLE + Vector3(0, 0.4, 0))
	)
	var layers: Array[Array] = [[0.55, Color(0.96, 0.80, 0.62)], [0.4, Color(0.98, 0.72, 0.78)]]
	var y: float = 0.9
	for layer: Array in layers:
		var cake: CylinderMesh = CylinderMesh.new()
		cake.top_radius = layer[0]
		cake.bottom_radius = layer[0]
		cake.height = 0.3
		add_child(Blocks.mesh(cake, layer[1], CAKE_TABLE + Vector3(0, y + 0.15, 0)))
		y += 0.3
	var cherry: SphereMesh = SphereMesh.new()
	cherry.radius = 0.1
	cherry.height = 0.2
	add_child(Blocks.mesh(cherry, Color(0.85, 0.15, 0.2), CAKE_TABLE + Vector3(0, y + 0.08, 0)))
