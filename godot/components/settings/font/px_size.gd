extends SpinBox


func save() -> void:
	StateVars.font.px_size = int(value)


func load() -> void:
	value = StateVars.font.px_size
