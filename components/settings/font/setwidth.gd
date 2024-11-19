extends XLFDVal


func save() -> void:
	StateVars.font.setwidth = text


func load() -> void:
	text = StateVars.font.setwidth
