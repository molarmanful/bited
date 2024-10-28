extends SpinBox


func save() -> void:
	StateVars.font.cap_h = value


func load() -> void:
	value = StateVars.font.cap_h
