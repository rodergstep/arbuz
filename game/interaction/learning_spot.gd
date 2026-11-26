class_name LearningSpot
extends Area3D
## An invisible place in the world that teaches a word when the hero or the car passes it
## (a bridge, the river bank, the road). It only asks; LearningDirector decides if now is a good
## moment (not too often, never during a door question).

signal passed(spot: LearningSpot)

@export var word_id: StringName
## Where the picture's camera stands, relative to the spot.
@export var view_offset: Vector3 = Vector3(5, 4, 6)


func setup(id: StringName, radius: float, view: Vector3) -> void:
	word_id = id
	view_offset = view
	collision_layer = 0
	collision_mask = Blocks.LAYER_HERO | Blocks.LAYER_CAR
	var shape: CollisionShape3D = CollisionShape3D.new()
	var cyl: CylinderShape3D = CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = 3.0
	shape.shape = cyl
	shape.position.y = 1.5
	add_child(shape)
	body_entered.connect(func(_body: Node3D) -> void: passed.emit(self))
