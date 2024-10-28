extends OptionButton

var opts = ["M", "P", "C"]


func save() -> void:
	StateVars.font.spacing = opts[selected]


func load() -> void:
	selected = opts.find(StateVars.font.spacing)
