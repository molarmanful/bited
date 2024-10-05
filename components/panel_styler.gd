class_name PanelStyler
extends PanelContainer

@onready var stylebox := get_theme_stylebox("panel").duplicate()


func _ready() -> void:
	apply()


func apply() -> void:
	style()
	add_theme_stylebox_override("panel", stylebox)


func style() -> void:
	pass
