class_name TreasureHunt
extends Node
## The town's hidden treasures: places the ones he hasn't found yet (found ones stay found,
## across sessions) and handles finding one: the word, its learning card, and a cheer when the
## last one is found.

var town: GreyboxVillage
var _treasures: Array[Array] = []


func setup(the_town: GreyboxVillage, treasures: Array[Array]) -> void:
	town = the_town
	_treasures = treasures
	for t: Array in treasures:
		if SaveSystem.has_encountered("treasure:%s" % t[0]):
			continue
		var treasure: Treasure = Treasure.new()
		treasure.setup(t[0])
		town.add_child(treasure)
		treasure.global_position = t[1]


func on_click(treasure: Treasure) -> void:
	if treasure.is_found():
		return
	var word: WordEntry = WordDB.get_word(treasure.word_id)
	var pos: Vector3 = treasure.global_position
	treasure.find()
	EventLog.log_event(&"treasure", {"word": String(treasure.word_id)})
	Speech.line("treasure:found", word, true)
	LearningTracker.record_heard(treasure.word_id)
	town.learning.request(treasure.word_id, pos, pos + Vector3(2.0, 1.8, 2.6))
	var left: int = (
		_treasures
		. filter(func(t: Array) -> bool: return not SaveSystem.has_encountered("treasure:%s" % t[0]))
		. size()
	)
	if left == 0:
		town.say_when_free("treasure:all")
