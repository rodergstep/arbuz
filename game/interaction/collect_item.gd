class_name CollectItem
extends Area3D
## A thing to find and collect in a chapter (an apple, an egg, the milk, the flour): a gentle
## glow and a hop like a find target; clicking it collects it (it hops into the air and fades).

signal collected(item: CollectItem)

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
	_art = Props.make(id)
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
		# Animals with a walk animation really walk home, then stand and graze.
		if ModelPainter.play(_art, "Walk"):
			walk.tween_callback(func() -> void: ModelPainter.play(_art, "Idle"))
		return
	var tween: Tween = create_tween()
	tween.tween_property(_art, "position:y", 2.2, 0.5).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_art, "scale", Vector3.ONE * 0.2, 0.5)
	tween.tween_callback(queue_free)


func _process(delta: float) -> void:
	_time += delta
	if _collected:
		if home != Vector3.INF and _art.find_children("*", "AnimationPlayer", true, false).is_empty():
			_art.position.y = absf(sin(_time * 8.0)) * 0.12
		return
	_art.position.y = 0.1 + absf(sin(_time * 2.0)) * 0.15
	_art.rotation.y += delta * 0.8
