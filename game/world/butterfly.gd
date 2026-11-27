class_name Butterfly
extends Clickable
## A butterfly fluttering in soft loops over the flowers near `home` (roadmap step 26). It can
## be clicked like any thing (its word: butterfly).

var home: Vector3
var _time: float = 0.0
var _wing_l: Node3D
var _wing_r: Node3D
var _phase: float = 0.0


func start(at: Vector3, colour: Color) -> void:
	home = at
	_phase = randf() * TAU
	var art: Node3D = Node3D.new()
	_wing_l = _wing(colour, -1.0)
	_wing_r = _wing(colour, 1.0)
	art.add_child(_wing_l)
	art.add_child(_wing_r)
	var body: CapsuleMesh = CapsuleMesh.new()
	body.radius = 0.03
	body.height = 0.22
	var b: MeshInstance3D = Blocks.mesh(body, Color(0.2, 0.18, 0.18))
	b.rotation.x = PI / 2.0
	art.add_child(b)
	var entry: WordEntry = WordDB.get_word(&"butterfly")
	setup(&"butterfly", entry.uk if entry != null else "", "butterfly", art, Vector3(1.2, 1.2, 1.2))


func _wing(colour: Color, side: float) -> Node3D:
	var pivot: Node3D = Node3D.new()
	for k: int in 2:
		var w: SphereMesh = SphereMesh.new()
		w.radius = 0.14 if k == 0 else 0.1
		w.height = 0.03
		var m: MeshInstance3D = Blocks.mesh(w, colour if k == 0 else colour.lightened(0.3))
		m.position = Vector3(side * 0.14, 0, -0.05 if k == 0 else 0.1)
		pivot.add_child(m)
	var dot: SphereMesh = SphereMesh.new()
	dot.radius = 0.04
	dot.height = 0.032
	pivot.add_child(Blocks.mesh(dot, Color(0.15, 0.12, 0.12), Vector3(side * 0.16, 0.01, -0.05)))
	return pivot


func _process(delta: float) -> void:
	super._process(delta)
	_time += delta
	var t: float = _time * 0.6 + _phase
	var target: Vector3 = home + Vector3(sin(t) * 2.2, 1.1 + sin(t * 2.3) * 0.35, sin(t * 1.4) * 1.6)
	var to: Vector3 = target - global_position
	global_position = target
	if to.length() > 0.001:
		rotation.y = atan2(-to.x, -to.z)
	var flap: float = sin(_time * 18.0) * 0.9
	_wing_l.rotation.z = flap
	_wing_r.rotation.z = -flap
