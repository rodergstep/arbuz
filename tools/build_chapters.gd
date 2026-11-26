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
	quit(0 if err == OK else 1)


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
