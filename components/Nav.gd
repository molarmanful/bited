extends PanelStyler

@export var node_theme: CheckButton


func style() -> void:
	stylebox.set("border_width_top", 1)


func _ready() -> void:
	super()
	node_theme.toggled.connect(ontoggle)


func ontoggle(on: bool) -> void:
	var t := load("res://dark.tres" if on else "res://light.tres")
	StyleVars.set_theme.emit(t)
