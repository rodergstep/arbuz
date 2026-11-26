class_name ParentScreen
extends CanvasLayer
## Parent-only settings behind the ParentGate. Text is allowed here (parents read Ukrainian):
## session length, volume, and "play 15 more minutes" after the goodbye.

signal closed
signal extend_requested

const LENGTHS: Array[int] = [10, 15, 20, 30]

var _length_buttons: Array[Button] = []
var _volume_label: Label


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bg: ColorRect = ColorRect.new()
	bg.color = UiTokens.BG_SKY
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 28)
	center.add_child(box)
	box.add_child(_text("Для батьків", UiTokens.SIZE_SUBTITLE))
	box.add_child(_text("Тривалість гри, хвилин", UiTokens.SIZE_BODY))
	var lengths: HBoxContainer = HBoxContainer.new()
	lengths.add_theme_constant_override("separation", 16)
	box.add_child(lengths)
	for minutes: int in LENGTHS:
		var b: Button = _button(str(minutes))
		b.toggle_mode = true
		b.pressed.connect(_set_length.bind(minutes))
		lengths.add_child(b)
		_length_buttons.append(b)
	box.add_child(_text("Гучність", UiTokens.SIZE_BODY))
	var volume: HBoxContainer = HBoxContainer.new()
	volume.add_theme_constant_override("separation", 16)
	box.add_child(volume)
	var down: Button = _button("−")
	down.pressed.connect(_change_volume.bind(-0.1))
	volume.add_child(down)
	_volume_label = _text("", UiTokens.SIZE_BODY)
	_volume_label.custom_minimum_size.x = 120
	volume.add_child(_volume_label)
	var up: Button = _button("+")
	up.pressed.connect(_change_volume.bind(0.1))
	volume.add_child(up)
	var extend: Button = _button("Грати ще 15 хвилин")
	extend.pressed.connect(func() -> void: extend_requested.emit())
	box.add_child(extend)
	var close_button: Button = _button("Закрити")
	close_button.pressed.connect(close)
	box.add_child(close_button)
	visible = false


func open() -> void:
	_refresh()
	visible = true


func close() -> void:
	visible = false
	closed.emit()


func _set_length(minutes: int) -> void:
	SaveSystem.settings["session_minutes"] = minutes
	SaveSystem.save_now()
	_refresh()


func _change_volume(step: float) -> void:
	var v: float = clampf(float(SaveSystem.settings["volume"]) + step, 0.0, 1.0)
	SaveSystem.settings["volume"] = snappedf(v, 0.05)
	SaveSystem.save_now()
	Speech.apply_volume()
	_refresh()


func _refresh() -> void:
	var current: int = int(SaveSystem.settings["session_minutes"])
	for i: int in LENGTHS.size():
		_length_buttons[i].button_pressed = LENGTHS[i] == current
	_volume_label.text = "%d%%" % roundi(float(SaveSystem.settings["volume"]) * 100.0)


func _text(text: String, size: int) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", UiTokens.INK)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _button(text: String) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(120, 72)
	b.add_theme_font_size_override("font_size", UiTokens.SIZE_BODY)
	return b
