class_name PanelStyler
extends PanelContainer

var stylebox: StyleBox


func _ready() -> void:
	apply()
	StyleVars.apply_theme.connect(apply)


func apply() -> void:
	stylebox = get_theme_stylebox("panel").duplicate()
	add_theme_stylebox_override("panel", stylebox)
	style()


func style() -> void:
	pass
