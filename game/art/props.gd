class_name Props
extends RefCounted
## Every small thing in the game by name (an apple, a ball, a dog, a red balloon, the number
## three, a bridge…), for the world, the chapters' finds and the learning cards' little scenes.
## A model in assets/models/<name>.glb wins (made by tools/blender/build_models.py); otherwise
## it is built here from painted shapes. Each thing stands on y = 0, facing +z.

## Word ids whose model file has another name.
const ALIASES: Dictionary[String, String] = {
	"car": "car_hatchback",
	"house": "english_house",
	"shop": "toy_shop",
	"toymaker": "toy_maker",
	"clockmaker": "clock_maker",
	"clock_tower": "clock_tower",
}
## A balloon in a colour word's colour, always with its own pattern too, so colour is never
## the only cue: red has dots, blue has stripes, yellow has plus signs, green has upright rings.
const BALLOON_COLORS: Dictionary[StringName, Color] = {
	&"red": Color(0.88, 0.22, 0.24),
	&"blue": Color(0.25, 0.48, 0.88),
	&"yellow": Color(0.98, 0.82, 0.20),
	&"green": Color(0.30, 0.70, 0.36),
}
const NUMBERS: Dictionary[StringName, int] = {&"one": 1, &"two": 2, &"three": 3, &"four": 4, &"five": 5}
const WHITE: Color = Color(0.98, 0.98, 0.96)
const INK: Color = Color(0.16, 0.14, 0.14)


## True when the thing comes from a model file (those face -z; built shapes face +z).
static func is_model(thing: StringName) -> bool:
	var model_name: String = ALIASES.get(String(thing), String(thing))
	return ResourceLoader.exists("%s/%s.glb" % [ModelPainter.MODELS_DIR, model_name])


static func make(thing: StringName) -> Node3D:
	if is_model(thing):
		return ModelPainter.load_model(ALIASES.get(String(thing), String(thing)))
	var root: Node3D = Node3D.new()
	root.name = String(thing)
	var name: String = String(thing)
	if name.begins_with("paint_pot_"):
		_paint_pot(root, StringName(name.trim_prefix("paint_pot_")))
	elif name.begins_with("balloon_"):
		_balloon(root, StringName(name.trim_prefix("balloon_")))
	elif BALLOON_COLORS.has(thing):
		_balloon(root, thing)
	elif NUMBERS.has(thing):
		_number(root, thing)
	elif _builders().has(name):
		_builders()[name].call(root)
	else:
		_sphere(root, 0.3, Color(0.9, 0.8, 0.4), Vector3(0, 0.3, 0))
	return root


static func _builders() -> Dictionary[String, Callable]:
	return {
		"apple": _apple,
		"egg": _egg,
		"milk": _milk,
		"flour": _flour,
		"ball": _ball,
		"flower": _flower,
		"dog": _dog,
		"cat": _cat,
		"lion": _lion,
		"hen": _hen,
		"bird": _bird,
		"sun": _sun,
		"cloud": _cloud,
		"moon": _moon,
		"bridge": _bridge,
		"boat": _boat,
		"bus": _bus,
		"letter": _letter,
		"door": _door,
		"clock": _clock,
		"cake": _cake,
		"bread": _bread,
		"cup": _cup,
		"table": _table,
		"toy": _toy,
		"teddy": _teddy,
		"bulb_horn": _bulb_horn,
		"bell": _bell,
		"cap": _cap,
		"sun_hat": _sun_hat,
		"butterfly": _butterfly,
		"kite": _kite,
		"star": _star,
		"umbrella": _umbrella,
		"teapot": _teapot,
		"crown": _crown,
		"arrow_left": func(r: Node3D) -> void: _arrow(r, -1.0),
		"arrow_right": func(r: Node3D) -> void: _arrow(r, 1.0),
		"balloon": func(r: Node3D) -> void: _balloon(r, &"red"),
	}


# --- small helpers ---------------------------------------------------------------------


static func _sphere(root: Node3D, r: float, color: Color, pos: Vector3, h: float = -1.0) -> MeshInstance3D:
	var m: SphereMesh = SphereMesh.new()
	m.radius = r
	m.height = r * 2.0 if h < 0.0 else h
	var inst: MeshInstance3D = Blocks.mesh(m, color, pos)
	root.add_child(inst)
	return inst


static func _box(root: Node3D, size: Vector3, color: Color, pos: Vector3) -> MeshInstance3D:
	var inst: MeshInstance3D = Blocks.box_mesh(size, color, pos)
	root.add_child(inst)
	return inst


static func _cyl(
	root: Node3D, r_top: float, r_bottom: float, h: float, color: Color, pos: Vector3
) -> MeshInstance3D:
	var m: CylinderMesh = CylinderMesh.new()
	m.top_radius = r_top
	m.bottom_radius = r_bottom
	m.height = h
	var inst: MeshInstance3D = Blocks.mesh(m, color, pos)
	root.add_child(inst)
	return inst


