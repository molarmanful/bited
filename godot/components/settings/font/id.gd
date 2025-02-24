extends IDVal

@export var win_over_warn: WinOverWarn


func save() -> void:
	var old := StateVars.font.id
	if old == text:
		return

	var ok := await win_over_warn.warn(text)
	if not ok:
		return

	StateVars.font.id = text
	StateVars.rename_font(old, text)


func load() -> void:
	text = StateVars.font.id
