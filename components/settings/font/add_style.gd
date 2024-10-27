extends LineEdit


func save() -> void:
	StateVars.font.add_style = text


func restore() -> void:
	text = StateVars.font.add_style
