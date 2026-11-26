class_name BakerNpc
extends Node3D
## The baker of Chapter 1 (her own English voice). intro(): she lost her apples, eggs, milk and
## flour and asks for help, and the child says hello back. thanks(): she gets everything back,
## bakes a cake (learning card) and everyone cheers.

signal talk_finished

var _model: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _waving: float = 0.0
var _talking: bool = false


func _ready() -> void:
	_model = ModelPainter.load_model("baker")
	add_child(_model)
	_arm_l = _model.find_child("ArmL", true, false) as Node3D
	_arm_r = _model.find_child("ArmR", true, false) as Node3D


func _process(delta: float) -> void:
	if _arm_r == null:
		return
	if _waving > 0.0:
		_waving -= delta
		var wave: float = sin(Time.get_ticks_msec() / 120.0) * 0.4
		_arm_r.rotation = Vector3(-2.6, 0.0, wave)
		_arm_l.rotation = Vector3(-2.6, 0.0, -wave)
	else:
		_arm_r.rotation = _arm_r.rotation.lerp(Vector3.ZERO, minf(1.0, 6.0 * delta))
		_arm_l.rotation = _arm_l.rotation.lerp(Vector3.ZERO, minf(1.0, 6.0 * delta))


func is_talking() -> bool:
	return _talking


func intro(mic: Control, look_at_pos: Vector3) -> void:
	_talking = true
	var alive: Callable = func() -> bool: return is_inside_tree()
	_face(look_at_pos)
	_waving = 2.0
	Speech.line("ch1:baker_hello", null, true)
	await SayItBack.wait_until_quiet(self, alive)
	Speech.line("ch1:baker_help")
	await SayItBack.wait_until_quiet(self, alive)
	Speech.line("ch1:help_baker")
	await SayItBack.wait_until_quiet(self, alive)
	# He greets her back: hello (taught by the postman in the prologue).
	var hello: WordEntry = WordDB.get_word(&"hello")
	Speech.line("talk:say_hello", hello)
	await SayItBack.wait_until_quiet(self, alive)
	var heard: bool = await SayItBack.wait_for_word(self, hello, mic, alive)
	await SayItBack.praise(self, hello, heard, alive)
	_talking = false
	talk_finished.emit()


func thanks(learning: LearningDirector, look_at_pos: Vector3) -> void:
	_talking = true
	var alive: Callable = func() -> bool: return is_inside_tree()
	_face(look_at_pos)
	_waving = 3.0
	Speech.line("ch1:baker_thanks", null, true)
	await SayItBack.wait_until_quiet(self, alive)
	Speech.line("ch1:baker_cake")
	await SayItBack.wait_until_quiet(self, alive)
	if learning.request(&"cake", global_position, global_position + Vector3(2.5, 2.2, 3.0), true):
		await learning.moment_closed
	_waving = 3.0
	Sfx.play(&"door")
	Speech.line("ch1:hooray")
	await SayItBack.wait_until_quiet(self, alive)
	_talking = false
	talk_finished.emit()


func _face(pos: Vector3) -> void:
	var to: Vector3 = pos - global_position
	to.y = 0.0
	if to.length() > 0.1:
		rotation.y = atan2(-to.x, -to.z)
