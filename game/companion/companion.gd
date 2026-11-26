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


func _ready() -> void:
	_body = Node3D.new()
	add_child(_body)
	var capsule: CapsuleMesh = CapsuleMesh.new()
	capsule.radius = 0.35
	capsule.height = 1.1
	_body.add_child(Blocks.mesh(capsule, Color(1.0, 0.6, 0.15), Vector3(0, 0.55, 0)))
	for x: float in [-0.18, 0.18]:
		var ear: SphereMesh = SphereMesh.new()
		ear.radius = 0.1
		ear.height = 0.2
		_body.add_child(Blocks.mesh(ear, Color(1.0, 0.6, 0.15), Vector3(x, 1.15, 0)))
	for y: float in [0.4, 0.65, 0.9]:
		var stripe: TorusMesh = TorusMesh.new()
		stripe.inner_radius = 0.33
		stripe.outer_radius = 0.38
		_body.add_child(Blocks.mesh(stripe, Color(0.15, 0.1, 0.1), Vector3(0, y, 0)))
	var shirt: CylinderMesh = CylinderMesh.new()
	shirt.top_radius = 0.37
	shirt.bottom_radius = 0.37
	shirt.height = 0.12
	_body.add_child(Blocks.mesh(shirt, Color(0.95, 0.95, 0.9), Vector3(0, 0.75, 0)))
	_pointer = Node3D.new()
	_pointer.position.y = 1.6
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
	if to.length() > 0.3:
		global_position += to.limit_length(speed * delta * maxf(1.0, to.length() / 4.0))
		_body.rotation.y = lerp_angle(_body.rotation.y, atan2(-to.x, -to.z), minf(1.0, 8.0 * delta))
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


func _give_hint(level: int) -> void:
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
