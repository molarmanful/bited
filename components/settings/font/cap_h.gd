extends SpinFoc


func save() -> void:
	StateVars.font.cap_h = value


func load() -> void:
	value = StateVars.font.cap_h
