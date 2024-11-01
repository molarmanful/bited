class_name Table
extends PanelContainer

@export var node_wrap: MarginContainer
@export var node_inner: Container
@export var node_glyphs: Container
@export var node_pad: Container
@export var node_info: Container
@export var node_info_text: Label
@export var virt: Virt
@export var sel: Sel

# TODO: consider lru-ing
var vglyphs := {}
var thumbs := {}
var debounced := false
var to_update := false


func _ready() -> void:
	sel.table = self

	resized.connect(onresize)
	node_info.resized.connect(
		func(): node_wrap.add_theme_constant_override("margin_bottom", 32 + int(node_info.size.y))
	)
	virt.refresh.connect(func(): to_update = true)
	StateVars.refresh.connect(refresh_tex)


func _process(_delta: float) -> void:
	onscroll()
	update()


func _input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_text_delete") or e.is_action_pressed("ui_text_backspace"):
		sel.delete()


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
	gen_glyphs_range(virt.i0, virt.i1)


# TODO: account for def-glyphs filter
func gen_glyphs_range(i0: int, i1: int) -> void:
	var len_glyphs := node_glyphs.get_child_count()

	while len_glyphs < virt.len_ideal:
		var glyph := Glyph.create(self)
		node_glyphs.add_child(glyph)
		len_glyphs += 1

	var len_i := i1 - i0
	while len_glyphs > len_i:
		node_glyphs.get_child(len_glyphs - 1).hide()
		len_glyphs -= 1

	vglyphs.clear()
	for c in range(i0, i1):
		var g := node_glyphs.get_child(c - i0)
		g.ind = c
		g.data_code = c
		g.show()
		vglyphs[g.data_name] = g

	var gs: Array[Glyph]
	gs.assign(vglyphs.values())
	update_imgs(gs)
	sel.refresh()


func update_imgs(gs: Array[Glyph]) -> void:
	var qs: Array[String] = []
	qs.resize(gs.size())
	qs.fill("?")

	var suc := (
		StateVars
		. db_saves
		. query_with_bindings(
			(
				"""
				select name, code, bb_x, bb_y, off_x, off_y, img
				from font_%s
				where name in (%s)
				;"""
				% [StateVars.font.id, ",".join(qs)]
			),
			gs.map(func(g: Glyph): return g.data_name)
		)
	)
	if not suc:
		return

	for gen in StateVars.db_saves.query_result:
		refresh_tex(gen)


func refresh_tex(gen: Dictionary) -> void:
	if gen.name not in vglyphs:
		return
	vglyphs[gen.name].refresh_tex(gen)
