class_name QuestStep
extends Resource
## One step of a chapter, as data (ADR-0004). The scene supplies the actors; the step says what
## to do, where, and what Тигриця says (keys in content/voice/lines.csv).

enum Kind { GET_IN_CAR, DRIVE_TO, WALK_TO, OPEN_DOOR }

@export var kind: Kind = Kind.WALK_TO
## Target spots; each visit of the loop uses the next one (DRIVE_TO, WALK_TO).
@export var spots: Array[Vector3] = []
## Said when the step starts (after any open learning card).
@export var start_line: String = ""
## Тигриця's idle hint for this step.
@export var hint_line: String = ""
## Said when he reaches the marker but the step needs one more action (e.g. click the car).
@export var arrive_line: String = ""
