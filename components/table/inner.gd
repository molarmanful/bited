extends PanelStyler

@export var virt: Virt


func style() -> void:
	stylebox.set("bg_color", get_theme_color("bord"))
	stylebox.set("border_width_top", 1)
	stylebox.set("border_width_bottom", 1)
	stylebox.set("border_width_left", 1)
	stylebox.set("border_width_right", 1)
