class_name Blocks
extends RefCounted
## Greybox building helpers: plain shapes with flat colours. Real art replaces them in Phase 3.

const LAYER_WORLD: int = 1
const LAYER_HERO: int = 2
const LAYER_CAR: int = 4
const LAYER_PICKABLE: int = 8


static func material(color: Color, emission: float = 0.0) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	if emission > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission
	return mat


## A mesh in the painted look (toon shading, coloured shadows, painted gradient).
static func mesh(
	primitive: PrimitiveMesh, color: Color, pos: Vector3 = Vector3.ZERO, sway: float = 0.0
) -> MeshInstance3D:
	primitive.material = PaintedMaterials.make(color, sway)
	var inst: MeshInstance3D = MeshInstance3D.new()
	inst.mesh = primitive
	inst.position = pos
	return inst


## A mesh with a plain StandardMaterial3D, for things that animate their material (markers,
## glows, cards).
static func flat_mesh(primitive: PrimitiveMesh, color: Color, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	primitive.material = material(color)
	var inst: MeshInstance3D = MeshInstance3D.new()
	inst.mesh = primitive
	inst.position = pos
	return inst


static func box_mesh(size: Vector3, color: Color, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	return mesh(box, color, pos)


static func flat_box_mesh(size: Vector3, color: Color, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	return flat_mesh(box, color, pos)


## A solid box the hero and the car collide with; part of the navigation mesh when it is a
## child of the NavigationRegion3D.
static func solid_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.collision_layer = LAYER_WORLD
	body.position = pos
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.add_child(box_mesh(size, color))
	parent.add_child(body)
	return body


static func house(parent: Node3D, pos: Vector3, size: Vector3, wall: Color, roof: Color) -> StaticBody3D:
	var body: StaticBody3D = solid_box(parent, pos + Vector3(0, size.y / 2.0, 0), size, wall)
	var prism: PrismMesh = PrismMesh.new()
	prism.size = Vector3(size.x + 0.6, size.y * 0.6, size.z + 0.6)
	body.add_child(mesh(prism, roof, Vector3(0, size.y / 2.0 + size.y * 0.3, 0)))
	return body


static func label(text: String, height: float, size: int = 64) -> Label3D:
	var l: Label3D = Label3D.new()
	l.text = text
	l.font_size = size
	l.outline_size = 16
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = Vector3(0, height, 0)
	return l
