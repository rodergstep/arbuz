extends SceneTree
## Writes the project's input map into project.godot, so it is defined once and reproducibly.
## Run: godot --headless --path . --script res://tools/setup_input_map.gd

const DEADZONE: float = 0.3


func _init() -> void:
	_set_action(
		&"move_left",
		[_key(KEY_LEFT), _key(KEY_A), _axis(JOY_AXIS_LEFT_X, -1.0), _button(JOY_BUTTON_DPAD_LEFT)]
	)
	_set_action(
		&"move_right",
		[_key(KEY_RIGHT), _key(KEY_D), _axis(JOY_AXIS_LEFT_X, 1.0), _button(JOY_BUTTON_DPAD_RIGHT)]
	)
	_set_action(
		&"move_up", [_key(KEY_UP), _key(KEY_W), _axis(JOY_AXIS_LEFT_Y, -1.0), _button(JOY_BUTTON_DPAD_UP)]
	)
	_set_action(
		&"move_down",
		[_key(KEY_DOWN), _key(KEY_S), _axis(JOY_AXIS_LEFT_Y, 1.0), _button(JOY_BUTTON_DPAD_DOWN)]
	)
	_set_action(&"use", [_key(KEY_SPACE), _key(KEY_ENTER), _button(JOY_BUTTON_A)])
	_set_action(&"horn", [_key(KEY_H), _button(JOY_BUTTON_X), _button(JOY_BUTTON_Y)])
	_set_action(&"pause", [_key(KEY_ESCAPE), _key(KEY_P), _button(JOY_BUTTON_START)])
	var err: Error = ProjectSettings.save()
	print("input map saved: %s" % error_string(err))
	quit(0 if err == OK else 1)


func _set_action(action: StringName, events: Array[InputEvent]) -> void:
	ProjectSettings.set_setting("input/" + action, {"deadzone": DEADZONE, "events": events})


func _key(keycode: Key) -> InputEventKey:
	var e: InputEventKey = InputEventKey.new()
	e.physical_keycode = keycode
	return e


func _button(index: JoyButton) -> InputEventJoypadButton:
	var e: InputEventJoypadButton = InputEventJoypadButton.new()
	e.button_index = index
	e.device = -1
	return e


func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e: InputEventJoypadMotion = InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	e.device = -1
	return e
