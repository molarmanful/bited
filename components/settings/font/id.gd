extends LineEdit


func save() -> void:
	StateVars.font.id = text


func restore() -> void:
	text = StateVars.font.id
