extends GutTest

const GamepadCheckScene: PackedScene = preload("res://game/dev/gamepad_check/gamepad_check.tscn")


func test_scene_builds_a_label_for_every_known_button() -> void:
	var scene: Control = GamepadCheckScene.instantiate()
	add_child_autofree(scene)
	var labels: Array[Node] = scene.find_children("*", "Label", true, false)
	assert_gt(labels.size(), scene.BUTTON_NAMES.size())
	assert_eq(scene.seen_count(), 0)
