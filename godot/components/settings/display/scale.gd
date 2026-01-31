extends SpinFoc


func save() -> void:
	StateVars.cfg.set_value("display", "scale", value)


func load() -> void:
	value = clampi(get_tree().root.content_scale_factor, 1, 3)
