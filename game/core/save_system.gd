extends Node
## The player's save: one versioned JSON file per profile in user://saves (ADR-0003, contract:
## docs/contracts/save-format.md). Written to a temp file and renamed, so a crash never leaves a
## half-written save. Phase 1 stores only first encounters; Phase 2 adds progress and word stats.

signal saved

const VERSION: int = 1
const DEFAULT_DIR: String = "user://saves"
const DEFAULT_PROFILE: String = "default"

var save_dir: String = DEFAULT_DIR
var profile_id: String = DEFAULT_PROFILE

var _encountered: Dictionary[String, bool] = {}


func _ready() -> void:
	load_profile()


func path() -> String:
	return "%s/%s.json" % [save_dir, profile_id]


## Loads the profile; a missing, unreadable or corrupt file starts fresh with a warning.
func load_profile() -> void:
	_encountered.clear()
	if not FileAccess.file_exists(path()):
		return
	var json: JSON = JSON.new()
	var err: Error = json.parse(FileAccess.get_file_as_string(path()))
	var parsed: Variant = json.data if err == OK else null
	if not parsed is Dictionary:
		push_warning("SaveSystem: %s is not valid JSON; starting fresh" % path())
		return
	var data: Dictionary = migrate(parsed)
	var seen: Variant = data.get("encountered", [])
	if seen is Array:
		for key: Variant in seen:
			_encountered[str(key)] = true


## Brings an older save up to VERSION, one step at a time. Never edit a shipped step.
func migrate(data: Dictionary) -> Dictionary:
	var version: int = int(data.get("version", 1))
	if version > VERSION:
		push_warning("SaveSystem: save version %d is newer than this game (%d)" % [version, VERSION])
	# v1 is the first version: no steps yet. Add `if version == 1: data = _v1_to_v2(data)` here.
	return data


func save_now() -> bool:
	var err: Error = DirAccess.make_dir_recursive_absolute(save_dir)
	if err != OK:
		push_warning("SaveSystem: cannot create %s (error %d)" % [save_dir, err])
		return false
	var data: Dictionary = {
		"version": VERSION,
		"profile_id": profile_id,
		"encountered": _encountered.keys(),
	}
	var tmp: String = path() + ".tmp"
	var file: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		push_warning("SaveSystem: cannot write %s" % tmp)
		return false
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	err = DirAccess.rename_absolute(tmp, path())
	if err != OK:
		push_warning("SaveSystem: cannot replace %s (error %d)" % [path(), err])
		return false
	saved.emit()
	return true


func has_encountered(key: String) -> bool:
	return _encountered.has(key)


## Remembers that he has met this line or thing; saved at once.
func mark_encountered(key: String) -> void:
	if _encountered.has(key):
		return
	_encountered[key] = true
	save_now()
