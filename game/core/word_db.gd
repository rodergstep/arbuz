extends Node
## The word database: every word the game teaches, loaded once from content/words/words.csv.
## Adding a word is a data change only (ADR-0004). Contract: docs/contracts/word-db.md.

const WORDS_PATH: String = "res://content/words/words.csv"
const REQUIRED_COLUMNS: Array[String] = ["id", "topic", "uk", "en"]
const EXAMPLE_SEPARATOR: String = "|"

var _words: Dictionary[StringName, WordEntry] = {}


func _ready() -> void:
	load_csv(WORDS_PATH)


## Loads (or reloads) a word CSV. Bad rows are skipped with a warning; never crashes the game.
func load_csv(path: String) -> int:
	_words.clear()
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("WordDB: cannot open %s" % path)
		return 0
	var header: PackedStringArray = file.get_csv_line()
	var col: Dictionary[String, int] = {}
	for i: int in header.size():
		col[header[i].strip_edges()] = i
	for required: String in REQUIRED_COLUMNS:
		if not col.has(required):
			push_warning("WordDB: %s has no '%s' column" % [path, required])
			return 0
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() < header.size() or row[col["id"]].strip_edges().is_empty():
			continue
		var entry: WordEntry = WordEntry.new()
		entry.id = StringName(row[col["id"]].strip_edges())
		entry.topic = StringName(row[col["topic"]])
		entry.uk = row[col["uk"]]
		entry.en = row[col["en"]]
		entry.es = _cell(row, col, "es")
		entry.fr = _cell(row, col, "fr")
		entry.model_path = _cell(row, col, "model")
		var examples: String = _cell(row, col, "examples_en")
		if not examples.is_empty():
			entry.examples_en = examples.split(EXAMPLE_SEPARATOR, false)
		_words[entry.id] = entry
	return _words.size()


func has_word(id: StringName) -> bool:
	return _words.has(id)


func get_word(id: StringName) -> WordEntry:
	if not _words.has(id):
		push_warning("WordDB: unknown word '%s'" % id)
		return null
	return _words[id]


func count() -> int:
	return _words.size()


func _cell(row: PackedStringArray, col: Dictionary[String, int], name: String) -> String:
	return row[col[name]] if col.has(name) else ""
