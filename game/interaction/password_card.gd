class_name PasswordCard
extends Area3D
## One blank card of a password door. Says its English word when pointed at or clicked.
## The focus ring (thick orange frame) shows which card the keyboard or gamepad points at.

const SIZE: Vector3 = Vector3(1.9, 2.3, 0.12)
const SAY_COOLDOWN: float = 0.8

var word_en: String = ""
var is_answer: bool = false
var door: PasswordDoor

var _face: MeshInstance3D
var _ring: MeshInstance3D
var _face_mat: StandardMaterial3D
var _say_timer: float = 0.0


func _ready() -> void:
	collision_layer = Blocks.LAYER_PICKABLE
	collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = SIZE + Vector3(0.3, 0.3, 0.3)
	shape.shape = box
	add_child(shape)
	_ring = Blocks.flat_box_mesh(SIZE + Vector3(0.36, 0.36, -0.04), Color(0.95, 0.55, 0.2))
	_ring.position.z = -0.03
	add_child(_ring)
	_face = Blocks.flat_box_mesh(SIZE, Color(0.98, 0.9, 0.75))
	_face_mat = _face.mesh.material
	add_child(_face)
	var mark: Label3D = Label3D.new()
	mark.text = "?"
	mark.font_size = 220
	mark.modulate = Color(0.45, 0.4, 0.35)
	mark.position.z = SIZE.z / 2.0 + 0.01
	add_child(mark)


func _process(delta: float) -> void:
	_say_timer = maxf(0.0, _say_timer - delta)


func say() -> void:
	if _say_timer > 0.0:
		return
	_say_timer = SAY_COOLDOWN
	Sfx.play(&"tap")
	Speech.say(word_en, Speech.LANG_EN, true)


func set_focused(focused: bool) -> void:
	_ring.visible = focused
	scale = Vector3.ONE * (1.08 if focused else 1.0)


func wiggle() -> void:
	var tween: Tween = create_tween()
	for angle: float in [0.15, -0.15, 0.1, 0.0]:
		tween.tween_property(self, "rotation:z", angle, 0.07)


func glow() -> void:
	_face_mat.emission_enabled = true
	_face_mat.emission = Color(1.0, 0.85, 0.3)
	_face_mat.emission_energy_multiplier = 2.5
	_face_mat.albedo_color = Color(1.0, 0.85, 0.35)
	scale = Vector3.ONE * 1.2
	celebrate()


func celebrate() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "position:y", position.y + 0.4, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(
		Tween.EASE_OUT
	)
