extends SpinBox


func save() -> void:
	StateVars.font.px_size = value


func load() -> void:
	value = StateVars.font.px_size
