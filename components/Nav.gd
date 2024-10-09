extends PanelContainer

@export var node_theme: CheckButton
@export var font_name: Label


func _ready() -> void:
	node_theme.toggled.connect(ontoggle)
	font_name.text = StateVars.font.family


func ontoggle(on: bool) -> void:
	var t := load("res://dark.tres" if on else "res://light.tres")
	StyleVars.set_theme.emit(t)
