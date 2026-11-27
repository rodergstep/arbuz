class_name Treasure
extends Area3D
## A hidden treasure (a teddy behind a hata, a crown behind the barn…): a small thing with a
## twinkling star above it, tucked away for free exploration (roadmap step 28). Clicking it
## teaches its word; once found it is remembered (save key "treasure:<id>") and stays found.

var word_id: StringName
var _art: Node3D
var _twinkle: MeshInstance3D
var _time: float = 0.0
var _found: bool = false


func setup(id: StringName) -> void:
	word_id = id
	collision_layer = Blocks.LAYER_PICKABLE
	collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(1.8, 2.0, 1.8)
	shape.shape = box
	shape.position.y = 0.8
	add_child(shape)
	_art = Props.make(id)
	_art.scale = Vector3.ONE * 0.8
	add_child(_art)
	var star: PrismMesh = PrismMesh.new()
	star.size = Vector3(0.35, 0.35, 0.05)
	_twinkle = Blocks.flat_mesh(star, Color(1.0, 0.9, 0.4), Vector3(0, 2.0, 0))
	var mat: StandardMaterial3D = _twinkle.mesh.material
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_twinkle)


func is_found() -> bool:
	return _found


## Found: a happy hop up and away.
func find() -> void:
	if _found:
		return
	_found = true
	SaveSystem.mark_encountered("treasure:%s" % word_id)
	Sfx.play(&"chime")
	collision_layer = 0
	_twinkle.visible = false
	var tween: Tween = create_tween()
	tween.tween_property(_art, "position:y", 1.2, 0.35).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_art, "rotation:y", TAU, 0.7)
	tween.tween_interval(1.2)
	tween.tween_property(_art, "scale", Vector3.ZERO, 0.4)
	tween.tween_callback(queue_free)


func _process(delta: float) -> void:
	_time += delta
	if _found:
		return
	# A gentle twinkle: the star above pulses and turns.
	var k: float = 0.7 + 0.3 * sin(_time * 4.0)
	_twinkle.scale = Vector3.ONE * k
	_twinkle.rotation.z = _time * 1.5
