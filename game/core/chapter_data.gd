class_name ChapterData
extends Resource
## A chapter as data: an ordered list of steps. Adding a chapter never touches engine code.
## Contract: docs/contracts/content-resources.md.

@export var id: StringName
@export var steps: Array[QuestStep] = []
## When true the chapter starts again after the last step (the greybox practice loop).
@export var loop: bool = false
@export var loop_line: String = ""
@export var loop_delay: float = 6.0
## Played after this one ends (res:// path), e.g. the prologue leads into the practice loop.
@export var next_chapter: String = ""
## Remembered in the save when finished ("" = not remembered).
@export var done_key: String = ""
