extends LineEdit


func save() -> void:
	StateVars.font.add_style = text


func load() -> void:
	text = StateVars.font.add_style
