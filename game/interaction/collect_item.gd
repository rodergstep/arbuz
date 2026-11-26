class_name CollectItem
extends Area3D
## A thing to find and collect in a chapter (an apple, an egg, the milk, the flour): a gentle
## glow and a hop like a find target; clicking it collects it (it hops into the air and fades).

signal collected(item: CollectItem)

var word_id: StringName
var _art: Node3D
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


func is_collected() -> bool:
	return _collected


func collect() -> void:
	if _collected:
		return
	_collected = true
	Sfx.play(&"pop")
	collected.emit(self)
	var tween: Tween = create_tween()
	tween.tween_property(_art, "position:y", 2.2, 0.5).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_art, "scale", Vector3.ONE * 0.2, 0.5)
	tween.tween_callback(queue_free)


func _process(delta: float) -> void:
	if _collected:
		return
	_time += delta
	_art.position.y = 0.1 + absf(sin(_time * 2.0)) * 0.15
	_art.rotation.y += delta * 0.8


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
		_:
			var ball: SphereMesh = SphereMesh.new()
			ball.radius = 0.3
			ball.height = 0.6
			root.add_child(Blocks.mesh(ball, Color(0.9, 0.8, 0.4), Vector3(0, 0.3, 0)))
	return root
