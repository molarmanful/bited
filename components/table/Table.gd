extends PanelContainer

@export var node_inner: Container
@export var node_glyphs: Container
@export var node_pad: Container
@export var virt: Virt

var debounced = false
var to_update = false


func _ready() -> void:
	resized.connect(onresize)
	virt.refresh.connect(func(): to_update = true)


func _process(_delta: float) -> void:
	onscroll()
	update()


func onresize() -> void:
	virt.w_sizer = int(size.x)
	virt.h_view = get_viewport().size.y


func onscroll() -> void:
	if debounced:
		return

	var cur := -int(get_global_transform_with_canvas().get_origin().y)
	if virt.v_scroll == cur:
		return
	virt.v_scroll = cur

	# debounced = true
	# get_tree().create_timer(.1).timeout.connect(func(): debounced = false)


func update() -> void:
	if not to_update:
		return
	to_update = false

	node_inner.custom_minimum_size = virt.size_table
	node_pad.custom_minimum_size.y = virt.pad_top
	gen_glyphs(virt.i0, virt.i1)


func gen_glyphs(i0: int, i1: int) -> void:
	var len_glyphs := node_glyphs.get_child_count()

	while len_glyphs < virt.len_ideal:
		var glyph := Glyph.create()
		node_glyphs.add_child(glyph)
		len_glyphs += 1

	var len_i := i1 - i0
	while len_glyphs > len_i:
		node_glyphs.get_child(len_glyphs - 1).hide()
		len_glyphs -= 1

	for c in range(i0, i1):
		var glyph := node_glyphs.get_child(c - i0)
		glyph.data_code = c
		glyph.show()
