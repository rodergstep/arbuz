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
var _footprint: float = 1.0
var _highlight: StandardMaterial3D
var _highlight_time: float = 0.0
var _hop_timer: float = 0.0
var _ring: MeshInstance3D


## Builds the pick area around the given visual; height places the word label.
func setup(id: StringName, uk: String, en: String, art: Node3D, pick_size: Vector3) -> void:
	word_id = id
	word_uk = uk
	word_en = en
	visual = art
	_height = pick_size.y + 0.6
	_footprint = maxf(pick_size.x, pick_size.z) / 2.0
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
	Speech.line("thing:click", WordDB.get_word(word_id), true, "word:%s" % word_id)


## A gentle "this one" sign for find tasks: a soft warm glow that breathes and a small hop now
## and then. Not a giveaway: the glow stays faint (the strong marker comes only after 2 misses).
func set_highlight(on: bool) -> void:
	if on and _highlight == null:
		_highlight = StandardMaterial3D.new()
		_highlight.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_highlight.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_highlight.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_highlight.albedo_color = Color(1.0, 0.85, 0.4, 0.0)
		_highlight_time = 0.0
		_hop_timer = 1.5
		var disc: CylinderMesh = CylinderMesh.new()
		# Wider than the thing itself, so the ring shows even around a house.
		disc.top_radius = _footprint + 0.6
		disc.bottom_radius = _footprint + 0.6
		disc.height = 0.02
		_ring = Blocks.mesh(disc, Color(1.0, 0.85, 0.4), Vector3(0, 0.03, 0))
		var ring_mat: StandardMaterial3D = _ring.mesh.material
		ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		add_child(_ring)
	elif not on:
		_highlight = null
		if _ring != null:
			_ring.queue_free()
			_ring = null
	if visual != null:
		for mesh: Node in visual.find_children("*", "MeshInstance3D", true, false):
			(mesh as MeshInstance3D).material_overlay = _highlight


func _show_label() -> void:
	if _label == null:
		_label = Blocks.label("", _height, 72)
		add_child(_label)
	_label.text = word_en
	_label.visible = true
	_label_timer = LABEL_SECONDS


func _process(delta: float) -> void:
	if _highlight != null:
		_highlight_time += delta
		var breath: float = 0.5 + 0.5 * sin(_highlight_time * 2.4)
		_highlight.albedo_color.a = 0.22 + 0.18 * breath
		if _ring != null:
			(_ring.mesh.material as StandardMaterial3D).albedo_color.a = 0.25 + 0.2 * breath
			_ring.scale = Vector3.ONE * (1.0 + 0.12 * breath)
		_hop_timer -= delta
		if _hop_timer <= 0.0 and visual != null:
			_hop_timer = 4.0
			var hop: Tween = create_tween()
			hop.tween_property(visual, "position:y", 0.25, 0.18).set_ease(Tween.EASE_OUT)
			hop.tween_property(visual, "position:y", 0.0, 0.3).set_trans(Tween.TRANS_BOUNCE)
	if _label_timer > 0.0:
		_label_timer -= delta
		if _label_timer <= 0.0:
			_label.visible = false