## Two friendly eyes (white with a dark pupil) on a face at `pos`, looking along +z.
static func _eyes(root: Node3D, pos: Vector3, spacing: float, size: float) -> void:
	for side: float in [-1.0, 1.0]:
		var p: Vector3 = pos + Vector3(side * spacing / 2.0, 0, 0)
		_sphere(root, size, WHITE, p)
		_sphere(root, size * 0.55, INK, p + Vector3(0, 0, size * 0.6))


# --- food --------------------------------------------------------------------------------


static func _apple(root: Node3D) -> void:
	_sphere(root, 0.32, Color(0.88, 0.22, 0.24), Vector3(0, 0.3, 0), 0.6)
	_box(root, Vector3(0.04, 0.16, 0.04), Color(0.45, 0.3, 0.2), Vector3(0, 0.66, 0))
	_sphere(root, 0.1, Color(0.35, 0.65, 0.3), Vector3(0.1, 0.68, 0), 0.06)


static func _egg(root: Node3D) -> void:
	_sphere(root, 0.22, Color(0.98, 0.95, 0.88), Vector3(0, 0.3, 0), 0.58)


static func _milk(root: Node3D) -> void:
	_cyl(root, 0.14, 0.22, 0.7, WHITE, Vector3(0, 0.35, 0))
	_box(root, Vector3(0.2, 0.08, 0.2), Color(0.3, 0.55, 0.85), Vector3(0, 0.74, 0))


static func _flour(root: Node3D) -> void:
	_sphere(root, 0.36, Color(0.92, 0.88, 0.78), Vector3(0, 0.38, 0), 0.8)
	_box(root, Vector3(0.18, 0.12, 0.18), Color(0.7, 0.55, 0.35), Vector3(0, 0.8, 0))


static func _cake(root: Node3D) -> void:
	_cyl(root, 0.55, 0.55, 0.3, Color(0.96, 0.80, 0.62), Vector3(0, 0.15, 0))
	_cyl(root, 0.57, 0.57, 0.06, WHITE, Vector3(0, 0.32, 0))
	_cyl(root, 0.4, 0.4, 0.3, Color(0.98, 0.72, 0.78), Vector3(0, 0.5, 0))
	_sphere(root, 0.1, Color(0.85, 0.15, 0.2), Vector3(0, 0.74, 0))
	for i: int in 3:
		var a: float = TAU * i / 3.0
		_cyl(root, 0.025, 0.025, 0.2, Color(0.55, 0.75, 0.95), Vector3(cos(a) * 0.22, 0.75, sin(a) * 0.22))
		_sphere(root, 0.04, Color(1.0, 0.8, 0.3), Vector3(cos(a) * 0.22, 0.88, sin(a) * 0.22))


static func _bread(root: Node3D) -> void:
	var loaf: MeshInstance3D = _sphere(root, 0.4, Color(0.85, 0.6, 0.32), Vector3(0, 0.22, 0), 0.45)
	loaf.scale = Vector3(1.4, 1.0, 0.8)
	for i: int in 3:
		_box(root, Vector3(0.05, 0.02, 0.4), Color(0.95, 0.82, 0.6), Vector3(-0.25 + i * 0.25, 0.44, 0))


static func _cup(root: Node3D) -> void:
	_cyl(root, 0.2, 0.17, 0.4, WHITE, Vector3(0, 0.2, 0))
	_cyl(root, 0.18, 0.18, 0.02, WHITE.darkened(0.03), Vector3(0, 0.39, 0))
	var handle: TorusMesh = TorusMesh.new()
	handle.inner_radius = 0.07
	handle.outer_radius = 0.11
	var inst: MeshInstance3D = Blocks.mesh(handle, WHITE, Vector3(0.22, 0.22, 0))
	inst.rotation.x = PI / 2.0
	root.add_child(inst)


static func _table(root: Node3D) -> void:
	_cyl(root, 1.0, 1.0, 0.1, Color(0.98, 0.97, 0.94), Vector3(0, 0.85, 0))
	_box(root, Vector3(0.16, 0.8, 0.16), Color(0.62, 0.44, 0.30), Vector3(0, 0.4, 0))
	_cyl(root, 0.4, 0.4, 0.05, Color(0.62, 0.44, 0.30), Vector3(0, 0.03, 0))


# --- toys and things -------------------------------------------------------------------


static func _ball(root: Node3D) -> void:
	_sphere(root, 0.4, Color(0.9, 0.3, 0.35), Vector3(0, 0.4, 0))
	var band: TorusMesh = TorusMesh.new()
	band.inner_radius = 0.38
	band.outer_radius = 0.42
	var inst: MeshInstance3D = Blocks.mesh(band, WHITE, Vector3(0, 0.4, 0))
	inst.rotation.z = PI / 2.0
	root.add_child(inst)


