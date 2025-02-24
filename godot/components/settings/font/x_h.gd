extends SpinFoc


func save() -> void:
	StateVars.font.x_h = value


func load() -> void:
	value = StateVars.font.x_h
