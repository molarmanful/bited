extends OptionButton


func save() -> void:
	StateVars.cfg.set_value("display", "theme", selected)


func load() -> void:
	selected = StateVars.cfg.get_value("display", "theme", 0)
