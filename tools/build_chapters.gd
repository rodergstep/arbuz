extends SceneTree
## Writes the chapter data files under content/chapters/ from the definitions below.
## Run: godot --headless --path . --script res://tools/build_chapters.gd
## (Edit the .tres in the inspector afterwards if you like; this is the starting point.)

const DOOR_POS: Vector3 = Vector3(-14, 0, -28)


func _initialize() -> void:
	var chapter: ChapterData = ChapterData.new()
	chapter.id = &"greybox_loop"
	chapter.loop = true
	chapter.loop_line = "line:again"
	chapter.loop_delay = 6.0
	chapter.steps = [
		_step(QuestStep.Kind.GET_IN_CAR, [], "", "hint:to_car", "line:here_car"),
		# Drive spots sit on the car's side of the river with a clear straight line from the
		# previous spot, so driving straight at the marker never hits water, a house or a tree.
		_step(
			QuestStep.Kind.DRIVE_TO,
			[Vector3(-24, 0, -6), Vector3(0, 0, -22), Vector3(-30, 0, 20)],
			"line:drive",
			"hint:drive"
		),
		_step(QuestStep.Kind.WALK_TO, [DOOR_POS + Vector3(0, 0, 6.5)], "line:to_door", "hint:to_door"),
		_step(QuestStep.Kind.OPEN_DOOR, [], "", ""),
		_step(QuestStep.Kind.FIND_OBJECT, [], "", ""),
	]
	var err: Error = ResourceSaver.save(chapter, "res://content/chapters/greybox_loop.tres")
	print("greybox_loop.tres: ", error_string(err))
	# The prologue: learn to walk, meet the postman (hello, a letter, bye), drive to the ferry,
	# sail to England. Played once; then the practice loop.
	var prologue: ChapterData = ChapterData.new()
	prologue.id = &"prologue"
	prologue.done_key = "chapter:prologue"
	prologue.steps = [
		_step(QuestStep.Kind.WALK_TO, [Vector3(-9, 0, 12)], "line:walk_tutorial", "hint:walk"),
		_step(QuestStep.Kind.TALK_TO, [Vector3(-15, 0, 17)], "line:to_postman", "hint:to_postman"),
		_step(QuestStep.Kind.GET_IN_CAR, [], "", "hint:to_car", "line:here_car"),
		_step(QuestStep.Kind.DRIVE_TO, [Vector3(8.5, 0, 14)], "line:to_ferry", "hint:to_ferry"),
		_step(QuestStep.Kind.FERRY, [], "", ""),
	]
	var err2: Error = ResourceSaver.save(prologue, "res://content/chapters/prologue.tres")
	print("prologue.tres: ", error_string(err2))
	# England practice loop (until Chapter 1): drive round the town, the bakery door, a find.
	var england: ChapterData = ChapterData.new()
	england.id = &"england_practice"
	england.loop = true
	england.loop_line = "line:again"
	england.steps = [
		_step(QuestStep.Kind.GET_IN_CAR, [], "", "hint:to_car", "line:here_car"),
		_step(
			QuestStep.Kind.DRIVE_TO,
			[Vector3(24, 0, -14), Vector3(24, 0, 16), Vector3(-24, 0, 16)],
			"line:drive",
			"hint:drive"
		),
		_step(QuestStep.Kind.WALK_TO, [Vector3(-9.4, 0, -2.9)], "line:to_door", "hint:to_door"),
		_step(QuestStep.Kind.OPEN_DOOR, [], "", ""),
		_step(QuestStep.Kind.FIND_OBJECT, [], "", ""),
	]
	var err3: Error = ResourceSaver.save(england, "res://content/chapters/england_practice.tres")
	print("england_practice.tres: ", error_string(err3))
	# Chapter 1: the baker lost her apples, eggs, milk and flour; find and count them, bring
	# them back through the bakery door, and she bakes a cake.
	var ch1: ChapterData = ChapterData.new()
	ch1.id = &"chapter1_bakery"
	ch1.done_key = "chapter:bakery"
	ch1.next_chapter = "res://content/chapters/england_practice.tres"
	var intro: QuestStep = _step(
		QuestStep.Kind.TALK_TO, [Vector3(-5.5, 0, -6.2)], "ch1:to_baker", "hint:to_baker"
	)
	intro.talk_id = &"baker_intro"
	var thanks: QuestStep = _step(QuestStep.Kind.TALK_TO, [Vector3(-5.5, 0, -6.2)], "", "hint:to_baker")
	thanks.talk_id = &"baker_thanks"
	ch1.steps = [
		intro,
		_collect(&"apple", [Vector3(-30, 0, 18), Vector3(-34, 0, 10), Vector3(-22, 0, 25)]),
		_collect(&"egg", [Vector3(26, 0, 26), Vector3(35, 0, 22)]),
		_collect(&"milk", [Vector3(8, 0, -6)]),
		_collect(&"flour", [Vector3(22, 0, -6)]),
		_step(QuestStep.Kind.WALK_TO, [Vector3(-9.4, 0, -2.9)], "ch1:back_to_baker", "hint:to_door"),
		_step(QuestStep.Kind.OPEN_DOOR, [], "", ""),
		thanks,
	]
	var err4: Error = ResourceSaver.save(ch1, "res://content/chapters/chapter1_bakery.tres")
	print("chapter1_bakery.tres: ", error_string(err4))
	quit(0 if err == OK and err2 == OK and err3 == OK and err4 == OK else 1)


func _collect(word: StringName, spots: Array[Vector3]) -> QuestStep:
	var s: QuestStep = _step(QuestStep.Kind.COLLECT, spots, "", "")
	s.word = word
	s.count = spots.size()
	return s


func _step(
	kind: QuestStep.Kind, spots: Array[Vector3], start_line: String, hint: String, arrive: String = ""
) -> QuestStep:
	var s: QuestStep = QuestStep.new()
	s.kind = kind
	s.spots = spots
	s.start_line = start_line
	s.hint_line = hint
	s.arrive_line = arrive
	return s
