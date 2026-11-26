class_name Scenery
extends RefCounted
## Helpers that dress a town: many copies of a model as one MultiMesh (a few draw calls for a
## whole field or row), props with a collision box, and the far backdrop (hills and fields
## beyond the edge, so the world never ends at a bare horizon).


## Many copies of a model, one MultiMesh (one draw call per colour, whatever the count).
static func scatter(
	model_name: String, spots: Array[Transform3D], sway_colors: Array[Color] = [], sway: float = 0.06
) -> MultiMeshInstance3D:
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = ModelPainter.merged_mesh(model_name, sway_colors, sway)
	mm.instance_count = spots.size()
	for i: int in spots.size():
		mm.set_instance_transform(i, spots[i])
	var inst: MultiMeshInstance3D = MultiMeshInstance3D.new()
	inst.multimesh = mm
	return inst


## A transform at pos, turned yaw degrees, scaled.
static func at(pos: Vector3, yaw_deg: float = 0.0, scale_by: float = 1.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)).scaled(Vector3.ONE * scale_by), pos)


## Spots on a grid inside rect (x/z), with a little random jitter, turn and size.
static func field(rect: Rect2, step: float, seed_value: int, jitter: float = 0.3) -> Array[Transform3D]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var spots: Array[Transform3D] = []
	var x: float = rect.position.x
	while x <= rect.end.x:
		var z: float = rect.position.y
		while z <= rect.end.y:
			var p: Vector3 = Vector3(
				x + rng.randf_range(-jitter, jitter), 0, z + rng.randf_range(-jitter, jitter)
			)
			spots.append(at(p, rng.randf_range(0, 360), rng.randf_range(0.85, 1.15)))
			z += step
		x += step
	return spots


## `count` random spots inside rect (x/z) where blocked(Vector2) is false.
static func loose(rect: Rect2, count: int, blocked: Callable, seed_value: int) -> Array[Transform3D]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var spots: Array[Transform3D] = []
	var tries: int = 0
	while spots.size() < count and tries < count * 6:
		tries += 1
		var p: Vector2 = Vector2(
			rng.randf_range(rect.position.x, rect.end.x), rng.randf_range(rect.position.y, rect.end.y)
		)
		if not blocked.call(p):
			spots.append(at(Vector3(p.x, 0, p.y), rng.randf_range(0, 360), rng.randf_range(0.8, 1.2)))
	return spots


## A model placed with an invisible collision box (trunk, wall) in the navigation region.
static func solid(
	nav: Node3D,
	parent: Node3D,
	model_name: String,
	pos: Vector3,
	yaw_deg: float,
	box: Vector3,
	scale_by: float = 1.0,
	sway_colors: Array[Color] = []
) -> void:
	Blocks.hidden_solid(nav, pos + Vector3(0, box.y / 2.0, 0), box)
	parent.add_child(Blocks.prop(model_name, pos, yaw_deg, Vector3.ONE * scale_by, sway_colors))


## Low rolling hills and fields all round, outside the play area (no collision).
static func backdrop(parent: Node3D, hill_colors: Array, field_colors: Array, seed_value: int) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	# Flat fields in a patchwork ring just outside the edge.
	for i: int in 28:
		var a: float = TAU * i / 28.0
		var r: float = rng.randf_range(52.0, 62.0)
		var size: Vector3 = Vector3(rng.randf_range(14, 22), 0.1, rng.randf_range(10, 16))
		var patch: MeshInstance3D = Blocks.mesh(BoxMesh.new(), field_colors[i % field_colors.size()] as Color)
		(patch.mesh as BoxMesh).size = size
		patch.position = Vector3(cos(a) * r, -0.05, sin(a) * r)
		patch.rotation.y = -a
		parent.add_child(patch)
	# Soft hills further out.
	for i: int in 22:
		var a: float = TAU * (i + rng.randf()) / 22.0
		var r: float = rng.randf_range(72.0, 88.0)
		var hill: SphereMesh = SphereMesh.new()
		hill.radius = rng.randf_range(12.0, 20.0)
		hill.height = hill.radius * 2.0
		var inst: MeshInstance3D = Blocks.mesh(hill, hill_colors[i % hill_colors.size()] as Color)
		inst.position = Vector3(cos(a) * r, -hill.radius * rng.randf_range(0.6, 0.75), sin(a) * r)
		inst.scale = Vector3(1.6, 1.0, 1.0)
		inst.rotation.y = -a
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(inst)
	# A big plain ground under everything so no edge shows.
	var ground: CylinderMesh = CylinderMesh.new()
	ground.top_radius = 140.0
	ground.bottom_radius = 140.0
	ground.height = 0.2
	var base: MeshInstance3D = Blocks.mesh(ground, (field_colors[0] as Color).darkened(0.05))
	base.position = Vector3(0, -0.25, 0)
	parent.add_child(base)
