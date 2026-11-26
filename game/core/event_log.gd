extends Node
## Playtest event log: one JSON object per line, {"t": msec since start, "wall": ISO time,
## "kind": ..., "data": {...}}, written to user://logs/<session start>.jsonl.
## Reviewed next to the OBS recording. Never stores anything outside the local machine.

signal event_logged(kind: StringName)

const DEFAULT_LOG_DIR: String = "user://logs"

var log_dir: String = DEFAULT_LOG_DIR
var _file: FileAccess
var _path: String = ""


func _exit_tree() -> void:
	close()


## Writes one event. Failures to write are warned, never raised: errors never reach the child.
func log_event(kind: StringName, data: Dictionary = {}) -> void:
	if not _ensure_open():
		return
	var entry: Dictionary = {
		"t": Time.get_ticks_msec(),
		"wall": Time.get_datetime_string_from_system(false, true),
		"kind": String(kind),
		"data": data,
	}
	_file.store_line(JSON.stringify(entry))
	_file.flush()
	event_logged.emit(kind)


## The file the current session writes to; empty until the first event.
func current_path() -> String:
	return _path


func close() -> void:
	if _file != null:
		_file.close()
		_file = null
	_path = ""


func _ensure_open() -> bool:
	if _file != null:
		return true
	var err: Error = DirAccess.make_dir_recursive_absolute(log_dir)
	if err != OK:
		push_warning("EventLog: cannot create %s (error %d)" % [log_dir, err])
		return false
	var stamp: String = Time.get_datetime_string_from_system(false, false).replace(":", "-")
	_path = "%s/%s.jsonl" % [log_dir, stamp]
	_file = FileAccess.open(
		_path, FileAccess.WRITE_READ if FileAccess.file_exists(_path) else FileAccess.WRITE
	)
	if _file == null:
		push_warning("EventLog: cannot open %s (error %d)" % [_path, FileAccess.get_open_error()])
		_path = ""
		return false
	_file.seek_end()
	return true
