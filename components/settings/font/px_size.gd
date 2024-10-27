extends SpinBox


func save() -> void:
	StateVars.font.px_size = value


func restore() -> void:
	value = StateVars.font.px_size
