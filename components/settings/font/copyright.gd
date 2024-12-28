extends LineEdit


func save() -> void:
	StateVars.font.copyright = text


func load() -> void:
	text = StateVars.font.copyright
