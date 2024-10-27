extends LineEdit


func save() -> void:
	StateVars.font.foundry = text


func restore() -> void:
	text = StateVars.font.foundry
