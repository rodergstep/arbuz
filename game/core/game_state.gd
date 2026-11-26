extends Node
## In-memory session state. Systems read and write it through set_value/get_value.
## The example autoload of the skeleton; persistence belongs to SaveSystem (Phase 2).

signal state_changed(key: StringName)

var _values: Dictionary[StringName, Variant] = {}


func set_value(key: StringName, value: Variant) -> void:
	if _values.has(key) and _values[key] == value:
		return
	_values[key] = value
	state_changed.emit(key)


func get_value(key: StringName, fallback: Variant = null) -> Variant:
	return _values.get(key, fallback)


func has_value(key: StringName) -> bool:
	return _values.has(key)


func clear() -> void:
	_values.clear()
