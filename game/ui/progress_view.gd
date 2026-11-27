class_name ProgressView
extends CanvasLayer
## The parent's progress view (roadmap step 21), opened from the parent screen (behind the
## ParentGate, so it's parents only; text is fine here, in Ukrainian). For every word he has met:
## how often he heard it, how often he said it back (the microphone heard him), and how he did
## when a door asked it. Words to practise (any wrong answer, or never answered right) come first.

signal closed

var _list: GridContainer
var _summary: Label


func _ready() -> void:
	layer = 31
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bg: ColorRect = ColorRect.new()
	bg.color = UiTokens.BG_PAPER
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	column.add_child(_label("Прогрес: слова", UiTokens.SIZE_SUBTITLE))
	_summary = _label("", UiTokens.SIZE_BODY)
	column.add_child(_summary)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	_list = GridContainer.new()
	_list.columns = 5
	_list.add_theme_constant_override("h_separation", 40)
	_list.add_theme_constant_override("v_separation", 6)
	scroll.add_child(_list)
	var back: Button = Button.new()
	back.text = "Назад"
	back.custom_minimum_size = Vector2(240, 80)
	back.add_theme_font_size_override("font_size", UiTokens.SIZE_BODY)
	back.pressed.connect(close)
	column.add_child(back)
	visible = false


func open() -> void:
	_fill()
	visible = true


func close() -> void:
	visible = false
	closed.emit()


func _fill() -> void:
	for child: Node in _list.get_children():
		child.queue_free()
	var rows: Array[Dictionary] = []
	for key: String in SaveSystem.words:
		var s: Dictionary = LearningTracker.stats(StringName(key))
		var entry: WordEntry = WordDB.get_word(StringName(key))
		if entry == null or int(s["heard"]) == 0:
			continue
		s["id"] = key
		s["en"] = entry.en
		s["uk"] = entry.uk
		s["practise"] = int(s["wrong"]) > 0 or (int(s["right"]) == 0 and int(s["said"]) == 0)
		rows.append(s)
	rows.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			if a["practise"] != b["practise"]:
				return a["practise"]
			return int(a["heard"]) > int(b["heard"])
	)
	var said: int = rows.filter(func(r: Dictionary) -> bool: return int(r["said"]) > 0).size()
	var practise: int = rows.filter(func(r: Dictionary) -> bool: return r["practise"]).size()
	_summary.text = "Слів зустрів: %d   Сказав сам: %d   Варто повторити: %d" % [rows.size(), said, practise]
	for title: String in ["Слово", "Українською", "Чув", "Сказав", "Двері ✓ / ✗"]:
		_list.add_child(_label(title, UiTokens.SIZE_BODY, UiTokens.ACCENT_SKY))
	for r: Dictionary in rows:
		var colour: Color = Color(0.75, 0.35, 0.2) if r["practise"] else UiTokens.INK
		_list.add_child(_label(String(r["en"]), UiTokens.SIZE_BODY, colour))
		_list.add_child(_label(String(r["uk"]), UiTokens.SIZE_BODY))
		_list.add_child(_label(str(r["heard"]), UiTokens.SIZE_BODY))
		_list.add_child(_label(str(r["said"]), UiTokens.SIZE_BODY))
		_list.add_child(_label("%d / %d" % [r["right"], r["wrong"]], UiTokens.SIZE_BODY))


func _label(text: String, size: int, colour: Color = UiTokens.INK) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	return l
