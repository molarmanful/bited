@tool
extends PanelStyler

@onready var sb := get_theme_stylebox("panel").duplicate()

func _ready() -> void:
	style()

func style() -> void:
	stylebox.set("border_width_top", 1)
