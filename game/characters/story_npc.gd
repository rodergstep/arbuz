class_name StoryNpc
extends Node3D
## A town character from assets/models (the baker, the toy maker…): stands, faces the hero,
## waves with both arms when greeting or cheering. What they say lives in the town's talk
## scripts; is_talking() is set by those scripts while a conversation runs.

var talking: bool = false

var _model: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _waving: float = 0.0
var _walking: bool = false
var _time: float = 0.0


func setup(model_name: String) -> void:
	_model = ModelPainter.load_model(model_name)
	add_child(_model)
	_arm_l = _model.find_child("ArmL", true, false) as Node3D
	_arm_r = _model.find_child("ArmR", true, false) as Node3D


func is_talking() -> bool:
	return talking


func wave(seconds: float = 2.0) -> void:
	_waving = seconds


func face(pos: Vector3) -> void:
	var to: Vector3 = pos - global_position
	to.y = 0.0
	if to.length() > 0.1:
		rotation.y = atan2(-to.x, -to.z)


## Walks (glides with a little bob) to a spot, then turns to look at look_at.
func walk_to(pos: Vector3, seconds: float, look_at: Vector3) -> void:
	face(pos)
	_walking = true
	var tween: Tween = create_tween()
	tween.tween_property(self, "global_position", pos, seconds)
	tween.tween_callback(
		func() -> void:
			_walking = false
			_model.position.y = 0.0
			face(look_at)
	)


func _process(delta: float) -> void:
	_time += delta
	if _walking and _model != null:
		_model.position.y = absf(sin(_time * 9.0)) * 0.12
	if _arm_r == null:
		return
	if _waving > 0.0:
		_waving -= delta
		var w: float = sin(Time.get_ticks_msec() / 120.0) * 0.4
		_arm_r.rotation = Vector3(-2.6, 0.0, w)
		_arm_l.rotation = Vector3(-2.6, 0.0, -w)
	else:
		_arm_r.rotation = _arm_r.rotation.lerp(Vector3.ZERO, minf(1.0, 6.0 * delta))
		_arm_l.rotation = _arm_l.rotation.lerp(Vector3.ZERO, minf(1.0, 6.0 * delta))