static func _toy(root: Node3D) -> void:
	# A little wooden toy train engine.
	_box(root, Vector3(0.8, 0.4, 0.5), Color(0.3, 0.55, 0.85), Vector3(0, 0.35, 0))
	_box(root, Vector3(0.35, 0.4, 0.5), Color(0.88, 0.3, 0.3), Vector3(-0.22, 0.75, 0))
	_cyl(root, 0.08, 0.1, 0.3, INK, Vector3(0.25, 0.7, 0))
	for x: float in [-0.25, 0.25]:
		for z: float in [-0.27, 0.27]:
			var wheel: MeshInstance3D = _cyl(
				root, 0.14, 0.14, 0.06, Color(0.98, 0.82, 0.2), Vector3(x, 0.14, z)
			)
			wheel.rotation.x = PI / 2.0


## A big friendly arrow pointing left (-1) or right (+1), seen from the front.
static func _arrow(root: Node3D, side: float) -> void:
	var colour: Color = Color(0.98, 0.62, 0.18)
	_box(root, Vector3(0.9, 0.32, 0.14), colour, Vector3(-side * 0.2, 0, 0))
	var head: PrismMesh = PrismMesh.new()
	head.size = Vector3(0.7, 0.6, 0.14)
	var inst: MeshInstance3D = Blocks.mesh(head, colour, Vector3(side * 0.45, 0, 0))
	inst.rotation.z = -side * PI / 2.0
	root.add_child(inst)


static func _butterfly(root: Node3D) -> void:
	for side: float in [-1.0, 1.0]:
		var wing: SphereMesh = SphereMesh.new()
		wing.radius = 0.28
		wing.height = 0.05
		var w: MeshInstance3D = Blocks.mesh(wing, Color(0.98, 0.55, 0.2), Vector3(side * 0.27, 0.6, 0))
		w.rotation.z = side * 0.35
		root.add_child(w)
		_sphere(root, 0.07, INK, Vector3(side * 0.3, 0.63, 0.04), 0.05)
	_cyl(root, 0.04, 0.04, 0.36, INK, Vector3(0, 0.6, 0)).rotation.x = PI / 2.0


## A big paint pot in a colour word's colour with that colour's own pattern (dots, stripes,
## a plus, rings), a lid of paint and a brush.
static func _paint_pot(root: Node3D, id: StringName) -> void:
	var c: Color = BALLOON_COLORS.get(id, Color.WHITE)
	_cyl(root, 0.42, 0.36, 0.8, c, Vector3(0, 0.4, 0))
	_cyl(root, 0.44, 0.44, 0.06, c.darkened(0.25), Vector3(0, 0.81, 0))
	var drip: MeshInstance3D = _sphere(root, 0.12, c, Vector3(0.3, 0.7, 0.28), 0.3)
	drip.scale = Vector3(0.6, 1.4, 0.6)
	match id:
		&"red":
			for a: float in [0.0, 1.2, 2.4, 3.6, 4.8]:
				_sphere(root, 0.07, WHITE, Vector3(sin(a) * 0.41, 0.45, cos(a) * 0.41))
		&"blue":
			for y: float in [0.25, 0.55]:
				var band: TorusMesh = TorusMesh.new()
				band.inner_radius = 0.38
				band.outer_radius = 0.43
				root.add_child(Blocks.mesh(band, WHITE, Vector3(0, y, 0)))
		&"yellow":
			_box(root, Vector3(0.3, 0.08, 0.05), WHITE, Vector3(0, 0.45, 0.41))
			_box(root, Vector3(0.08, 0.3, 0.05), WHITE, Vector3(0, 0.45, 0.41))
		&"green":
			var ring: TorusMesh = TorusMesh.new()
			ring.inner_radius = 0.12
			ring.outer_radius = 0.17
			var r: MeshInstance3D = Blocks.mesh(ring, WHITE, Vector3(0, 0.45, 0.41))
			r.rotation.x = PI / 2.0
			root.add_child(r)
	var brush: MeshInstance3D = _box(
		root, Vector3(0.06, 0.6, 0.06), Color(0.6, 0.42, 0.28), Vector3(-0.1, 1.05, 0)
	)
	brush.rotation.z = 0.35
	_box(root, Vector3(0.16, 0.14, 0.08), c, Vector3(0.0, 0.78, 0))


static func _cap(root: Node3D) -> void:
	var blue: Color = Color(0.25, 0.48, 0.88)
	var dome: SphereMesh = SphereMesh.new()
	dome.radius = 0.32
	dome.height = 0.32
	dome.is_hemisphere = true
	root.add_child(Blocks.mesh(dome, blue, Vector3.ZERO))
	var peak: MeshInstance3D = _cyl(root, 0.22, 0.22, 0.03, blue.darkened(0.2), Vector3(0, 0.02, 0.24))
	peak.scale = Vector3(1.0, 1.0, 0.7)
	_sphere(root, 0.05, WHITE, Vector3(0, 0.3, 0))


static func _sun_hat(root: Node3D) -> void:
	var straw: Color = Color(0.96, 0.84, 0.48)
	_cyl(root, 0.55, 0.55, 0.04, straw, Vector3(0, 0.02, 0))
	var crown: SphereMesh = SphereMesh.new()
	crown.radius = 0.3
	crown.height = 0.4
	crown.is_hemisphere = true
	root.add_child(Blocks.mesh(crown, straw, Vector3(0, 0.02, 0)))
	_cyl(root, 0.31, 0.31, 0.07, Color(0.88, 0.3, 0.35), Vector3(0, 0.07, 0))


