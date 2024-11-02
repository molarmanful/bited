extends SpinBox


func save() -> void:
	StateVars.font.desc = value


func load() -> void:
	value = StateVars.font.desc
