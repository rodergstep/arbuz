class_name Car
extends CharacterBody3D
## Forgiving arcade car (a box). Arrow keys point the way to drive (world-relative, so a toddler
## never has to think about steering); a click on the ground drives there. Bumping bounces softly
## with a funny sound; nothing breaks.

signal bumped

const MAX_SPEED: float = 8.0
const ACCEL: float = 7.0
const BRAKE: float = 10.0
const TURN_RATE: float = 2.6
const ARRIVE_RADIUS: float = 1.8
const BUMP_COOLDOWN: float = 0.5

var driving: bool = false

var _speed: float = 0.0
var _target: Vector3 = Vector3.ZERO
var _has_target: bool = false
var _bump_timer: float = 0.0
var _body: Node3D


func _ready() -> void:
	collision_layer = Blocks.LAYER_CAR
	collision_mask = Blocks.LAYER_WORLD
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(1.8, 1.2, 3.0)
	shape.shape = box
	shape.position.y = 0.7
	add_child(shape)
	_body = Node3D.new()
	add_child(_body)
	_body.add_child(Blocks.box_mesh(Vector3(1.8, 0.8, 3.0), Color(0.95, 0.45, 0.35), Vector3(0, 0.6, 0)))
	_body.add_child(Blocks.box_mesh(Vector3(1.5, 0.6, 1.6), Color(0.8, 0.9, 1.0), Vector3(0, 1.3, 0.2)))
	for x: float in [-0.95, 0.95]:
		for z: float in [-1.0, 1.0]:
			var wheel: CylinderMesh = CylinderMesh.new()
			wheel.top_radius = 0.35
			wheel.bottom_radius = 0.35
			wheel.height = 0.3
			var w: MeshInstance3D = Blocks.mesh(wheel, Color(0.2, 0.2, 0.22), Vector3(x, 0.35, z))
			w.rotation.z = PI / 2.0
			_body.add_child(w)
	# Pick area so a click on the car is recognised.
	var area: Area3D = Area3D.new()
	area.collision_layer = Blocks.LAYER_PICKABLE
	area.collision_mask = 0
	var pick: CollisionShape3D = CollisionShape3D.new()
	var pick_box: BoxShape3D = BoxShape3D.new()
	pick_box.size = Vector3(2.6, 2.2, 3.8)
	pick.shape = pick_box
	pick.position.y = 1.0
	area.add_child(pick)
	area.set_meta(&"car", self)
	add_child(area)


func drive_to(point: Vector3) -> void:
	_target = point
	_has_target = true


func stop() -> void:
	_has_target = false


func honk() -> void:
	Sfx.play(&"horn")
	EventLog.log_event(&"horn")
	var tween: Tween = create_tween()
	tween.tween_property(_body, "scale", Vector3(1.08, 0.92, 1.08), 0.08)
	tween.tween_property(_body, "scale", Vector3.ONE, 0.15)


func _physics_process(delta: float) -> void:
	_bump_timer = maxf(0.0, _bump_timer - delta)
	var want: Vector3 = Vector3.ZERO
	if driving:
		var input: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
		if input.length() > 0.1:
			_has_target = false
			want = Vector3(input.x, 0.0, input.y).normalized()
		elif _has_target:
			var to_target: Vector3 = _target - global_position
			to_target.y = 0.0
			if to_target.length() < ARRIVE_RADIUS:
				_has_target = false
			else:
				want = to_target.normalized()
	if want != Vector3.ZERO:
		var target_yaw: float = atan2(-want.x, -want.z)
		rotation.y = rotate_toward(rotation.y, target_yaw, TURN_RATE * delta)
		var facing: Vector3 = -transform.basis.z
		var alignment: float = clampf(facing.dot(want), 0.2, 1.0)
		_speed = move_toward(_speed, MAX_SPEED * alignment, ACCEL * delta)
	else:
		_speed = move_toward(_speed, 0.0, BRAKE * delta)
	var forward: Vector3 = -transform.basis.z
	velocity = forward * _speed
	velocity.y = -1.0
	move_and_slide()
	if get_slide_collision_count() > 0 and absf(_speed) > 2.0 and _bump_timer <= 0.0:
		_bounce()


func _bounce() -> void:
	_bump_timer = BUMP_COOLDOWN
	_speed = -_speed * 0.35
	_has_target = false
	Sfx.play(&"boing")
	EventLog.log_event(&"bump")
	bumped.emit()
	var tween: Tween = create_tween()
	tween.tween_property(_body, "position:y", 0.5, 0.12).set_ease(Tween.EASE_OUT)
	tween.tween_property(_body, "position:y", 0.0, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(
		Tween.EASE_OUT
	)
