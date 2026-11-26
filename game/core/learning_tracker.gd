extends Node
## Remembers, per word, how often he heard it and how he did when asked, and decides which words
## come back (box-based repetition, like flashcards): a right answer moves the word up a box,
## a wrong one sends it back to box 1. Low boxes and words not seen for a while come first.
## Data lives in the save (SaveSystem.words, save format v2).

signal stats_changed(word_id: StringName)

const MIN_BOX: int = 1
const MAX_BOX: int = 5


func record_heard(word_id: StringName) -> void:
	var s: Dictionary = _stats(word_id)
	s["heard"] = int(s["heard"]) + 1
	s["last_seen"] = Time.get_unix_time_from_system()
	_commit(word_id, s)


## Records his answer when he was asked this word (a password door, a quiz).
func record_answer(word_id: StringName, correct: bool) -> void:
	var s: Dictionary = _stats(word_id)
	if correct:
		s["right"] = int(s["right"]) + 1
		s["box"] = mini(int(s["box"]) + 1, MAX_BOX)
	else:
		s["wrong"] = int(s["wrong"]) + 1
		s["box"] = MIN_BOX
	s["last_seen"] = Time.get_unix_time_from_system()
	_commit(word_id, s)
	EventLog.log_event(&"word_answer", {"word_id": String(word_id), "correct": correct, "box": s["box"]})


func box_of(word_id: StringName) -> int:
	return int(_stats(word_id)["box"])


func heard_count(word_id: StringName) -> int:
	return int(_stats(word_id)["heard"])


## Orders candidates so the words he most needs come first: lowest box, then least recently seen.
func most_needed(candidates: Array[StringName]) -> Array[StringName]:
	var sorted: Array[StringName] = candidates.duplicate()
	sorted.sort_custom(_needs_more)
	return sorted


func _needs_more(a: StringName, b: StringName) -> bool:
	var sa: Dictionary = _stats(a)
	var sb: Dictionary = _stats(b)
	if int(sa["box"]) != int(sb["box"]):
		return int(sa["box"]) < int(sb["box"])
	return float(sa["last_seen"]) < float(sb["last_seen"])


func _stats(word_id: StringName) -> Dictionary:
	var stored: Dictionary = SaveSystem.words.get(String(word_id), {})
	return {
		"heard": int(stored.get("heard", 0)),
		"right": int(stored.get("right", 0)),
		"wrong": int(stored.get("wrong", 0)),
		"box": int(stored.get("box", MIN_BOX)),
		"last_seen": float(stored.get("last_seen", 0.0)),
	}


func _commit(word_id: StringName, s: Dictionary) -> void:
	SaveSystem.words[String(word_id)] = s
	SaveSystem.save_now()
	stats_changed.emit(word_id)
