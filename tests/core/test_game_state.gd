extends GutTest

const GameStateScript: GDScript = preload("res://game/core/game_state.gd")

var _state: Node


func before_each() -> void:
	_state = GameStateScript.new()
	add_child_autofree(_state)


func test_get_value_returns_fallback_when_missing() -> void:
	assert_eq(_state.get_value(&"chapter", 0), 0)


func test_set_value_stores_the_value() -> void:
	_state.set_value(&"chapter", 2)
	assert_eq(_state.get_value(&"chapter"), 2)


func test_set_value_emits_state_changed_once_for_the_same_value() -> void:
	watch_signals(_state)
	_state.set_value(&"chapter", 1)
	_state.set_value(&"chapter", 1)
	assert_signal_emit_count(_state, "state_changed", 1)
	assert_signal_emitted_with_parameters(_state, "state_changed", [&"chapter"])


func test_clear_removes_every_value() -> void:
	_state.set_value(&"chapter", 1)
	_state.clear()
	assert_false(_state.has_value(&"chapter"))
