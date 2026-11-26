class_name Hero
extends CharacterBody3D
## The hero: a little boy (assets/models/boy.glb) who swings his arms and legs as he walks.
## Click to walk with pathfinding, hold to follow the cursor, arrow keys or the stick to walk
## directly. Reports arrival; never judges anything.

signal arrived

const SPEED: float = 4.0
const TURN_SPEED: float = 10.0
const GRAVITY: float = 20.0

## When false, the move actions don't steer the hero (for example while choosing a card).
var keyboard_enabled: bool = true

var _agent: NavigationAgent3D
var _body: Node3D
var _has_target: bool = false
var _model: Node3D
var _limbs: Dictionary[String, Node3D] = {}
var _walk_phase: float = 0.0


func _ready() -> void:
	collision_layer = Blocks.LAYER_HERO
	collision_mask = Blocks.LAYER_WORLD | Blocks.LAYER_CAR
	var shape: CollisionShape3D = CollisionShape3D.new()
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.4
	shape.shape = capsule
	shape.position.y = 0.7
	add_child(shape)
	_body = Node3D.new()
	add_child(_body)
	_model = ModelPainter.load_model("boy")
	_model.scale = Vector3.ONE * 1.35
	_body.add_child(_model)
	# He starts facing the camera (south), so his face is seen.
	_body.rotation.y = PI
	for joint: String in ["LegL", "LegR", "ArmL", "ArmR", "Head"]:
		_limbs[joint] = _model.find_child(joint, true, false) as Node3D
	_agent = NavigationAgent3D.new()
	_agent.radius = 0.4
	_agent.path_desired_distance = 0.5
	_agent.target_desired_distance = 0.7
	_agent.path_height_offset = 0.5
	add_child(_agent)


func go_to(point: Vector3) -> void:
	_agent.target_position = point
	_has_target = true


func stop() -> void:
	_has_target = false
	velocity = Vector3.ZERO


func is_walking() -> bool:
	return _has_target


func _physics_process(delta: float) -> void:
	var input: Vector2 = Vector2.ZERO
	if keyboard_enabled:
		input = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var dir: Vector3 = Vector3.ZERO
	if input.length() > 0.1:
		_has_target = false
		dir = Vector3(input.x, 0.0, input.y)
	elif _has_target:
		if _agent.is_navigation_finished():
			_has_target = false
			arrived.emit()
		else:
			var next: Vector3 = _agent.get_next_path_position()
			dir = next - global_position
			dir.y = 0.0
			dir = dir.normalized()
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
	move_and_slide()
	_animate(delta, dir.length() > 0.1)
	if dir.length() > 0.1:
		var target_yaw: float = atan2(-dir.x, -dir.z)
		_body.rotation.y = lerp_angle(_body.rotation.y, target_yaw, minf(1.0, TURN_SPEED * delta))


## Arms and legs swing while he walks; a small bob; standing still, a gentle sway.
func _animate(delta: float, moving: bool) -> void:
	_walk_phase += delta * (10.0 if moving else 2.0)
	var swing: float = sin(_walk_phase) * (0.7 if moving else 0.0)
	if _limbs["LegL"] != null:
		_limbs["LegL"].rotation.x = swing
		_limbs["LegR"].rotation.x = -swing
	if _limbs["ArmL"] != null:
		_limbs["ArmL"].rotation.x = -swing * 0.8
		_limbs["ArmR"].rotation.x = swing * 0.8
	if _limbs["Head"] != null:
		_limbs["Head"].rotation.z = sin(_walk_phase * 0.5) * (0.05 if moving else 0.03)
	_model.position.y = absf(sin(_walk_phase)) * (0.06 if moving else 0.0)
