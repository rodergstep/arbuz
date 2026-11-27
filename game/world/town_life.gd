class_name TownLife
extends Node3D
## The town lives (roadmap step 26, first part): vehicles drive slowly round the road loop (a
## red bus, a taxi, a tractor) and animals wander about. Everything can be clicked to learn its
## word. Vehicles always stop for him: when the hero or his car is just ahead, they wait.

const STOP_DISTANCE: float = 7.0

var town: GreyboxVillage
var _movers: Array[Dictionary] = []


func setup(the_town: GreyboxVillage) -> void:
	town = the_town


## A vehicle driving round `path` (closed loop of points) at `speed` m/s, starting at point `start`.
func add_vehicle(model: String, word: StringName, path: Array[Vector3], speed: float, start: int = 0) -> void:
	var thing: Clickable = _clickable(model, word, Vector3(2.4, 2.4, 4.0))
	thing.global_position = path[start]
	_movers.append(
		{"node": thing, "path": path, "next": (start + 1) % path.size(), "speed": speed, "wait": 0.0}
	)


## An animal strolling between random spots within `radius` of `center`.
func add_wanderer(model: String, word: StringName, center: Vector3, radius: float) -> void:
	var thing: Clickable = _clickable(model, word, Vector3(1.6, 1.6, 1.6))
	thing.global_position = center
	_movers.append(
		{
			"node": thing,
			"center": center,
			"radius": radius,
			"speed": 1.1,
			"wait": randf_range(1, 4),
			"target": center
		}
	)


## The paint shop (four paint pots) and the hat stand, side by side from these spots.
func add_dress_up(paint_spot: Vector3, hat_spot: Vector3) -> void:
	var dress: DressUp = DressUp.new()
	add_child(dress)
	dress.build(town, paint_spot, hat_spot)


## Butterflies fluttering over the flowers, one at each spot (orange, blue, pink).
func add_butterflies(spots: Array[Vector3]) -> void:
	var colours: Array[Color] = [Color(0.98, 0.55, 0.2), Color(0.35, 0.55, 0.95), Color(0.95, 0.4, 0.6)]
	for i: int in spots.size():
		var b: Butterfly = Butterfly.new()
		b.start(spots[i], colours[i % colours.size()])
		add_child(b)


func _clickable(model: String, word: StringName, pick: Vector3) -> Clickable:
	var entry: WordEntry = WordDB.get_word(word)
	var holder: Node3D = Node3D.new()
	var art: Node3D = ModelPainter.load_model(model)
	art.rotation.y = PI
	holder.add_child(art)
	var thing: Clickable = Clickable.new()
	thing.setup(word, entry.uk if entry != null else "", String(word), holder, pick)
	add_child(thing)
	return thing


func _process(delta: float) -> void:
	for m: Dictionary in _movers:
		if m.has("path"):
			_drive(m, delta)
		else:
			_wander(m, delta)


func _drive(m: Dictionary, delta: float) -> void:
	var node: Node3D = m["node"]
	var path: Array[Vector3] = m["path"]
	var target: Vector3 = path[m["next"]]
	var to: Vector3 = target - node.global_position
	to.y = 0.0
	if to.length() < 0.5:
		m["next"] = (int(m["next"]) + 1) % path.size()
		return
	var dir: Vector3 = to.normalized()
	if _blocked(node.global_position, dir):
		return
	node.global_position += dir * minf(float(m["speed"]) * delta, to.length())
	node.rotation.y = lerp_angle(node.rotation.y, atan2(-dir.x, -dir.z), minf(1.0, 4.0 * delta))


func _wander(m: Dictionary, delta: float) -> void:
	var node: Node3D = m["node"]
	var art: Node3D = (node as Clickable).visual.get_child(0)
	if m["wait"] > 0.0:
		m["wait"] = float(m["wait"]) - delta
		if m["wait"] <= 0.0:
			var a: float = randf() * TAU
			m["target"] = (
				(m["center"] as Vector3) + Vector3(cos(a), 0, sin(a)) * randf_range(1.0, float(m["radius"]))
			)
			ModelPainter.play(art, "Walk")
		return
	var to: Vector3 = (m["target"] as Vector3) - node.global_position
	to.y = 0.0
	if to.length() < 0.3:
		m["wait"] = randf_range(2.0, 6.0)
		ModelPainter.play(art, "Idle")
		return
	var dir: Vector3 = to.normalized()
	node.global_position += dir * float(m["speed"]) * delta
	node.rotation.y = lerp_angle(node.rotation.y, atan2(-dir.x, -dir.z), minf(1.0, 5.0 * delta))


## True when the hero or his car is just ahead: the vehicle waits (they always stop for him).
func _blocked(pos: Vector3, dir: Vector3) -> bool:
	for other: Node3D in [town.hero, town.car]:
		if other == null or not other.visible:
			continue
		var to: Vector3 = other.global_position - pos
		to.y = 0.0
		if to.length() < STOP_DISTANCE and to.normalized().dot(dir) > 0.5:
			return true
	return false
