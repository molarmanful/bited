extends LineEdit


func save() -> void:
	StateVars.font.family = text


func load() -> void:
	text = StateVars.font.family
