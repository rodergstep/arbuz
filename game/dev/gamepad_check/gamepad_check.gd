extends Control
## Developer scene for Gate 0: shows every gamepad button, trigger and stick, the connected
## device names, the game's input actions, and tests rumble. Press the gamepad's A / bottom
## button (or R to rumble any pad) to feel the motor. Not child-facing.

signal button_seen(button: JoyButton)

const BUTTON_NAMES: Dictionary[JoyButton, String] = {
	JOY_BUTTON_A: "A / bottom",
	JOY_BUTTON_B: "B / right",
	JOY_BUTTON_X: "X / left",
	JOY_BUTTON_Y: "Y / top",
	JOY_BUTTON_BACK: "Back / Select",
	JOY_BUTTON_GUIDE: "Guide / Home",
	JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_STICK: "L3",
	JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "LB",
	JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "D-pad up",
	JOY_BUTTON_DPAD_DOWN: "D-pad down",
	JOY_BUTTON_DPAD_LEFT: "D-pad left",
	JOY_BUTTON_DPAD_RIGHT: "D-pad right",
	JOY_BUTTON_MISC1: "Misc / Share",
	JOY_BUTTON_PADDLE1: "Paddle 1",
	JOY_BUTTON_PADDLE2: "Paddle 2",
	JOY_BUTTON_PADDLE3: "Paddle 3",
	JOY_BUTTON_PADDLE4: "Paddle 4",
	JOY_BUTTON_TOUCHPAD: "Touchpad",
}
const AXIS_NAMES: Dictionary[JoyAxis, String] = {
	JOY_AXIS_LEFT_X: "Left stick X",
	JOY_AXIS_LEFT_Y: "Left stick Y",
	JOY_AXIS_RIGHT_X: "Right stick X",
	JOY_AXIS_RIGHT_Y: "Right stick Y",
	JOY_AXIS_TRIGGER_LEFT: "LT",
	JOY_AXIS_TRIGGER_RIGHT: "RT",
}
const ACTIONS: Array[StringName] = [
	&"move_left", &"move_right", &"move_up", &"move_down", &"use", &"horn", &"pause"
]
const SEEN_COLOR: Color = Color(0.55, 0.85, 0.55)
const PRESSED_COLOR: Color = Color(1.0, 0.85, 0.3)
const IDLE_COLOR: Color = Color(0.7, 0.7, 0.7)

var _devices_label: Label
var _button_labels: Dictionary[JoyButton, Label] = {}
var _axis_bars: Dictionary[JoyAxis, ProgressBar] = {}
var _action_labels: Dictionary[StringName, Label] = {}
var _seen: Dictionary[JoyButton, bool] = {}


func _ready() -> void:
	_build_ui()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_refresh_devices()
	EventLog.log_event(&"gamepad_check_opened", {"pads": Input.get_connected_joypads().size()})


func _process(_delta: float) -> void:
	var pads: Array[int] = Input.get_connected_joypads()
	for button: JoyButton in _button_labels:
		var down: bool = pads.any(func(id: int) -> bool: return Input.is_joy_button_pressed(id, button))
		if down and not _seen.has(button):
			_seen[button] = true
			button_seen.emit(button)
		_button_labels[button].modulate = (
			PRESSED_COLOR if down else (SEEN_COLOR if _seen.has(button) else IDLE_COLOR)
		)
	for axis: JoyAxis in _axis_bars:
		var value: float = 0.0
		for id: int in pads:
			var v: float = Input.get_joy_axis(id, axis)
			if absf(v) > absf(value):
				value = v
		_axis_bars[axis].value = value
	for action: StringName in _action_labels:
		_action_labels[action].modulate = PRESSED_COLOR if Input.is_action_pressed(action) else IDLE_COLOR


func _unhandled_input(event: InputEvent) -> void:
	var rumble_pad: bool = (
		event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A
	)
	var rumble_key: bool = event is InputEventKey and event.pressed and event.physical_keycode == KEY_R
	if rumble_pad or rumble_key:
		for id: int in Input.get_connected_joypads():
			Input.start_joy_vibration(id, 0.6, 0.9, 0.4)
		EventLog.log_event(&"rumble_test")


func seen_count() -> int:
	return _seen.size()


func _on_joy_connection_changed(device: int, connected: bool) -> void:
	EventLog.log_event(
		&"joy_connection", {"device": device, "connected": connected, "name": Input.get_joy_name(device)}
	)
	_refresh_devices()


func _refresh_devices() -> void:
	var lines: PackedStringArray = []
	for id: int in Input.get_connected_joypads():
		lines.append("#%d  %s  (%s)" % [id, Input.get_joy_name(id), Input.get_joy_guid(id)])
	_devices_label.text = (
		"Connected pads:\n"
		+ (
			"\n".join(lines)
			if not lines.is_empty()
			else "none — plug in USB, the 2.4G dongle, or pair over Bluetooth"
		)
	)


func _build_ui() -> void:
	var root: MarginContainer = MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		root.add_theme_constant_override("margin_" + side, 24)
	add_child(root)
	var columns: HBoxContainer = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 48)
	root.add_child(columns)

	var left: VBoxContainer = _column(columns, "Gamepad check  ·  press every button; A or R tests rumble")
	_devices_label = Label.new()
	left.add_child(_devices_label)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	left.add_child(grid)
	for button: JoyButton in BUTTON_NAMES:
		var label: Label = Label.new()
		label.text = BUTTON_NAMES[button]
		label.custom_minimum_size = Vector2(150, 28)
		label.modulate = IDLE_COLOR
		grid.add_child(label)
		_button_labels[button] = label

	var right: VBoxContainer = _column(columns, "Sticks and triggers")
	for axis: JoyAxis in AXIS_NAMES:
		var name_label: Label = Label.new()
		name_label.text = AXIS_NAMES[axis]
		right.add_child(name_label)
		var bar: ProgressBar = ProgressBar.new()
		bar.min_value = -1.0
		bar.max_value = 1.0
		bar.step = 0.01
		bar.custom_minimum_size = Vector2(320, 18)
		right.add_child(bar)
		_axis_bars[axis] = bar
	var actions_title: Label = Label.new()
	actions_title.text = "\nGame actions (keys or pad)"
	right.add_child(actions_title)
	for action: StringName in ACTIONS:
		var label: Label = Label.new()
		label.text = String(action)
		label.modulate = IDLE_COLOR
		right.add_child(label)
		_action_labels[action] = label


func _column(parent: Container, title: String) -> VBoxContainer:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	parent.add_child(box)
	var heading: Label = Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 22)
	box.add_child(heading)
	return box
