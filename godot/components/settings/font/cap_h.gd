extends SpinFoc


func save() -> void:
	StateVars.font.cap_h = int(value)


func load() -> void:
	value = StateVars.font.cap_h
