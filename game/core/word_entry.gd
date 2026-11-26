class_name WordEntry
extends RefCounted
## One row of the word database (content/words/words.csv, contract: docs/contracts/word-db.md).

var id: StringName
var topic: StringName
var uk: String = ""
var en: String = ""
var es: String = ""
var fr: String = ""
var model_path: String = ""
## Short English sentences that use the word in different situations.
var examples_en: PackedStringArray = PackedStringArray()
