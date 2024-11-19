extends XLFDVal


func save() -> void:
	StateVars.font.weight = text


func load() -> void:
	text = StateVars.font.weight
