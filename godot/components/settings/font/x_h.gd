extends SpinFoc


func save() -> void:
	StateVars.font.x_h = int(value)


func load() -> void:
	value = StateVars.font.x_h
