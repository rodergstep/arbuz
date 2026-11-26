extends SceneTree
## Dev helper: runs the main scene windowed for a moment, simulates a few inputs, and saves
## screenshots to build/shots/. Run: godot --path . --script res://tools/capture.gd

const SHOTS_DIR: String = "res://build/shots"

var _frame: int = 0
var _village: Node


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOTS_DIR))
	var scene: PackedScene = load(ProjectSettings.get_setting("application/run/main_scene"))
	_village = scene.instantiate()
	root.add_child(_village)


func _process(_delta: float) -> bool:
	_frame += 1
	match _frame:
		60:
			_shot("01_start")
			_village.call("_on_pickable_clicked", _village.get("car").get_child(-1))
		240:
			_shot("02_walking_to_car")
		250:
			for child: Node in _village.get_children():
				if child.has_method("say_name") and child.get("word_id") == &"duck":
					_village.call("_on_pickable_clicked", child)
		330:
			_shot("02b_learning_card")
		335:
			_village.get("learning").get("card").call("close")
		420:
			_shot("03_in_car")
			_village.get("car").call("drive_to", Vector3(22, 0, 18))
		700:
			_shot("04_driving")
		760:
			_village.call("_exit_car")
			var hero: Node3D = _village.get("hero")
			hero.global_position = Vector3(-14, 0, -14)
		900:
			_shot("05_door_cards")
			var door: Node = _village.get("door")
			var cards: Array = door.get("cards")
			for card: Node in cards:
				if not card.get("is_answer"):
					door.call("pick", card)
					break
		960:
			var door: Node = _village.get("door")
			var cards: Array = door.get("cards")
			for card: Node in cards:
				if not card.get("is_answer"):
					door.call("pick", card)
		1100:
			_shot("06_door_open")
		1150:
			return true
	return false


func _shot(shot_name: String) -> void:
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("%s/%s.png" % [SHOTS_DIR, shot_name]))
	print("shot ", shot_name, " step=", _village.get("step"))
