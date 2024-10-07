extends PanelStyler

@export var node_sizer: Node
@export var virt: Virt


func style() -> void:
	stylebox.set("bg_color", get_theme_color("bord"))
	stylebox.set("border_width_top", 1)
	stylebox.set("border_width_bottom", 1)
	stylebox.set("border_width_left", 1)
	stylebox.set("border_width_right", 1)


func _ready() -> void:
	super()

	node_sizer.resized.connect(func(): virt.w_sizer.Value = node_sizer.size.x)
	virt.size_table.subscribe(func(sz: Vector2i): custom_minimum_size = sz).dispose_with(self)
