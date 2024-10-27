extends LineEdit


func save() -> void:
	StateVars.font.weight = text


func restore() -> void:
	text = StateVars.font.weight
