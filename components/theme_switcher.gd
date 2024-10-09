class_name ThemeSwitcher
extends Node

@export var node: Control


func _ready() -> void:
	StyleVars.set_theme.connect(set_theme)


func set_theme(t: Theme):
	node.theme = t
	StyleVars.apply_theme.emit()
