extends PanelStyler

@export var node_resizer: Container


func style() -> void:
	stylebox.set("bg_color", get_theme_color("bord"))
	stylebox.set("border_width_top", 1)
	stylebox.set("border_width_bottom", 1)
	stylebox.set("border_width_left", 1)
	stylebox.set("border_width_right", 1)


func _ready() -> void:
	super()
	node_resizer.resized.connect(resize_width)


func resize_width() -> void:
	custom_minimum_size.x = int(node_resizer.size.x / 33 - 1) * 33 + 1
