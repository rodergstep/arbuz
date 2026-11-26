class_name Clickable
extends Area3D
## A thing in the world that reacts when clicked (a pop, a squash, its written word for a
## moment). What it teaches is decided by the scene: normally a learning moment for word_id.

signal clicked(word_id: StringName)

const LABEL_SECONDS: float = 2.5

@export var word_id: StringName
@export var word_uk: String
@export var word_en: String

var visual: Node3D
var _label: Label3D
var _label_timer: float = 0.0
var _height: float = 2.0


## Builds the pick area around the given visual; height places the word label.
func setup(id: StringName, uk: String, en: String, art: Node3D, pick_size: Vector3) -> void:
	word_id = id
	word_uk = uk
	word_en = en
	visual = art
	_height = pick_size.y + 0.6
	add_child(art)
	collision_layer = Blocks.LAYER_PICKABLE
	collision_mask = 0
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = pick_size
	shape.shape = box
	shape.position.y = pick_size.y / 2.0
	add_child(shape)


func activate(show_word: bool = true) -> void:
	Sfx.play(&"pop")
	EventLog.log_event(&"object_clicked", {"word_id": String(word_id)})
	clicked.emit(word_id)
	if show_word:
		_show_label()
	if visual != null:
		var tween: Tween = create_tween()
		tween.tween_property(visual, "scale", Vector3(1.15, 0.85, 1.15), 0.08)
		tween.tween_property(visual, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(
			Tween.EASE_OUT
		)


## Says the word aloud (used when no learning moment can open).
## A good camera spot for picturing this thing, scaled to its size.
func picture_view() -> Vector3:
	var distance: float = clampf(_height * 1.3, 2.5, 9.0)
	return global_position + Vector3(0.55, 0.5, 0.67).normalized() * distance


func say_name() -> void:
	Speech.say_first("word:%s" % word_id, "Це %s!" % word_uk, "This is a %s. %s!" % [word_en, word_en], true)


func _show_label() -> void:
	if _label == null:
		_label = Blocks.label("", _height, 72)
		add_child(_label)
	_label.text = word_en
	_label.visible = true
	_label_timer = LABEL_SECONDS


func _process(delta: float) -> void:
	if _label_timer > 0.0:
		_label_timer -= delta
		if _label_timer <= 0.0:
			_label.visible = false