## A big old-fashioned bulb horn: a red rubber bulb and a golden trumpet.
static func _bulb_horn(root: Node3D) -> void:
	_sphere(root, 0.2, Color(0.85, 0.2, 0.2), Vector3(-0.35, 0.25, 0))
	var pipe: MeshInstance3D = _cyl(root, 0.05, 0.05, 0.4, Color(0.95, 0.78, 0.3), Vector3(-0.05, 0.25, 0))
	pipe.rotation.z = PI / 2.0
	var bell: MeshInstance3D = _cyl(root, 0.26, 0.05, 0.4, Color(0.98, 0.82, 0.3), Vector3(0.3, 0.25, 0))
	bell.rotation.z = PI / 2.0


## A bicycle bell: a shiny dome with a little lever.
static func _bell(root: Node3D) -> void:
	var dome: SphereMesh = SphereMesh.new()
	dome.radius = 0.28
	dome.height = 0.28
	dome.is_hemisphere = true
	root.add_child(Blocks.mesh(dome, Color(0.85, 0.87, 0.9), Vector3(0, 0.12, 0)))
	_cyl(root, 0.06, 0.06, 0.12, Color(0.3, 0.3, 0.32), Vector3(0, 0.06, 0))
	_box(root, Vector3(0.25, 0.04, 0.06), Color(0.85, 0.2, 0.2), Vector3(0.2, 0.18, 0.1))


static func _teddy(root: Node3D) -> void:
	var fur: Color = Color(0.74, 0.50, 0.30)
	var light: Color = Color(0.95, 0.82, 0.62)
	_sphere(root, 0.32, fur, Vector3(0, 0.38, 0), 0.7)
	_sphere(root, 0.18, light, Vector3(0, 0.36, 0.22), 0.3)
	_sphere(root, 0.26, fur, Vector3(0, 0.86, 0))
	_sphere(root, 0.1, light, Vector3(0, 0.8, 0.22), 0.16)
	_sphere(root, 0.04, INK, Vector3(0, 0.84, 0.31))
	_eyes(root, Vector3(0, 0.93, 0.21), 0.16, 0.04)
	for side: float in [-1.0, 1.0]:
		_sphere(root, 0.09, fur, Vector3(side * 0.2, 1.08, 0))
		_sphere(root, 0.05, light, Vector3(side * 0.2, 1.08, 0.05))
		_sphere(root, 0.1, fur, Vector3(side * 0.3, 0.45, 0.08), 0.24)
		_sphere(root, 0.11, fur, Vector3(side * 0.16, 0.08, 0.12), 0.18)
	_box(root, Vector3(0.36, 0.06, 0.08), Color(0.85, 0.2, 0.25), Vector3(0, 0.66, 0.15))


static func _kite(root: Node3D) -> void:
	var diamond: PrismMesh = PrismMesh.new()
	diamond.size = Vector3(0.9, 0.6, 0.04)
	var top: MeshInstance3D = Blocks.mesh(diamond, Color(0.9, 0.25, 0.25), Vector3(0, 1.3, 0))
	root.add_child(top)
	var bottom: MeshInstance3D = Blocks.mesh(diamond.duplicate(), Color(0.98, 0.8, 0.2), Vector3(0, 0.7, 0))
	bottom.rotation.z = PI
	root.add_child(bottom)
	_box(root, Vector3(0.03, 1.2, 0.05), Color(0.55, 0.4, 0.3), Vector3(0, 1.0, 0.03))
	for i: int in 4:
		var bow: MeshInstance3D = _box(
			root, Vector3(0.14, 0.06, 0.03), Color(0.3, 0.55, 0.9), Vector3(0.05 * (i % 2), 0.3 - i * 0.18, 0)
		)
		bow.rotation.z = 0.5 if i % 2 == 0 else -0.5


static func _star(root: Node3D) -> void:
	var gold: Color = Color(1.0, 0.84, 0.25)
	_sphere(root, 0.22, gold, Vector3(0, 0.6, 0), 0.18)
	for i: int in 5:
		var a: float = TAU * i / 5.0
		var ray: PrismMesh = PrismMesh.new()
		ray.size = Vector3(0.26, 0.34, 0.16)
		var inst: MeshInstance3D = Blocks.mesh(ray, gold, Vector3(sin(a) * 0.3, 0.6 + cos(a) * 0.3, 0))
		inst.rotation.z = -a
		root.add_child(inst)
	_eyes(root, Vector3(0, 0.64, 0.09), 0.1, 0.03)


