class_name PointerInput
extends Node
## Mouse and touch (touch arrives as an emulated mouse). Raycasts what is under the pointer and
## reports it: a click on the ground, a held button following the cursor, a click on a pickable
## thing, and hovering over a password card. It decides nothing; GreyboxVillage does.

signal ground_clicked(point: Vector3)
signal ground_held(point: Vector3)
signal pickable_clicked(area: Area3D)
signal card_hovered(card: PasswordCard)
signal any_input

const HOLD_DELAY: float = 0.25
const HOLD_REPEAT: float = 0.1
const RAY_LENGTH: float = 200.0

var _pressed: bool = false
var _press_time: float = 0.0
var _repeat: float = 0.0
var _hovered: PasswordCard


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		any_input.emit()
		_pressed = event.pressed
		_press_time = 0.0
		if event.pressed:
			_click(event.position)
	elif event is InputEventMouseMotion:
		_hover(event.position)
	elif event is InputEventKey or event is InputEventJoypadButton:
		if event.is_pressed():
			any_input.emit()


func _process(delta: float) -> void:
	if not _pressed:
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_pressed = false
		return
	_press_time += delta
	_repeat -= delta
	if _press_time >= HOLD_DELAY and _repeat <= 0.0:
		_repeat = HOLD_REPEAT
		var hit: Dictionary = _raycast(get_viewport().get_mouse_position(), Blocks.LAYER_WORLD, false)
		if not hit.is_empty():
			ground_held.emit(hit["position"])


func _click(screen_pos: Vector2) -> void:
	var pick: Dictionary = _raycast(screen_pos, Blocks.LAYER_PICKABLE, true)
	if not pick.is_empty() and pick["collider"] is Area3D:
		var area: Area3D = pick["collider"]
		EventLog.log_event(&"click", {"on": String(area.name), "kind": area.get_class()})
		pickable_clicked.emit(area)
		return
	var hit: Dictionary = _raycast(screen_pos, Blocks.LAYER_WORLD, false)
	if not hit.is_empty():
		var p: Vector3 = hit["position"]
		EventLog.log_event(&"click", {"on": "ground", "x": snappedf(p.x, 0.1), "z": snappedf(p.z, 0.1)})
		ground_clicked.emit(p)


func _hover(screen_pos: Vector2) -> void:
	var pick: Dictionary = _raycast(screen_pos, Blocks.LAYER_PICKABLE, true)
	var card: PasswordCard = null
	if not pick.is_empty():
		card = pick["collider"] as PasswordCard
	if card != _hovered:
		_hovered = card
		if card != null:
			card_hovered.emit(card)


func _raycast(screen_pos: Vector2, mask: int, areas: bool) -> Dictionary:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return {}
	var from: Vector3 = camera.project_ray_origin(screen_pos)
	var to: Vector3 = from + camera.project_ray_normal(screen_pos) * RAY_LENGTH
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to, mask)
	query.collide_with_areas = areas
	query.collide_with_bodies = not areas
	return get_viewport().get_world_3d().direct_space_state.intersect_ray(query)
