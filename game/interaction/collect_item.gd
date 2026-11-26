class_name CollectItem
extends Area3D
## A thing to find and collect in a chapter (an apple, an egg, the milk, the flour): a gentle
## glow and a hop like a find target; clicking it collects it (it hops into the air and fades).

signal collected(item: CollectItem)

const NUMBERS: Dictionary[StringName, int] = {&"one": 1, &"two": 2, &"three": 3, &"four": 4, &"five": 5}

## A balloon in a colour word's colour, always with its own pattern too, so colour is never
## the only cue: red has dots, blue has stripes, yellow has plus signs, green has upright rings.
const BALLOON_COLORS: Dictionary[StringName, Color] = {
	&"red": Color(0.88, 0.22, 0.24),
	&"blue": Color(0.25, 0.48, 0.88),
	&"yellow": Color(0.98, 0.82, 0.20),
	&"green": Color(0.30, 0.70, 0.36),
}

var word_id: StringName
## Where it goes when collected (an animal trots home to the farm); unset = it flies away.
var home: Vector3 = Vector3.INF
var _art: Node3D
var _ring: MeshInstance3D
var _collected: bool = false
var _time: float = 0.0


func setup(id: StringName) -> void:
	word_id = id
	collision_layer = Blocks.LAYER_PICKABLE
	collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(1.6, 1.6, 1.6)
	shape.shape = box
	shape.position.y = 0.6
	add_child(shape)
	_art = _make_art(id)
	add_child(_art)
	var ring_mesh: CylinderMesh = CylinderMesh.new()
	ring_mesh.top_radius = 0.8
	ring_mesh.bottom_radius = 0.8
	ring_mesh.height = 0.02
	var ring: MeshInstance3D = Blocks.flat_mesh(ring_mesh, Color(1.0, 0.85, 0.4), Vector3(0, 0.03, 0))
	var ring_mat: StandardMaterial3D = ring.mesh.material
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.albedo_color.a = 0.35
	add_child(ring)
	_ring = ring


func is_collected() -> bool:
	return _collected


func collect() -> void:
	if _collected:
		return
	_collected = true
	Sfx.play(&"pop")
	collected.emit(self)
	if home != Vector3.INF:
		# Animals go back home and stay there.
		_ring.visible = false
		collision_layer = 0
		var to: Vector3 = home - global_position
		_art.rotation.y = atan2(-to.x, -to.z)
		var walk: Tween = create_tween()
		walk.tween_property(self, "global_position", home, clampf(to.length() / 4.0, 1.5, 8.0))
		return
	var tween: Tween = create_tween()
	tween.tween_property(_art, "position:y", 2.2, 0.5).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_art, "scale", Vector3.ONE * 0.2, 0.5)
	tween.tween_callback(queue_free)


func _process(delta: float) -> void:
	_time += delta
	if _collected:
		if home != Vector3.INF:
			_art.position.y = absf(sin(_time * 8.0)) * 0.12
		return
	_art.position.y = 0.1 + absf(sin(_time * 2.0)) * 0.15
	_art.rotation.y += delta * 0.8


func _make_balloon(root: Node3D, id: StringName) -> void:
	var c: Vector3 = Vector3(0, 1.9, 0)
	var balloon: SphereMesh = SphereMesh.new()
	balloon.radius = 0.45
	balloon.height = 1.1
	root.add_child(Blocks.mesh(balloon, BALLOON_COLORS[id], c))
	root.add_child(Blocks.box_mesh(Vector3(0.02, 1.4, 0.02), Color(0.95, 0.95, 0.95), Vector3(0, 0.75, 0)))
	var white: Color = Color(0.98, 0.98, 0.96)
	match id:
		&"red":
			for p: Vector3 in [
				Vector3(0.0, 0.2, 0.42),
				Vector3(0.25, -0.1, 0.36),
				Vector3(-0.25, -0.1, 0.36),
				Vector3(0, -0.3, 0.38)
			]:
				var dot: SphereMesh = SphereMesh.new()
				dot.radius = 0.07
				dot.height = 0.14
				root.add_child(Blocks.mesh(dot, white, c + p))
		&"blue":
			for y: float in [-0.18, 0.15]:
				var ring: TorusMesh = TorusMesh.new()
				ring.inner_radius = 0.4
				ring.outer_radius = 0.46
				root.add_child(Blocks.mesh(ring, white, c + Vector3(0, y, 0)))
		&"yellow":
			# A white plus on four sides, so it shows whichever way the balloon turns.
			for yaw: float in [0.0, PI / 2.0, PI, PI * 1.5]:
				var side: Node3D = Node3D.new()
				side.position = c
				side.rotation.y = yaw
				side.add_child(Blocks.box_mesh(Vector3(0.3, 0.09, 0.09), white, Vector3(0, 0, 0.42)))
				side.add_child(Blocks.box_mesh(Vector3(0.09, 0.3, 0.09), white, Vector3(0, 0, 0.42)))
				root.add_child(side)
		&"green":
			# Two upright rings, like the seams of a beach ball.
			for yaw: float in [0.0, PI / 2.0]:
				var ring: TorusMesh = TorusMesh.new()
				ring.inner_radius = 0.43
				ring.outer_radius = 0.48
				var band: MeshInstance3D = Blocks.mesh(ring, white, c)
				band.rotation = Vector3(0, yaw, PI / 2.0)
				band.scale = Vector3(1.2, 1.0, 1.0)
				root.add_child(band)


