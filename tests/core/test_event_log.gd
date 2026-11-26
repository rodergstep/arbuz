extends GutTest

const EventLogScript: GDScript = preload("res://game/core/event_log.gd")
const TEST_DIR: String = "user://test_logs"

var _log: Node


func before_each() -> void:
	_remove_dir(TEST_DIR)
	_log = EventLogScript.new()
	_log.log_dir = TEST_DIR
	add_child_autofree(_log)


func after_each() -> void:
	_log.close()
	_remove_dir(TEST_DIR)


func test_log_event_writes_one_json_line_per_call() -> void:
	_log.log_event(&"click", {"word_id": "apple"})
	_log.log_event(&"idle", {"seconds": 15})
	var path: String = _log.current_path()
	_log.close()
	var lines: PackedStringArray = FileAccess.get_file_as_string(path).strip_edges().split("\n")
	assert_eq(lines.size(), 2)
	var first: Dictionary = JSON.parse_string(lines[0])
	assert_eq(first["kind"], "click")
	assert_eq(first["data"]["word_id"], "apple")
	assert_true(first.has("t"))
	assert_true(first.has("wall"))


func test_log_event_emits_event_logged() -> void:
	watch_signals(_log)
	_log.log_event(&"card_pick")
	assert_signal_emitted_with_parameters(_log, "event_logged", [&"card_pick"])


func test_log_file_lives_under_the_log_dir() -> void:
	_log.log_event(&"click")
	assert_string_starts_with(_log.current_path(), TEST_DIR + "/")


func _remove_dir(dir_path: String) -> void:
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	for file_name: String in DirAccess.get_files_at(dir_path):
		DirAccess.remove_absolute(dir_path + "/" + file_name)
	DirAccess.remove_absolute(dir_path)
