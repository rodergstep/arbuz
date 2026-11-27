class_name Car
extends CharacterBody3D
## Forgiving arcade car (a box). Arrow keys point the way to drive (world-relative, so a toddler
## never has to think about steering); a click on the ground drives there. Bumping bounces softly
## with a funny sound; nothing breaks.

signal bumped
## Driving events for the car's words (go, stop, left, right, horn).
signal started
signal stopped
signal turned(left: bool)
signal honked

const MAX_SPEED: float = 7.0
const ACCEL: float = 8.5
const BRAKE: float = 10.0
const TURN_RATE: float = 2.6
const ARRIVE_RADIUS: float = 1.8
const BUMP_COOLDOWN: float = 0.6
const GRAVITY: float = 20.0
## A collision counts as a bump only against something upright, never the ground.
const WALL_NORMAL_MAX_Y: float = 0.5

var driving: bool = false
## Which toy car: car_hatchback, car_jeep or car_van (assets/models).
var model_name: String = "car_hatchback"

var _speed: float = 0.0
var _target: Vector3 = Vector3.ZERO
var _has_target: bool = false
var _bump_timer: float = 0.0
var _fall_speed: float = 0.0
var _body: Node3D
var _moving: bool = false
## Body paint: [mesh, surface, original colour] for every surface in the body's colour family.
var _paint_parts: Array[Array] = []
var _body_color: Color = Color.WHITE
var _turn_time: float = 0.0
var _last_yaw: float = 0.0


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
	_body.add_child(ModelPainter.load_model(model_name))
	_find_body_paint()
	if SaveSystem.settings.has("car_color"):
		repaint(Color.html(String(SaveSystem.settings["car_color"])))
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


## Repaints the car's body (all shades of its main colour), keeping each shade's lightness.
func repaint(color: Color) -> void:
	for part: Array in _paint_parts:
		var mesh_inst: MeshInstance3D = part[0]
		var original: Color = part[2]
		var shade: float = clampf(original.v / maxf(_body_color.v, 0.01), 0.6, 1.3)
		var c: Color = Color.from_hsv(color.h, color.s, clampf(color.v * shade, 0.0, 1.0))
		mesh_inst.set_surface_override_material(part[1], PaintedMaterials.make(c))


## The body colour is the most-used colourful colour of the model (by triangles).
func _find_body_paint() -> void:
	var weight: Dictionary[String, int] = {}
	var colors: Dictionary[String, Color] = {}
	var parts: Array[Array] = []
	for node: Node in _body.find_children("*", "MeshInstance3D", true, false):
		var mesh_inst: MeshInstance3D = node
		for i: int in mesh_inst.mesh.get_surface_count():
			var mat: Material = mesh_inst.get_active_material(i)
			if not mat is ShaderMaterial:
				continue
			var c: Color = (mat as ShaderMaterial).get_shader_parameter(&"base_color")
			parts.append([mesh_inst, i, c])
			if c.s < 0.3:
				continue
			var key: String = "%d" % int(c.h * 12.0)
			var tris: int = mesh_inst.mesh.surface_get_array_len(i)
			weight[key] = weight.get(key, 0) + tris
			colors[key] = c
	if weight.is_empty():
		return
	var best: String = weight.keys()[0]
	for key: String in weight:
		if weight[key] > weight[best]:
			best = key
	_body_color = colors[best]
	for part: Array in parts:
		var c: Color = part[2]
		if c.s >= 0.3 and absf(angle_difference(c.h * TAU, _body_color.h * TAU)) < TAU / 14.0:
			_paint_parts.append(part)


func drive_to(point: Vector3) -> void:
	_target = point
	_has_target = true


func stop() -> void:
	_has_target = false


func honk() -> void:
	Sfx.play(&"horn")
	EventLog.log_event(&"horn")
	honked.emit()
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
		var alignment: float = clampf(facing.dot(want), 0.45, 1.0)
		_speed = move_toward(_speed, MAX_SPEED * alignment, ACCEL * delta)
	else:
		_speed = move_toward(_speed, 0.0, BRAKE * delta)
	var forward: Vector3 = -transform.basis.z
	_fall_speed = 0.0 if is_on_floor() else _fall_speed + GRAVITY * delta
	velocity = forward * _speed
	velocity.y = -_fall_speed
	move_and_slide()
	if _hit_wall() and absf(_speed) > 2.0 and _bump_timer <= 0.0:
		_bounce()
	_watch_motion(delta)


## Notices starting, stopping and a real turn (half a second of steady turning while moving).
func _watch_motion(delta: float) -> void:
	if not driving:
		_moving = false
		return
	if not _moving and _speed > 2.5:
		_moving = true
		started.emit()
	elif _moving and absf(_speed) < 0.2:
		_moving = false
		stopped.emit()
	var yaw_rate: float = angle_difference(_last_yaw, rotation.y) / maxf(delta, 0.001)
	_last_yaw = rotation.y
	if absf(_speed) > 1.0 and absf(yaw_rate) > 1.0:
		_turn_time += delta * signf(yaw_rate)
		if absf(_turn_time) > 0.5:
			# Counter-clockwise seen from above (positive yaw) is a left turn.
			turned.emit(_turn_time > 0.0)
			_turn_time = 0.0
	else:
		_turn_time = move_toward(_turn_time, 0.0, delta)


func _hit_wall() -> bool:
	for i: int in get_slide_collision_count():
		if get_slide_collision(i).get_normal().y < WALL_NORMAL_MAX_Y:
			return true
	return false


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
