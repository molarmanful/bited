extends OptionButton


func save() -> void:
	StateVars.cfg.set_value("display", "theme", StyleVars.Themes[selected])


func load() -> void:
	selected = StyleVars.Themes.find(
		StateVars.cfg.get_value("display", "theme", "system")
	)
