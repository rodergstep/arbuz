class_name GoalMarker
extends Node3D
## The glowing marker that shows where to go. Pulses gently; gets brighter as hints escalate.
## Emits reached when the hero or the car enters it.

signal reached(body: Node3D)

const RADIUS: float = 1.6
const BASE_ENERGY: float = 1.2

var brightness_level: int = 0

var _mat: StandardMaterial3D
var _ring: MeshInstance3D
var _time: float = 0.0
var _active: bool = true


func _ready() -> void:
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = RADIUS
	cyl.bottom_radius = RADIUS
	cyl.height = 0.08
	_ring = Blocks.mesh(cyl, Color(1.0, 0.85, 0.3), Vector3(0, 0.05, 0))
	_mat = _ring.mesh.material
	_mat.emission_enabled = true
	_mat.emission = Color(1.0, 0.8, 0.25)
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.albedo_color.a = 0.7
	add_child(_ring)
	var beam: CylinderMesh = CylinderMesh.new()
	beam.top_radius = 0.15
	beam.bottom_radius = 0.5
	beam.height = 4.0
	var beam_inst: MeshInstance3D = Blocks.mesh(beam, Color(1.0, 0.9, 0.5), Vector3(0, 2.0, 0))
	var beam_mat: StandardMaterial3D = beam_inst.mesh.material
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.albedo_color.a = 0.25
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	add_child(beam_inst)
	var area: Area3D = Area3D.new()
	area.collision_layer = 0
	area.collision_mask = Blocks.LAYER_HERO | Blocks.LAYER_CAR
	var shape: CollisionShape3D = CollisionShape3D.new()
	var s: CylinderShape3D = CylinderShape3D.new()
	s.radius = RADIUS
	s.height = 3.0
	shape.shape = s
	shape.position.y = 1.5
	area.add_child(shape)
	area.body_entered.connect(_on_body_entered)
	add_child(area)


func set_brightness(level: int) -> void:
	brightness_level = level


func _process(delta: float) -> void:
	_time += delta
	var pulse: float = 0.5 + 0.5 * sin(_time * 2.5)
	_mat.emission_energy_multiplier = (
		BASE_ENERGY * (1.0 + brightness_level) + pulse * (0.6 + brightness_level)
	)
	var s: float = 1.0 + pulse * 0.08 * (1 + brightness_level)
	_ring.scale = Vector3(s, 1.0, s)


func _on_body_entered(body: Node3D) -> void:
	if _active:
		reached.emit(body)
