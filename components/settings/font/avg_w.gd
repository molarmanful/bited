extends SpinBox


func save() -> void:
	StateVars.font.avg_w = value


func restore() -> void:
	value = StateVars.font.avg_w
