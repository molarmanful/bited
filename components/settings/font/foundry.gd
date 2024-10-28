extends LineEdit


func save() -> void:
	StateVars.font.foundry = text


func load() -> void:
	text = StateVars.font.foundry
