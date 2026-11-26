extends Node
## Starts the game in the right place: the Ukrainian village (prologue) until the prologue is
## done, then the English town.

const VILLAGE: String = "res://game/world/greybox/greybox_village.tscn"
const ENGLAND: String = "res://game/world/england/england_town.tscn"


func _ready() -> void:
	var scene: String = ENGLAND if SaveSystem.has_encountered(GreyboxVillage.PROLOGUE_DONE) else VILLAGE
	get_tree().change_scene_to_file.call_deferred(scene)
