extends LineEdit


func save() -> void:
	StateVars.font.family = text


func restore() -> void:
	text = StateVars.font.family
