extends SpinFoc


func save() -> void:
	StateVars.font.desc = int(value)


func load() -> void:
	value = StateVars.font.desc
