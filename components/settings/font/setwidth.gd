extends LineEdit


func save() -> void:
	StateVars.font.setwidth = text


func restore() -> void:
	text = StateVars.font.setwidth
