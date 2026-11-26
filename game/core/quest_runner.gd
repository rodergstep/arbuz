class_name QuestRunner
extends Node
## Runs a ChapterData in a scene. The scene reports what happened (car entered, marker reached,
## door opened); the runner decides when a step is done and what comes next. It talks to the
## scene only through the QuestHost methods: place_marker, clear_marker, set_hint, say_when_free,
## exit_car, car_position, start_find, start_talk(talk_id), play_ferry, start_collect(step).

signal step_started(index: int, step: QuestStep)
signal chapter_finished(chapter_id: StringName)

var chapter: ChapterData
var host: Node
var index: int = -1

var _visits: Dictionary[int, int] = {}


func start(data: ChapterData, scene: Node) -> void:
	chapter = data
	host = scene
	_go(0)


func current() -> QuestStep:
	if chapter == null or index < 0 or index >= chapter.steps.size():
		return null
	return chapter.steps[index]


func notify_car_entered() -> void:
	if _is(QuestStep.Kind.GET_IN_CAR):
		_advance()


## body_kind: &"hero" or &"car".
func notify_marker_reached(body_kind: StringName) -> void:
	var step: QuestStep = current()
	if step == null:
		return
	EventLog.log_event(&"marker_reached", {"step": index, "by": String(body_kind)})
	match step.kind:
		QuestStep.Kind.GET_IN_CAR:
			if body_kind == &"hero" and not step.arrive_line.is_empty():
				Speech.line(step.arrive_line, null, true)
		QuestStep.Kind.DRIVE_TO:
			if body_kind == &"car":
				Sfx.play(&"chime")
				# Stay in the car when the ferry comes next.
				if not _next_is(QuestStep.Kind.FERRY):
					host.call("exit_car")
				_advance()
		QuestStep.Kind.WALK_TO:
			if body_kind == &"hero":
				_advance()
		QuestStep.Kind.TALK_TO:
			if body_kind == &"hero":
				host.call("clear_marker")
				host.call("start_talk", step.talk_id)


func notify_door_question() -> void:
	if _is(QuestStep.Kind.WALK_TO) and _next_is(QuestStep.Kind.OPEN_DOOR):
		_advance()


func notify_door_opened() -> void:
	if _is(QuestStep.Kind.OPEN_DOOR):
		_advance()


func notify_talk_done() -> void:
	if _is(QuestStep.Kind.TALK_TO):
		_advance()


func notify_ferry_done() -> void:
	if _is(QuestStep.Kind.FERRY):
		_advance()


func notify_collected() -> void:
	if _is(QuestStep.Kind.COLLECT):
		_advance()


func notify_found() -> void:
	if _is(QuestStep.Kind.FIND_OBJECT):
		_advance()


func _is(kind: QuestStep.Kind) -> bool:
	var step: QuestStep = current()
	return step != null and step.kind == kind


## True when the step after the current one is of this kind.
func next_is(kind: QuestStep.Kind) -> bool:
	return _next_is(kind)


func _next_is(kind: QuestStep.Kind) -> bool:
	return index + 1 < chapter.steps.size() and chapter.steps[index + 1].kind == kind


func _advance() -> void:
	if index + 1 < chapter.steps.size():
		_go(index + 1)
		return
	host.call("clear_marker")
	host.call("set_hint", null, "")
	chapter_finished.emit(chapter.id)
	EventLog.log_event(&"chapter_finished", {"chapter": String(chapter.id)})
	if not chapter.done_key.is_empty():
		SaveSystem.mark_encountered(chapter.done_key)
	if not chapter.next_chapter.is_empty():
		_visits.clear()
		chapter = load(chapter.next_chapter)
		_go(0)
		return
	if chapter.loop:
		index = -1
		var tween: Tween = create_tween()
		tween.tween_interval(chapter.loop_delay)
		tween.tween_callback(_restart)


func _restart() -> void:
	if not chapter.loop_line.is_empty():
		host.call("say_when_free", chapter.loop_line)
	_go(0)


func _go(next: int) -> void:
	index = next
	var step: QuestStep = chapter.steps[next]
	var visit: int = _visits.get(next, 0)
	_visits[next] = visit + 1
	EventLog.log_event(&"step", {"step": next, "kind": QuestStep.Kind.keys()[step.kind]})
	if not step.start_line.is_empty():
		host.call("say_when_free", step.start_line)
	match step.kind:
		QuestStep.Kind.GET_IN_CAR:
			host.call("place_marker", host.call("car_position") + Vector3(-2.2, 0, 0))
		QuestStep.Kind.DRIVE_TO, QuestStep.Kind.WALK_TO, QuestStep.Kind.TALK_TO:
			if step.spots.is_empty():
				host.call("clear_marker")
			else:
				host.call("place_marker", step.spots[visit % step.spots.size()])
		QuestStep.Kind.OPEN_DOOR:
			host.call("clear_marker")
		QuestStep.Kind.FIND_OBJECT:
			host.call("clear_marker")
			host.call("start_find")
			step_started.emit(next, step)
			return
		QuestStep.Kind.COLLECT:
			host.call("clear_marker")
			host.call("start_collect", step)
			step_started.emit(next, step)
			return
		QuestStep.Kind.FERRY:
			host.call("clear_marker")
			host.call("set_hint", null, "")
			host.call("play_ferry")
			step_started.emit(next, step)
			return
	host.call("set_hint", host.get("marker"), step.hint_line)
	step_started.emit(next, step)
