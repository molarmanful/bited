extends SpinBox


func save() -> void:
	StateVars.font.cap_h = value


func restore() -> void:
	value = StateVars.font.cap_h
