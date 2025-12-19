extends OptionButton


func _ready() -> void:
	for t in StyleVars.Themes:
		add_item(t)


func save() -> void:
	StateVars.cfg.set_value("display", "theme", StyleVars.Themes[selected])


func load() -> void:
	selected = maxi(
		0,
		StyleVars.Themes.find(
			StateVars.cfg.get_value("display", "theme", "system")
		)
	)
