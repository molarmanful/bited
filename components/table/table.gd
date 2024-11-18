class_name Table
extends PanelContainer

enum Mode { RANGE, GLYPHS, SBCS }

@export var node_focus: PanelContainer
@export var node_scroll: ScrollContainer
@export var node_inner: Container
@export var node_header: Label
@export var node_subheader: Label
@export var node_glyphs: Container
@export var node_pad: Container
@export var node_info: Container
@export var node_info_text: Label
@export var node_placeholder: Container
@export var node_grid_panel: Container
@export var virt: Virt
@export var sel: Sel

@export_group("Buttons")
@export var btn_all: Button
@export var btn_cut: Button
@export var btn_copy: Button
@export var btn_paste: Button
@export var btn_del: Button

var names := {}
var thumbs := {}
var debounced := false
var to_update := false

var viewmode := Mode.GLYPHS
var start := 0
var end := 0
var sbcs := PackedInt32Array()


func _ready() -> void:
	sel.table = self
	(
		StateVars
		. db_saves
		. create_table(
			"temp.full",
			{
				row = {data_type = "int", not_null = true, primary_key = true, unique = true},
				name = {data_type = "text", not_null = true, unique = true},
				code = {data_type = "int", not_null = true},
			}
		)
	)

	StateVars.table_refresh.connect(func(): to_update = true)
	StateVars.refresh.connect(refresh_tex)
	resized.connect(onresize)
	virt.refresh.connect(func(): to_update = true)

	btn_all.pressed.connect(sel.all)
	btn_cut.pressed.connect(sel.cut)
	btn_copy.pressed.connect(sel.copy)
	btn_paste.pressed.connect(sel.paste)
	btn_del.pressed.connect(sel.delete)


func _process(_delta: float) -> void:
	onscroll()
	update()


func onresize() -> void:
	virt.w_sizer = int(size.x)
	virt.h_view = get_viewport().size.y


func onscroll() -> void:
	# if debounced:
	# 	return

	var cur = -int(get_global_transform_with_canvas().get_origin().y)
	if virt.v_scroll != cur:
		virt.v_scroll = cur

	# debounced = true
	# get_tree().create_timer(.1).timeout.connect(func(): debounced = false)


func update() -> void:
	if not to_update:
		return
	to_update = false

	node_inner.custom_minimum_size = virt.size_table
	node_pad.custom_minimum_size.y = virt.pad_top
	gen_glyphs()


func reset_full() -> void:
	match viewmode:
		Mode.GLYPHS:
			set_glyphs(false)


func set_range(a: int, b: int) -> void:
	start = a
	end = b
	viewmode = Mode.RANGE
	virt.length = end - start
	after_set()


func set_glyphs(top := true) -> void:
	StateVars.db_saves.delete_rows("temp.full", "")
	(
		StateVars
		. db_saves
		. query(
			(
				"""
				insert into temp.full
				select
					row_number() over (order by code, name) - 1 as row,
					name, code
				from font_%s
				;"""
				% StateVars.font.id
			)
		)
	)
	viewmode = Mode.GLYPHS
	virt.length = (
		StateVars.db_saves.select_rows("temp.full", "", ["count(row) as count"])[0].count
	)
	after_set(top)


func set_sbcs(ch: PackedInt32Array) -> void:
	sbcs = ch
	StateVars.db_saves.delete_rows("temp.full", "")
	StateVars.db_saves.query("begin transaction;")

	for i in 256:
		StateVars.db_saves.insert_row(
			"temp.full",
			{row = i, name = "%04X" % ch[i] if ch[i] >= 0 else "UN-%02X" % i, code = ch[i]}
		)

	StateVars.db_saves.query("commit;")

	viewmode = Mode.SBCS
	virt.length = 256
	after_set()


func after_set(top := true) -> void:
	if virt.length:
		node_placeholder.hide()
		node_grid_panel.show()
	else:
		node_grid_panel.hide()
		node_placeholder.show()
	sel.clear()
	if top:
		node_scroll.set_v_scroll(0)
	virt.v_scroll = node_scroll.get_v_scroll()


func gen_glyphs() -> void:
	if not virt.length:
		return

	var len_glyphs := node_glyphs.get_child_count()
	var i0 := virt.i0
	var i1 := virt.i1

	while len_glyphs < virt.len_ideal:
		node_glyphs.add_child(Glyph.create(self))
		len_glyphs += 1

	while len_glyphs > i1 - i0:
		node_glyphs.get_child(len_glyphs - 1).hide()
		len_glyphs -= 1

	var qs: Array[Dictionary]
	if viewmode != Mode.RANGE:
		(
			StateVars
			. db_saves
			. query_with_bindings(
				"""
				select row, name, code
				from temp.full
				where row between ? and ?
				order by row
				;""",
				[i0, i1 - 1]
			)
		)
		qs.assign(StateVars.db_saves.query_result)

	names.clear()
	var i := 0
	for c in range(i0, i1):
		var g := node_glyphs.get_child(i)
		g.nop = false
		if viewmode == Mode.RANGE:
			c += start
			g.data_code = c
		else:
			if viewmode == Mode.SBCS:
				g.nop = qs[i].code < 0
			g.data_name = qs[i].name
			g.data_code = qs[i].code
		g.ind = c
		g.show()
		names[g.data_name] = g
		i += 1

	var gs: Array[Glyph]
	gs.assign(names.values())
	update_glyphs(gs)
	sel.refresh()


func update_glyphs(gs: Array[Glyph]) -> void:
	var qs := PackedStringArray()
	qs.resize(gs.size())
	qs.fill("?")

	StateVars.db_saves.query_with_bindings(
		(
			"""
				select name, code, dwidth, bb_x, bb_y, off_x, off_y, img
				from font_%s
				where name in (%s)
				;"""
			% [StateVars.font.id, ",".join(qs)]
		),
		gs.map(func(g: Glyph): return g.data_name)
	)

	for gen in StateVars.db_saves.query_result:
		refresh_tex(gen)


func refresh_tex(gen: Dictionary) -> void:
	if gen.name not in names:
		return
	names[gen.name].refresh_tex(gen)
