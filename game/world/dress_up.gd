class_name DressUp
extends Node3D
## Customization (roadmap step 27): a paint shop of four big paint pots (red with dots, blue with
## stripes, yellow with plus signs, green with rings: colour is never the only cue) that repaint
## his car, and a hat stand (a cap, a sun hat, a crown) for the boy. Each is a thing to click,
## so it also teaches its word; his choices are kept in the save.

const PAINTS: Array[StringName] = [&"red", &"blue", &"yellow", &"green"]
const HATS: Array[StringName] = [&"cap", &"sun_hat", &"crown"]

var town: GreyboxVillage


func build(the_town: GreyboxVillage, paint_spot: Vector3, hat_spot: Vector3) -> void:
	town = the_town
	for i: int in PAINTS.size():
		var pot: Clickable = _thing(
			&"paint_pot_" + String(PAINTS[i]), PAINTS[i], paint_spot + Vector3(i * 1.9, 0, 0)
		)
		pot.clicked.connect(_on_paint.bind(PAINTS[i]))
	for i: int in HATS.size():
		var word: StringName = &"hat" if HATS[i] == &"sun_hat" else HATS[i]
		var hat: Clickable = _thing(HATS[i], word, hat_spot + Vector3(i * 1.9, 0, 0), 1.6)
		hat.clicked.connect(_on_hat.bind(HATS[i]))


func _thing(model: StringName, word: StringName, at: Vector3, lift: float = 0.0) -> Clickable:
	var art: Node3D = Node3D.new()
	if lift > 0.0:
		# A hat sits on a little wooden stand.
		art.add_child(
			Blocks.box_mesh(Vector3(0.12, lift, 0.12), Color(0.55, 0.4, 0.3), Vector3(0, lift / 2.0, 0))
		)
	var thing_art: Node3D = Props.make(model)
	thing_art.position.y = lift
	art.add_child(thing_art)
	var entry: WordEntry = WordDB.get_word(word)
	var c: Clickable = Clickable.new()
	c.setup(word, entry.uk if entry != null else "", String(word), art, Vector3(1.6, 2.0, 1.6))
	add_child(c)
	c.global_position = at
	return c


func _on_paint(_word: StringName, colour: StringName) -> void:
	var c: Color = Props.BALLOON_COLORS[colour]
	town.car.repaint(c)
	SaveSystem.settings["car_color"] = c.to_html()
	SaveSystem.save_now()
	Sfx.play(&"chime")
	town.say_when_free_word("paint:done", WordDB.get_word(colour))


func _on_hat(_word: StringName, hat: StringName) -> void:
	town.hero.set_hat(hat)
	SaveSystem.settings["hat"] = String(hat)
	SaveSystem.save_now()
	Sfx.play(&"pop")
