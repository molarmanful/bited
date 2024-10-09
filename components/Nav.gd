extends PanelContainer

@export var node_theme: CheckButton


func _ready() -> void:
	node_theme.toggled.connect(ontoggle)


func ontoggle(on: bool) -> void:
	var t := load("res://dark.tres" if on else "res://light.tres")
	StyleVars.set_theme.emit(t)
