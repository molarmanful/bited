extends OptionButton

var opts = ["R", "I", "O", "RI", "RO"]


func save() -> void:
	StateVars.font.slant = opts[selected]


func restore() -> void:
	selected = opts.find(StateVars.font.slant)
