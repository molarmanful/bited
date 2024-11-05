extends IDVal


func save() -> void:
	StateVars.font.id = text


func load() -> void:
	text = StateVars.font.id
