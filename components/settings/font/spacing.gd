extends OptionButton

var opts = ["M", "P", "C"]


func save() -> void:
	StateVars.font.spacing = opts[selected]


func restore() -> void:
	selected = opts.find(StateVars.font.spacing)
