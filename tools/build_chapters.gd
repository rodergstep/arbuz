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
	ch1.next_chapter = "res://content/chapters/chapter2_balloons.tres"
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
	# Chapter 2: the toy maker's balloons flew away; find the red, blue, yellow and green one
	# (each with its own pattern), bring them back.
	var ch2: ChapterData = ChapterData.new()
	ch2.id = &"chapter2_balloons"
	ch2.done_key = "chapter:balloons"
	ch2.next_chapter = "res://content/chapters/chapter3_animals.tres"
	var toy_spot: Array[Vector3] = [Vector3(-30, 0, 13.5)]
	var hello: QuestStep = _step(QuestStep.Kind.TALK_TO, toy_spot, "ch2:to_toy_maker", "hint:to_toy_maker")
	hello.talk_id = &"toy_intro"
	var bye: QuestStep = _step(QuestStep.Kind.TALK_TO, toy_spot, "ch2:back_to_toy_maker", "hint:to_toy_maker")
	bye.talk_id = &"toy_thanks"
	ch2.steps = [
		hello,
		_balloon(&"red", Vector3(-32, 0, 22)),
		_balloon(&"blue", Vector3(14, 0, -28)),
		_balloon(&"yellow", Vector3(6, 0, 9)),
		_balloon(&"green", Vector3(-14, 0, 22)),
		bye,
	]
	var err5: Error = ResourceSaver.save(ch2, "res://content/chapters/chapter2_balloons.tres")
	print("chapter2_balloons.tres: ", error_string(err5))
	# Chapter 3: the farm animals ran away; find the cow, the sheep, the duck and the pig, each
	# says its sound and name and trots home to the farm.
	var ch3: ChapterData = ChapterData.new()
	ch3.id = &"chapter3_animals"
	ch3.done_key = "chapter:animals"
	ch3.next_chapter = "res://content/chapters/england_practice.tres"
	var farm_spot: Array[Vector3] = [Vector3(24, 0, 22.5)]
	var meet: QuestStep = _step(QuestStep.Kind.TALK_TO, farm_spot, "ch3:to_farmer", "hint:to_farmer")
	meet.talk_id = &"farmer_intro"
	var done: QuestStep = _step(QuestStep.Kind.TALK_TO, farm_spot, "ch3:back_to_farmer", "hint:to_farmer")
	done.talk_id = &"farmer_thanks"
	ch3.steps = [
		meet,
		_animal(&"cow", Vector3(-18, 0, -27), Vector3(28, 0, 21)),
		_animal(&"sheep", Vector3(-34, 0, 28), Vector3(30.5, 0, 21)),
		_animal(&"duck", Vector3(20, 0, -28.5), Vector3(32.5, 0, 21)),
		_animal(&"pig", Vector3(8, 0, 12), Vector3(34.5, 0, 21)),
		done,
	]
	var err6: Error = ResourceSaver.save(ch3, "res://content/chapters/chapter3_animals.tres")
	print("chapter3_animals.tres: ", error_string(err6))
	quit(0 if err == OK and err2 == OK and err3 == OK and err4 == OK and err5 == OK and err6 == OK else 1)


func _animal(animal: StringName, spot: Vector3, home: Vector3) -> QuestStep:
	var s: QuestStep = _collect(animal, [spot])
	s.find_line = "ch3:find_animal"
	s.found_line = "ch3:found_%s" % animal
	s.hint_line = "ch3:find_animal"
	s.homes = [home]
	return s


func _balloon(colour: StringName, spot: Vector3) -> QuestStep:
	var s: QuestStep = _collect(colour, [spot])
	s.find_line = "ch2:find_balloon"
	s.found_line = "ch2:found_balloon"
	s.hint_line = "ch2:find_balloon"
	return s


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