static func _umbrella(root: Node3D) -> void:
	var canopy: SphereMesh = SphereMesh.new()
	canopy.radius = 0.8
	canopy.height = 0.8
	canopy.is_hemisphere = true
	root.add_child(Blocks.mesh(canopy, Color(0.28, 0.5, 0.88), Vector3(0, 1.45, 0)))
	for i: int in 6:
		var a: float = TAU * i / 6.0
		_sphere(root, 0.06, WHITE, Vector3(cos(a) * 0.78, 1.45, sin(a) * 0.78))
	_box(root, Vector3(0.04, 1.4, 0.04), Color(0.3, 0.3, 0.32), Vector3(0, 0.75, 0))
	var hook: TorusMesh = TorusMesh.new()
	hook.inner_radius = 0.08
	hook.outer_radius = 0.12
	var h: MeshInstance3D = Blocks.mesh(hook, Color(0.55, 0.35, 0.2), Vector3(0.1, 0.06, 0))
	h.rotation.x = PI / 2.0
	root.add_child(h)


static func _teapot(root: Node3D) -> void:
	var china: Color = Color(0.96, 0.95, 0.98)
	var blue: Color = Color(0.3, 0.5, 0.85)
	_sphere(root, 0.32, china, Vector3(0, 0.32, 0), 0.56)
	var band: TorusMesh = TorusMesh.new()
	band.inner_radius = 0.3
	band.outer_radius = 0.34
	root.add_child(Blocks.mesh(band, blue, Vector3(0, 0.32, 0)))
	_cyl(root, 0.14, 0.18, 0.08, china, Vector3(0, 0.62, 0))
	_sphere(root, 0.05, blue, Vector3(0, 0.69, 0))
	var spout: MeshInstance3D = _cyl(root, 0.04, 0.07, 0.36, china, Vector3(0.36, 0.4, 0))
	spout.rotation.z = -0.8
	var handle: TorusMesh = TorusMesh.new()
	handle.inner_radius = 0.09
	handle.outer_radius = 0.14
	var h: MeshInstance3D = Blocks.mesh(handle, china, Vector3(-0.34, 0.36, 0))
	h.rotation.x = PI / 2.0
	root.add_child(h)


static func _crown(root: Node3D) -> void:
	var gold: Color = Color(1.0, 0.8, 0.22)
	_cyl(root, 0.36, 0.34, 0.24, gold, Vector3(0, 0.12, 0))
	for i: int in 6:
		var a: float = TAU * i / 6.0
		var spike: CylinderMesh = CylinderMesh.new()
		spike.top_radius = 0.0
		spike.bottom_radius = 0.1
		spike.height = 0.26
		root.add_child(Blocks.mesh(spike, gold, Vector3(cos(a) * 0.3, 0.36, sin(a) * 0.3)))
		_sphere(root, 0.04, WHITE, Vector3(cos(a) * 0.3, 0.5, sin(a) * 0.3))
	for i: int in 4:
		var a: float = TAU * i / 4.0 + 0.4
		_sphere(
			root,
			0.06,
			Color(0.85, 0.15, 0.25) if i % 2 == 0 else Color(0.2, 0.45, 0.9),
			Vector3(cos(a) * 0.36, 0.13, sin(a) * 0.36)
		)


static func _letter(root: Node3D) -> void:
	_box(root, Vector3(0.7, 0.04, 0.48), WHITE, Vector3(0, 0.03, 0))
	var flap: PrismMesh = PrismMesh.new()
	flap.size = Vector3(0.7, 0.26, 0.02)
	var inst: MeshInstance3D = Blocks.mesh(flap, Color(0.92, 0.9, 0.86), Vector3(0, 0.06, -0.11))
	inst.rotation.x = -PI / 2.0
	root.add_child(inst)
	_sphere(root, 0.07, Color(0.85, 0.2, 0.22), Vector3(0, 0.07, 0.02), 0.04)


static func _door(root: Node3D) -> void:
	# A door in its frame; the door itself ("Leaf") turns on its hinge at x = -0.6.
	var wall: Color = Color(0.95, 0.88, 0.75)
	_box(root, Vector3(0.3, 2.4, 0.3), wall, Vector3(-0.75, 1.2, 0))
	_box(root, Vector3(0.3, 2.4, 0.3), wall, Vector3(0.75, 1.2, 0))
	_box(root, Vector3(1.8, 0.3, 0.3), wall, Vector3(0, 2.5, 0))
	var leaf: Node3D = Node3D.new()
	leaf.name = "Leaf"
	leaf.position = Vector3(-0.6, 0, 0)
	root.add_child(leaf)
	_box(leaf, Vector3(1.2, 2.2, 0.1), Color(0.55, 0.35, 0.65), Vector3(0.6, 1.1, 0))
	_sphere(leaf, 0.07, Color(0.98, 0.82, 0.2), Vector3(1.05, 1.1, 0.08))


