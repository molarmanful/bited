extends OptionButton


func _ready() -> void:
	for t in StyleVars.THEMES:
		add_item(t)


func save() -> void:
	StateVars.cfg.set_value("display", "theme", StyleVars.THEMES[selected])


func load() -> void:
	selected = maxi(0, StyleVars.THEMES.find(StateVars.cfg.get_value("display", "theme", "system")))
