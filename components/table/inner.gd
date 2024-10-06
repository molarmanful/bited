extends PanelStyler

@export var node_sizer: Node


func style() -> void:
	stylebox.set("bg_color", get_theme_color("bord"))
	stylebox.set("border_width_top", 1)
	stylebox.set("border_width_bottom", 1)
	stylebox.set("border_width_left", 1)
	stylebox.set("border_width_right", 1)


func _ready() -> void:
	super()
	node_sizer.resized.connect(func(): Virt.w_sizer.Value = node_sizer.size.x)
	Virt.w_table.subscribe(func(w: int): custom_minimum_size.x = w)