static func _clock(root: Node3D) -> void:
	# A round clock on a stand; its hands ("Hand") turn.
	_box(root, Vector3(0.12, 1.0, 0.12), Color(0.55, 0.4, 0.3), Vector3(0, 0.5, 0))
	var face: MeshInstance3D = _cyl(root, 0.6, 0.6, 0.12, Color(0.98, 0.95, 0.86), Vector3(0, 1.6, 0))
	face.rotation.x = PI / 2.0
	var rim: TorusMesh = TorusMesh.new()
	rim.inner_radius = 0.58
	rim.outer_radius = 0.68
	var rim_inst: MeshInstance3D = Blocks.mesh(rim, Color(0.85, 0.55, 0.3), Vector3(0, 1.6, 0))
	rim_inst.rotation.x = PI / 2.0
	root.add_child(rim_inst)
	for i: int in 12:
		var a: float = TAU * i / 12.0
		_sphere(root, 0.04, INK, Vector3(sin(a) * 0.48, 1.6 + cos(a) * 0.48, 0.07))
	var hand: Node3D = Node3D.new()
	hand.name = "Hand"
	hand.position = Vector3(0, 1.6, 0.09)
	root.add_child(hand)
	_box(hand, Vector3(0.05, 0.42, 0.02), INK, Vector3(0, 0.19, 0))
	_box(root, Vector3(0.05, 0.3, 0.02), INK, Vector3(0.1, 1.6, 0.08)).rotation.z = -PI / 2.0
	_sphere(root, 0.05, Color(0.85, 0.3, 0.25), Vector3(0, 1.6, 0.1))


static func _flower(root: Node3D) -> void:
	_box(root, Vector3(0.08, 1.0, 0.08), Color(0.3, 0.6, 0.3), Vector3(0, 0.5, 0))
	_sphere(root, 0.16, Color(0.4, 0.7, 0.35), Vector3(0.14, 0.45, 0), 0.06)
	for i: int in 6:
		var a: float = TAU * i / 6.0
		_sphere(root, 0.16, Color(1.0, 0.85, 0.2), Vector3(cos(a) * 0.2, 1.1 + sin(a) * 0.2, 0), 0.08)
	_sphere(root, 0.12, Color(0.85, 0.5, 0.2), Vector3(0, 1.1, 0.03), 0.1)


static func _bridge(root: Node3D) -> void:
	# An arched wooden bridge along x (over water running along z): deck rises to 0.7 m.
	var wood: Color = Color(0.7, 0.5, 0.32)
	for i: int in 13:
		var x: float = -3.0 + i * 0.5
		var y: float = bridge_height(x)
		_box(root, Vector3(0.45, 0.12, 1.6), wood, Vector3(x, y, 0))
	for side: float in [-0.8, 0.8]:
		for i: int in 7:
			var x: float = -3.0 + i * 1.0
			_box(root, Vector3(0.1, 0.6, 0.1), wood.darkened(0.2), Vector3(x, bridge_height(x) + 0.3, side))
		for i: int in 6:
			var x: float = -2.5 + i * 1.0
			var rail: MeshInstance3D = _box(
				root, Vector3(1.05, 0.08, 0.08), wood.darkened(0.1), Vector3(x, bridge_height(x) + 0.6, side)
			)
			rail.rotation.z = atan2(bridge_height(x + 0.5) - bridge_height(x - 0.5), 1.0)


## The bridge deck's height at x (an arch from x = -3 to 3).
static func bridge_height(x: float) -> float:
	return 0.1 + 0.7 * maxf(0.0, cos(clampf(x / 3.0, -1.0, 1.0) * PI / 2.0))


static func _boat(root: Node3D) -> void:
	var hull: MeshInstance3D = _sphere(root, 0.7, Color(0.85, 0.3, 0.25), Vector3(0, 0.15, 0), 0.6)
	hull.scale = Vector3(0.7, 0.8, 1.6)
	_box(root, Vector3(0.06, 1.6, 0.06), Color(0.55, 0.4, 0.3), Vector3(0, 1.0, 0))
	var sail: PrismMesh = PrismMesh.new()
	sail.size = Vector3(0.9, 1.2, 0.03)
	var inst: MeshInstance3D = Blocks.mesh(sail, WHITE, Vector3(0, 1.1, 0.35))
	inst.rotation.y = PI / 2.0
	root.add_child(inst)


static func _bus(root: Node3D) -> void:
	var red: Color = Color(0.86, 0.2, 0.2)
	_box(root, Vector3(1.3, 1.5, 3.2), red, Vector3(0, 1.0, 0))
	_box(root, Vector3(1.32, 0.12, 3.22), WHITE, Vector3(0, 1.15, 0))
	for side: float in [-0.66, 0.66]:
		for i: int in 4:
			_box(root, Vector3(0.02, 0.4, 0.55), Color(0.7, 0.85, 0.95), Vector3(side, 1.45, -1.1 + i * 0.72))
	_box(root, Vector3(1.1, 0.5, 0.02), Color(0.7, 0.85, 0.95), Vector3(0, 1.4, 1.61))
	for x: float in [-0.6, 0.6]:
		for z: float in [-1.0, 1.0]:
			var wheel: MeshInstance3D = _cyl(root, 0.28, 0.28, 0.2, INK, Vector3(x, 0.28, z))
			wheel.rotation.z = PI / 2.0


static func _sun(root: Node3D) -> void:
	_sphere(root, 0.6, Color(1.0, 0.85, 0.25), Vector3.ZERO)
	for i: int in 10:
		var a: float = TAU * i / 10.0
		var ray: MeshInstance3D = _box(
			root, Vector3(0.1, 0.35, 0.06), Color(1.0, 0.75, 0.2), Vector3(sin(a) * 0.85, cos(a) * 0.85, 0)
		)
		ray.rotation.z = -a
	_eyes(root, Vector3(0, 0.1, 0.5), 0.3, 0.08)


