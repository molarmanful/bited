extends PanelContainer

@export var node_inner: Container
@export var node_glyphs: Container
@export var node_pad: Container
@export var virt: Virt


func _ready() -> void:
	resized.connect(func(): virt.w_sizer.Value = size.x ; virt.h_view.Value = get_viewport().size.y)
	virt.size_table.subscribe(func(sz: Vector2i): node_inner.custom_minimum_size = sz).dispose_with(
		self
	)

	virt.pad_top.subscribe(func(v: int): node_pad.custom_minimum_size.y = v).dispose_with(self)

	(
		GDRx
		. combine_latest([virt.i0, virt.i1])
		. subscribe(func(i: Tuple): gen_glyphs(i.first, i.second))
		. dispose_with(self)
	)


func _process(_delta: float) -> void:
	onscroll()


func onscroll():
	var cur := -int(get_global_transform_with_canvas().get_origin().y)
	if virt.v_scroll.Value != cur:
		virt.v_scroll.Value = cur


func gen_glyphs(i0: int, i1: int):
	var len_ideal := i1 - i0
	var len_glyphs := node_glyphs.get_child_count()

	while len_glyphs < len_ideal:
		var glyph := Glyph.create()
		node_glyphs.add_child(glyph)
		len_glyphs += 1

	while len_glyphs > len_ideal:
		node_glyphs.get_child(len_glyphs - 1).hide()
		len_glyphs -= 1

	for c in range(i0, i1):
		var glyph := node_glyphs.get_child(c - i0)
		glyph.data_code = c
		glyph.show()
