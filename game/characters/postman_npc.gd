class_name PostmanNpc
extends Node3D
## The English postman of the prologue. When the hero reaches him he says "Hello!" and waves,
## Tygrytsa asks the child to say hello back (microphone, never judged), he hands over a letter
## from England (a learning card), then says "Bye!" and the child says bye. Emits talk_finished.

signal talk_finished

var _model: Node3D
var _arm: Node3D
var _waving: float = 0.0
var _talking: bool = false


func _ready() -> void:
	_model = ModelPainter.load_model("postman")
	add_child(_model)
	_arm = _model.find_child("ArmR", true, false) as Node3D


func _process(delta: float) -> void:
	if _arm == null:
		return
	if _waving > 0.0:
		_waving -= delta
		_arm.rotation.x = -2.6
		_arm.rotation.z = sin(Time.get_ticks_msec() / 120.0) * 0.4
	else:
		_arm.rotation.x = lerpf(_arm.rotation.x, 0.0, minf(1.0, 6.0 * delta))
		_arm.rotation.z = 0.0


func is_talking() -> bool:
	return _talking


## Runs the whole meeting. learning shows the letter card; mic is the on-screen "your turn" sign.
func talk(learning: LearningDirector, mic: Control, look_at_pos: Vector3) -> void:
	if _talking:
		return
	_talking = true
	var alive: Callable = func() -> bool: return is_inside_tree()
	_face(look_at_pos)
	EventLog.log_event(&"postman_talk")
	await _greet(&"hello", "talk:hello", "talk:say_hello", mic, alive)
	Speech.line("talk:letter")
	await SayItBack.wait_until_quiet(self, alive)
	var letter: WordEntry = WordDB.get_word(&"letter")
	if (
		letter != null
		and learning.request(letter.id, global_position, global_position + Vector3(2.5, 2.2, 3.0), true)
	):
		await learning.moment_closed
	await _greet(&"bye", "talk:bye", "talk:say_bye", mic, alive)
	_talking = false
	talk_finished.emit()


## He says the word and waves; Tygrytsa asks for it back; praise.
func _greet(word_id: StringName, his_line: String, her_line: String, mic: Control, alive: Callable) -> void:
	var word: WordEntry = WordDB.get_word(word_id)
	_waving = 2.5
	Speech.line(his_line, word, true)
	await SayItBack.wait_until_quiet(self, alive)
	Speech.line(her_line, word)
	await SayItBack.wait_until_quiet(self, alive)
	LearningTracker.record_heard(word_id)
	var heard: bool = await SayItBack.wait_for_word(self, word, mic, alive)
	await SayItBack.praise(self, word, heard, alive)


func _face(pos: Vector3) -> void:
	var to: Vector3 = pos - global_position
	to.y = 0.0
	if to.length() > 0.1:
		rotation.y = atan2(-to.x, -to.z)