static func _cloud(root: Node3D) -> void:
	for p: Vector3 in [Vector3(-0.5, 0, 0), Vector3(0, 0.2, 0), Vector3(0.5, 0, 0), Vector3(0.1, -0.1, 0.2)]:
		_sphere(root, 0.45, WHITE, p)


static func _moon(root: Node3D) -> void:
	_sphere(root, 0.5, Color(0.98, 0.95, 0.75), Vector3.ZERO)
	_sphere(root, 0.42, Color(0.16, 0.2, 0.38), Vector3(0.3, 0.15, 0.25))


static func _balloon(root: Node3D, id: StringName) -> void:
	var c: Vector3 = Vector3(0, 1.9, 0)
	_sphere(root, 0.45, BALLOON_COLORS.get(id, BALLOON_COLORS[&"red"]), c, 1.1)
	_box(root, Vector3(0.02, 1.4, 0.02), Color(0.95, 0.95, 0.95), Vector3(0, 0.75, 0))
	match id:
		&"red":
			for p: Vector3 in [
				Vector3(0.0, 0.2, 0.42),
				Vector3(0.25, -0.1, 0.36),
				Vector3(-0.25, -0.1, 0.36),
				Vector3(0, -0.3, 0.38)
			]:
				_sphere(root, 0.07, WHITE, c + p)
		&"blue":
			for y: float in [-0.18, 0.15]:
				var ring: TorusMesh = TorusMesh.new()
				ring.inner_radius = 0.4
				ring.outer_radius = 0.46
				root.add_child(Blocks.mesh(ring, WHITE, c + Vector3(0, y, 0)))
		&"yellow":
			# A white plus on four sides, so it shows whichever way the balloon turns.
			for yaw: float in [0.0, PI / 2.0, PI, PI * 1.5]:
				var side: Node3D = Node3D.new()
				side.position = c
				side.rotation.y = yaw
				side.add_child(Blocks.box_mesh(Vector3(0.3, 0.09, 0.09), WHITE, Vector3(0, 0, 0.42)))
				side.add_child(Blocks.box_mesh(Vector3(0.09, 0.3, 0.09), WHITE, Vector3(0, 0, 0.42)))
				root.add_child(side)
		&"green":
			# Two upright rings, like the seams of a beach ball.
			for yaw: float in [0.0, PI / 2.0]:
				var ring: TorusMesh = TorusMesh.new()
				ring.inner_radius = 0.43
				ring.outer_radius = 0.48
				var band: MeshInstance3D = Blocks.mesh(ring, WHITE, c)
				band.rotation = Vector3(0, yaw, PI / 2.0)
				band.scale = Vector3(1.2, 1.0, 1.0)
				root.add_child(band)


## A big number tile from the clock: the digit, and the same number of dots under it, so he
## sees how many as well as the symbol.
static func _number(root: Node3D, id: StringName) -> void:
	var n: int = NUMBERS[id]
	_box(root, Vector3(1.0, 1.2, 0.15), Color(0.98, 0.95, 0.86), Vector3(0, 1.0, 0))
	for side: float in [1.0, -1.0]:
		var digit: Label3D = Label3D.new()
		digit.text = str(n)
		digit.font_size = 220
		digit.modulate = Color(0.23, 0.23, 0.22)
		digit.outline_size = 0
		digit.position = Vector3(0, 1.15, 0.08 * side)
		digit.rotation.y = 0.0 if side > 0.0 else PI
		root.add_child(digit)
		for i: int in n:
			var x: float = (i - (n - 1) / 2.0) * 0.17
			_sphere(root, 0.06, Color(0.88, 0.40, 0.25), Vector3(x, 0.58, 0.09 * side))


# --- animals (until their Blender models exist) -----------------------------------------


static func _dog(root: Node3D) -> void:
	var fur: Color = Color(0.78, 0.56, 0.36)
	var body: MeshInstance3D = _sphere(root, 0.4, fur, Vector3(0, 0.55, 0))
	body.scale = Vector3(0.9, 0.85, 1.3)
	_sphere(root, 0.32, fur, Vector3(0, 0.95, 0.45))
	_sphere(root, 0.16, fur.lightened(0.3), Vector3(0, 0.88, 0.72))
	_sphere(root, 0.06, INK, Vector3(0, 0.93, 0.86))
	_eyes(root, Vector3(0, 1.05, 0.7), 0.24, 0.07)
	for side: float in [-1.0, 1.0]:
		var ear: MeshInstance3D = _sphere(root, 0.14, fur.darkened(0.3), Vector3(side * 0.28, 1.05, 0.4))
		ear.scale = Vector3(0.6, 1.4, 0.8)
	for x: float in [-0.2, 0.2]:
		for z: float in [-0.3, 0.3]:
			_cyl(root, 0.08, 0.08, 0.4, fur, Vector3(x, 0.2, z))
	var tail: MeshInstance3D = _cyl(root, 0.04, 0.06, 0.4, fur, Vector3(0, 0.8, -0.55))
	tail.rotation.x = -0.6