## A big number tile from the clock: the digit, and the same number of dots under it, so he
## sees how many as well as the symbol.
func _make_number(root: Node3D, id: StringName) -> void:
	var n: int = NUMBERS[id]
	var tile: MeshInstance3D = Blocks.box_mesh(
		Vector3(1.0, 1.2, 0.15), Color(0.98, 0.95, 0.86), Vector3(0, 1.0, 0)
	)
	root.add_child(tile)
	for side: float in [1.0, -1.0]:
		var digit: Label3D = Label3D.new()
		digit.text = str(n)
		digit.font_size = 220
		digit.modulate = Color(0.23, 0.23, 0.22)
		digit.outline_size = 0
		digit.position = Vector3(0, 1.15, 0.08 * side)
		digit.rotation.y = 0.0 if side > 0.0 else PI
		root.add_child(digit)
		for i: int in n:
			var dot: SphereMesh = SphereMesh.new()
			dot.radius = 0.06
			dot.height = 0.12
			var x: float = (i - (n - 1) / 2.0) * 0.17
			root.add_child(Blocks.mesh(dot, Color(0.88, 0.40, 0.25), Vector3(x, 0.58, 0.09 * side)))


func _make_art(id: StringName) -> Node3D:
	var root: Node3D = Node3D.new()
	match id:
		&"apple":
			var apple: SphereMesh = SphereMesh.new()
			apple.radius = 0.32
			apple.height = 0.6
			root.add_child(Blocks.mesh(apple, Color(0.88, 0.22, 0.24), Vector3(0, 0.3, 0)))
			root.add_child(
				Blocks.box_mesh(Vector3(0.04, 0.16, 0.04), Color(0.45, 0.3, 0.2), Vector3(0, 0.66, 0))
			)
			var leaf: SphereMesh = SphereMesh.new()
			leaf.radius = 0.1
			leaf.height = 0.06
			root.add_child(Blocks.mesh(leaf, Color(0.35, 0.65, 0.3), Vector3(0.1, 0.68, 0)))
		&"egg":
			var egg: SphereMesh = SphereMesh.new()
			egg.radius = 0.22
			egg.height = 0.58
			root.add_child(Blocks.mesh(egg, Color(0.98, 0.95, 0.88), Vector3(0, 0.3, 0)))
		&"milk":
			var bottle: CylinderMesh = CylinderMesh.new()
			bottle.top_radius = 0.14
			bottle.bottom_radius = 0.22
			bottle.height = 0.7
			root.add_child(Blocks.mesh(bottle, Color(0.98, 0.98, 0.96), Vector3(0, 0.35, 0)))
			root.add_child(
				Blocks.box_mesh(Vector3(0.2, 0.08, 0.2), Color(0.3, 0.55, 0.85), Vector3(0, 0.74, 0))
			)
		&"flour":
			var sack: SphereMesh = SphereMesh.new()
			sack.radius = 0.36
			sack.height = 0.8
			root.add_child(Blocks.mesh(sack, Color(0.92, 0.88, 0.78), Vector3(0, 0.38, 0)))
			root.add_child(
				Blocks.box_mesh(Vector3(0.18, 0.12, 0.18), Color(0.7, 0.55, 0.35), Vector3(0, 0.8, 0))
			)
		&"red", &"blue", &"yellow", &"green":
			_make_balloon(root, id)
		&"one", &"two", &"three", &"four", &"five":
			_make_number(root, id)
		&"cow", &"sheep", &"pig", &"duck":
			root.add_child(ModelPainter.load_model(String(id)))
		_:
			var ball: SphereMesh = SphereMesh.new()
			ball.radius = 0.3
			ball.height = 0.6
			root.add_child(Blocks.mesh(ball, Color(0.9, 0.8, 0.4), Vector3(0, 0.3, 0)))
	return root
