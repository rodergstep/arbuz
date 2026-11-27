extends Node
## The player's save: one versioned JSON file per profile in user://saves (ADR-0003, contract:
## docs/contracts/save-format.md). Written to a temp file and renamed, so a crash never leaves a
## half-written save. v1: first encounters. v2: + per-word learning stats and parent settings.

signal saved

const VERSION: int = 2
const DEFAULT_DIR: String = "user://saves"
const DEFAULT_PROFILE: String = "default"
## The game's user folder before the companion was renamed to Tygrytsa (2026-11-26). Saves found
## there are moved into the current folder once, so no progress is lost.
const LEGACY_USER_DIR_NAME: String = "Тигриця's Journey"

var save_dir: String = DEFAULT_DIR
var profile_id: String = DEFAULT_PROFILE

## Per-word learning stats, owned by LearningTracker: word id -> {heard, right, wrong, box, last_seen}.
var words: Dictionary[String, Dictionary] = {}
## Parent settings (v2): session_minutes, volume (0..1).
var settings: Dictionary = {}

var _encountered: Dictionary[String, bool] = {}


func _ready() -> void:
	load_profile()


func path() -> String:
	return "%s/%s.json" % [save_dir, profile_id]


## Loads the profile; a missing, unreadable or corrupt file starts fresh with a warning.
func load_profile() -> void:
	_encountered.clear()
	words.clear()
	settings = default_settings()
	_adopt_legacy_save()
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
	var stored_settings: Variant = data.get("settings", {})
	if stored_settings is Dictionary:
		settings.merge(stored_settings, true)
	var stats: Variant = data.get("words", {})
	if stats is Dictionary:
		for id: Variant in stats:
			if stats[id] is Dictionary:
				words[str(id)] = stats[id]


## Starts over from the very beginning (the parent's "start over"): the current save is kept as
## a dated backup next to it (saves are sacred), then progress, first meetings and word numbers
## are cleared. Parent settings (session length, volume, microphone) are kept.
func start_over() -> void:
	if FileAccess.file_exists(path()):
		var stamp: String = Time.get_datetime_string_from_system().replace(":", "-")
		DirAccess.copy_absolute(path(), "%s/%s.backup-%s.json" % [save_dir, profile_id, stamp])
	var keep: Dictionary = {}
	for key: String in ["session_minutes", "volume", "microphone"]:
		if settings.has(key):
			keep[key] = settings[key]
	_encountered.clear()
	words.clear()
	settings = default_settings()
	settings.merge(keep, true)
	save_now()


## Brings an older save up to VERSION, one step at a time. Never edit a shipped step.
func migrate(data: Dictionary) -> Dictionary:
	var version: int = int(data.get("version", 1))
	if version > VERSION:
		push_warning("SaveSystem: save version %d is newer than this game (%d)" % [version, VERSION])
	if version == 1:
		data = _v1_to_v2(data)
		version = 2
	# Next format change: `if version == 2: data = _v2_to_v3(data)`.
	return data


## v2 adds per-word learning stats; nothing he learned in v1 is lost.
func _v1_to_v2(data: Dictionary) -> Dictionary:
	var out: Dictionary = data.duplicate(true)
	out["words"] = {}
	out["settings"] = default_settings()
	out["version"] = 2
	return out


func save_now() -> bool:
	var err: Error = DirAccess.make_dir_recursive_absolute(save_dir)
	if err != OK:
		push_warning("SaveSystem: cannot create %s (error %d)" % [save_dir, err])
		return false
	var data: Dictionary = {
		"version": VERSION,
		"profile_id": profile_id,
		"encountered": _encountered.keys(),
		"words": words,
		"settings": settings,
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


## Copies a save from the pre-rename user folder when this folder has none yet.
func _adopt_legacy_save() -> void:
	if save_dir != DEFAULT_DIR or FileAccess.file_exists(path()):
		return
	var legacy_dir: String = OS.get_user_data_dir().get_base_dir().path_join(LEGACY_USER_DIR_NAME)
	var legacy: String = legacy_dir.path_join("saves/%s.json" % profile_id)
	if not FileAccess.file_exists(legacy):
		return
	DirAccess.make_dir_recursive_absolute(save_dir)
	var err: Error = DirAccess.copy_absolute(legacy, path())
	EventLog.log_event(&"save_migrated_folder", {"from": legacy, "ok": err == OK})


static func default_settings() -> Dictionary:
	return {"session_minutes": 15, "volume": 0.85, "microphone": true}


func has_encountered(key: String) -> bool:
	return _encountered.has(key)


## Remembers that he has met this line or thing; saved at once.
func mark_encountered(key: String) -> void:
	if _encountered.has(key):
		return
	_encountered[key] = true
	save_now()