static func _cat(root: Node3D) -> void:
	var fur: Color = Color(0.55, 0.55, 0.6)
	var body: MeshInstance3D = _sphere(root, 0.32, fur, Vector3(0, 0.45, 0))
	body.scale = Vector3(0.9, 0.9, 1.25)
	_sphere(root, 0.27, fur, Vector3(0, 0.82, 0.32))
	_eyes(root, Vector3(0, 0.88, 0.54), 0.2, 0.06)
	_sphere(root, 0.04, Color(0.95, 0.6, 0.65), Vector3(0, 0.8, 0.58))
	for side: float in [-1.0, 1.0]:
		var ear: PrismMesh = PrismMesh.new()
		ear.size = Vector3(0.16, 0.2, 0.08)
		root.add_child(Blocks.mesh(ear, fur, Vector3(side * 0.14, 1.08, 0.32)))
		for k: float in [-1.0, 1.0]:
			var whisker: MeshInstance3D = _box(
				root, Vector3(0.25, 0.01, 0.01), WHITE, Vector3(side * 0.22, 0.79 + k * 0.03, 0.56)
			)
			whisker.rotation.z = k * 0.15 * side
	for x: float in [-0.15, 0.15]:
		for z: float in [-0.25, 0.25]:
			_cyl(root, 0.06, 0.06, 0.3, fur, Vector3(x, 0.15, z))
	var tail: MeshInstance3D = _cyl(root, 0.04, 0.05, 0.6, fur, Vector3(0, 0.75, -0.45))
	tail.rotation.x = -0.4


static func _lion(root: Node3D) -> void:
	var fur: Color = Color(0.95, 0.72, 0.3)
	var body: MeshInstance3D = _sphere(root, 0.5, fur, Vector3(0, 0.75, 0))
	body.scale = Vector3(0.9, 0.85, 1.4)
	for i: int in 12:
		var a: float = TAU * i / 12.0
		_sphere(root, 0.2, Color(0.75, 0.42, 0.18), Vector3(cos(a) * 0.38, 1.3 + sin(a) * 0.38, 0.55))
	_sphere(root, 0.36, fur, Vector3(0, 1.3, 0.65))
	_sphere(root, 0.16, fur.lightened(0.3), Vector3(0, 1.18, 0.95))
	_sphere(root, 0.06, INK, Vector3(0, 1.24, 1.08))
	_eyes(root, Vector3(0, 1.4, 0.92), 0.26, 0.07)
	for x: float in [-0.28, 0.28]:
		for z: float in [-0.45, 0.45]:
			_cyl(root, 0.11, 0.11, 0.5, fur, Vector3(x, 0.25, z))
	var tail: MeshInstance3D = _cyl(root, 0.04, 0.05, 0.7, fur, Vector3(0, 0.9, -0.85))
	tail.rotation.x = -0.8
	_sphere(root, 0.1, Color(0.75, 0.42, 0.18), Vector3(0, 1.15, -1.1))


static func _hen(root: Node3D) -> void:
	var body: MeshInstance3D = _sphere(root, 0.35, WHITE, Vector3(0, 0.5, 0))
	body.scale = Vector3(0.9, 1.0, 1.1)
	_sphere(root, 0.2, WHITE, Vector3(0, 0.92, 0.22))
	_sphere(root, 0.08, Color(0.9, 0.2, 0.2), Vector3(0, 1.12, 0.22), 0.14)
	var beak: PrismMesh = PrismMesh.new()
	beak.size = Vector3(0.1, 0.12, 0.1)
	var b: MeshInstance3D = Blocks.mesh(beak, Color(1.0, 0.7, 0.2), Vector3(0, 0.92, 0.45))
	b.rotation.x = PI / 2.0
	root.add_child(b)
	_eyes(root, Vector3(0, 0.98, 0.36), 0.18, 0.045)
	for x: float in [-0.1, 0.1]:
		_cyl(root, 0.03, 0.03, 0.25, Color(1.0, 0.7, 0.2), Vector3(x, 0.12, 0))


static func _bird(root: Node3D) -> void:
	var blue: Color = Color(0.35, 0.6, 0.9)
	_sphere(root, 0.18, blue, Vector3(0, 0.2, 0))
	_sphere(root, 0.12, blue, Vector3(0, 0.36, 0.12))
	_sphere(root, 0.1, Color(1.0, 0.85, 0.6), Vector3(0, 0.15, 0.1))
	var beak: PrismMesh = PrismMesh.new()
	beak.size = Vector3(0.06, 0.08, 0.06)
	var b: MeshInstance3D = Blocks.mesh(beak, Color(1.0, 0.7, 0.2), Vector3(0, 0.36, 0.26))
	b.rotation.x = PI / 2.0
	root.add_child(b)
	_eyes(root, Vector3(0, 0.4, 0.2), 0.12, 0.03)
