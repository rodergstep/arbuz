extends GutTest
## Saves are sacred: the one place this project keeps a test. Every save version must load.

const SaveSystemScript: GDScript = preload("res://game/core/save_system.gd")
const TEST_DIR: String = "user://test_saves"

var _save: Node


func before_each() -> void:
	_clear()
	_save = SaveSystemScript.new()
	_save.save_dir = TEST_DIR
	add_child_autofree(_save)


func after_all() -> void:
	_clear()


func test_v1_fixture_loads_every_encounter() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	DirAccess.copy_absolute("res://tests/fixtures/saves/v1.json", _save.path())
	_save.load_profile()
	assert_true(_save.has_encountered("line:intro"))
	assert_true(_save.has_encountered("word:bridge"))
	assert_false(_save.has_encountered("word:river"))


func test_encounters_survive_a_restart() -> void:
	_save.mark_encountered("word:car")
	var again: Node = SaveSystemScript.new()
	again.save_dir = TEST_DIR
	add_child_autofree(again)
	again.load_profile()
	assert_true(again.has_encountered("word:car"))


func test_corrupt_file_starts_fresh() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	var f: FileAccess = FileAccess.open(_save.path(), FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	_save.load_profile()
	assert_false(_save.has_encountered("line:intro"))


func _clear() -> void:
	if not DirAccess.dir_exists_absolute(TEST_DIR):
		return
	for file_name: String in DirAccess.get_files_at(TEST_DIR):
		DirAccess.remove_absolute(TEST_DIR + "/" + file_name)
	DirAccess.remove_absolute(TEST_DIR)
