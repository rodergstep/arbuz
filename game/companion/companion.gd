class_name Companion
extends Node3D
## Tygrytsa, greybox placeholder: an orange capsule that follows the hero, points at the current
## goal and gives hints when there is no progress (hint ladder in docs/design-system.md):
## level 1 after 15 s (voiced hint, marker brighter), level 2 after +10 s (she runs ahead to
## the goal and the marker glows more).

signal hint_given(level: int)

const HINT_DELAY: float = 15.0
const ESCALATE_DELAY: float = 10.0
const PROGRESS_STEP: float = 1.0
const FOLLOW_SPEED: float = 3.0
const FOLLOW_OFFSET: Vector3 = Vector3(1.4, 0.0, 1.0)

var follow: Node3D
var goal: Node3D
var goal_marker: GoalMarker
## The hint's line key in content/voice/lines.csv ("" = no hint).
var hint_line: String = ""
## Fills {word} in the hint line (find tasks).
var hint_word: WordEntry

var _idle: float = 0.0
var _best_distance: float = INF
var _level: int = 0
var _pointer: Node3D
var _body: Node3D
var _model: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _tail: Node3D
var _head: Node3D
var _walk_phase: float = 0.0
var _point_time: float = 0.0


func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	_model = ModelPainter.load_model("tygrytsa")
	_body.add_child(_model)
	_arm_l = _model.find_child("ArmL", true, false) as Node3D
	_arm_r = _model.find_child("ArmR", true, false) as Node3D
	_leg_l = _model.find_child("LegL", true, false) as Node3D
	_leg_r = _model.find_child("LegR", true, false) as Node3D
	_tail = _model.find_child("Tail", true, false) as Node3D
	_head = _model.find_child("Head", true, false) as Node3D
	_pointer = Node3D.new()
	_pointer.position.y = 1.7
	var cone: CylinderMesh = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.18
	cone.height = 0.5
	var arrow: MeshInstance3D = Blocks.mesh(cone, Color(1.0, 0.85, 0.3))
	arrow.rotation.x = -PI / 2.0
	_pointer.add_child(arrow)
	add_child(_pointer)


## Sets the current goal; null clears it (free play: no hints).
func set_goal(new_goal: Node3D, line: String = "", word: WordEntry = null) -> void:
	goal = new_goal
	goal_marker = new_goal as GoalMarker
	hint_line = line
	hint_word = word
	reset_progress()


func reset_progress() -> void:
	_idle = 0.0
	_level = 0
	_best_distance = INF
	if goal_marker != null:
		goal_marker.set_brightness(0)


func _process(delta: float) -> void:
	if follow == null:
		return
	var leader: Vector3 = follow.global_position
	var target: Vector3 = leader + FOLLOW_OFFSET
	if _level >= 2 and goal != null:
		target = goal.global_position + Vector3(1.2, 0.0, 0.0)
	var speed: float = FOLLOW_SPEED * (2.0 if _level >= 2 else 1.0)
	var to: Vector3 = target - global_position
	to.y = 0.0
	var moving: bool = to.length() > 0.3
	if moving:
		global_position += to.limit_length(speed * delta * maxf(1.0, to.length() / 4.0))
		_body.rotation.y = lerp_angle(_body.rotation.y, atan2(-to.x, -to.z), minf(1.0, 8.0 * delta))
	_animate(delta, moving)
	_pointer.visible = goal != null
	if goal == null:
		return
	var aim: Vector3 = goal.global_position - _pointer.global_position
	aim.y = 0.0
	if aim.length() > 0.1:
		_pointer.rotation.y = atan2(-aim.x, -aim.z)
	_track_progress(delta, leader)


func _track_progress(delta: float, leader: Vector3) -> void:
	var distance: float = leader.distance_to(goal.global_position)
	if distance < _best_distance - PROGRESS_STEP:
		_best_distance = distance
		_idle = 0.0
		if _level > 0:
			_level = 0
			if goal_marker != null:
				goal_marker.set_brightness(0)
		return
	_idle += delta
	if _level == 0 and _idle >= HINT_DELAY:
		_give_hint(1)
	elif _level == 1 and _idle >= HINT_DELAY + ESCALATE_DELAY:
		_give_hint(2)


## Simple procedural animation on the model's joints: walk (legs, arms, bob), a happy tail,
## and pointing with the right arm while she gives a hint.
func _animate(delta: float, moving: bool) -> void:
	if _model == null:
		return
	_walk_phase += delta * (9.0 if moving else 2.0)
	var swing: float = sin(_walk_phase) * (0.6 if moving else 0.0)
	if _leg_l != null:
		_leg_l.rotation.x = swing
		_leg_r.rotation.x = -swing
	if _arm_l != null:
		_arm_l.rotation.x = -swing * 0.8
		var point: float = -2.2 if _point_time > 0.0 else swing * 0.8
		_arm_r.rotation.x = lerpf(_arm_r.rotation.x, point, minf(1.0, 10.0 * delta))
	if _tail != null:
		_tail.rotation.z = sin(Time.get_ticks_msec() / 260.0) * 0.35
	if _head != null:
		_head.rotation.z = sin(_walk_phase * 0.5) * (0.06 if moving else 0.03)
	_model.position.y = absf(sin(_walk_phase)) * (0.06 if moving else 0.0)
	_point_time = maxf(0.0, _point_time - delta)


func _give_hint(level: int) -> void:
	_point_time = 3.0
	_level = level
	if goal_marker != null:
		goal_marker.set_brightness(level)
	if not hint_line.is_empty():
		Speech.line(hint_line, hint_word, true)
	EventLog.log_event(&"hint", {"level": level, "idle_s": snappedf(_idle, 0.1)})
	hint_given.emit(level)
	var tween: Tween = create_tween()
	tween.tween_property(_body, "position:y", 0.6, 0.15)
	tween.tween_property(_body, "position:y", 0.0, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
