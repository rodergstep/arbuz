class_name QuestStep
extends Resource
## One step of a chapter, as data (ADR-0004). The scene supplies the actors; the step says what
## to do, where, and what Tygrytsa says (keys in content/voice/lines.csv).

## New kinds are appended (saved .tres files store the number).
enum Kind { GET_IN_CAR, DRIVE_TO, WALK_TO, OPEN_DOOR, FIND_OBJECT, TALK_TO, FERRY, COLLECT }

@export var kind: Kind = Kind.WALK_TO
## Target spots; each visit of the loop uses the next one (DRIVE_TO, WALK_TO).
@export var spots: Array[Vector3] = []
## Said when the step starts (after any open learning card).
@export var start_line: String = ""
## Tygrytsa's idle hint for this step.
@export var hint_line: String = ""
## Said when he reaches the marker but the step needs one more action (e.g. click the car).
@export var arrive_line: String = ""
## TALK_TO: which conversation the scene plays (e.g. &"baker_intro").
@export var talk_id: StringName
## COLLECT: the word of the things to find and how many (one at each spot).
@export var word: StringName
@export var count: int = 1
