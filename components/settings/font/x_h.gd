extends SpinBox


func save() -> void:
	StateVars.font.x_h = value


func restore() -> void:
	value = StateVars.font.x_h
