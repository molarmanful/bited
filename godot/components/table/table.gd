class_name Table
extends PanelContainer

enum Mode { RANGE, GLYPHS, PAGE }

@export var editor: Editor
@export var charsets: Charsets
@export var node_focus: PanelContainer
@export var node_scroll: ScrollContainer
@export var node_inner: Container
@export var node_header: Label
@export var node_subheader: Label
@export var node_glyphs: Container
@export var node_pad: Container
@export var node_info: Container
@export var node_info_text: Label
@export var node_toolbox: Container
@export var node_placeholder: Container
@export var node_grid_panel: Container
@export var sel: Sel
@export var win_fltr_dw: WinFilterDWidth

@export_group("Buttons")
@export var btn_all: Button
@export var btn_clr: Button
@export var btn_fltr_dw: Button
@export var btn_cut: Button
@export var btn_copy: Button
@export var btn_paste: Button
@export var btn_del: Button

var virt := Virt.new()
var grid: Grid:
	get:
		return editor.grid
var names: Dictionary[String, Glyph]
var thumbs: Dictionary[String, ImageTexture]
var thumb_bitmap := Bitmap.new(StyleVars.thumb_size_pre)
var to_update := false
var hide_tb := false

var viewmode := Mode.GLYPHS
var start := 0
var end := 0

var pick_layer := false:
	set(v):
		pick_layer = v
		sel.update()


func _ready() -> void:
	(
		StateVars
		. db
		. create_table(
			"temp.full",
			{
				row = {data_type = "int", primary_key = true},
				name = {data_type = "text", not_null = true, unique = true},
				code = {data_type = "int", not_null = true},
			}
		)
	)

	StateVars.settings.connect(
		func():
			thumbs.clear()
			to_update = true
	)
	StateVars.table_refresh.connect(
		func():
			thumbs.clear()
			to_update = true
	)
	StateVars.refresh.connect(
		func(gen):
			if gen.name in names:
				names[gen.name].refresh_tex(gen)
	)
	StyleVars.set_thumb.connect(func(): to_update = true)
	resized.connect(onresize)
	virt.refresh.connect(func(): to_update = true)
	node_scroll.get_v_scroll_bar().value_changed.connect(func(value): virt.v_scroll = int(value))
	node_toolbox.resized.connect(
		func():
			await get_tree().process_frame
			update_tb()
	)
	node_grid_panel.visibility_changed.connect(
		func(): node_placeholder.visible = not node_grid_panel.visible
	)

	btn_all.pressed.connect(sel.all)
	btn_clr.pressed.connect(sel.clear)
	btn_fltr_dw.pressed.connect(win_fltr_dw.open)
	btn_cut.pressed.connect(sel.cut)
	btn_copy.pressed.connect(sel.copy)
	btn_paste.pressed.connect(sel.paste)
	btn_del.pressed.connect(sel.delete)


func _process(_delta: float) -> void:
	if to_update:
		to_update = false
		update()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_RIGHT and not e.pressed:
		hide_tb = not hide_tb
		update_tb()


func onresize() -> void:
	virt.w_sizer = int(size.x)
	virt.h_view = get_viewport().size.y


func update() -> void:
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
	(
		StateVars
		. db
		. query(
			(
				"""
				delete from temp.full;
				insert into temp.full
				select
					row_number() over (order by code, name) - 1 as row,
					name, code
				from font_{0};
				select count(*) as count from temp.full;
				"""
				. format([StateVars.font.id])
			)
		)
	)
	viewmode = Mode.GLYPHS
	virt.length = StateVars.db.query_result[0].count
	after_set(top)


func set_page(id: String) -> void:
	(
		StateVars
		. db
		. query(
			(
				"""
				select json_group_array(coalesce(code, -1) order by row) as codes, count(*) as count
				from uc.p_{0}
				;"""
				. format([id])
			)
		)
	)
	set_codes(StateVars.db.query_result[0])


func set_finder(query: String) -> void:
	var fp := FinderParser.from(query)
	(
		StateVars
		. db
		. query_with_bindings(
			(
				"""
				select json_group_array(id order by id) as codes, count(*) as count
				from uc.data where {0};
				"""
				. format([fp.query()])
			),
			fp.binds
		)
	)
	set_codes(StateVars.db.query_result[0])


func set_codes(q: Dictionary) -> void:
	(
		StateVars
		. db
		. query_with_named_bindings(
			"""
			delete from temp.full;
			insert into temp.full
			select key, iif(value >= 0, printf('U+%04X', value), printf('UN-%02X', key)), value
			from json_each(:codes)
			;""",
			{codes = q.codes}
		)
	)
	viewmode = Mode.PAGE
	virt.length = q.count
	after_set()


func after_set(top := true) -> void:
	node_grid_panel.visible = bool(virt.length)
	sel.clear()
	if top:
		node_scroll.scroll_vertical = 0
	virt.v_scroll = node_scroll.scroll_vertical


func gen_glyphs() -> void:
	if not virt.length:
		return

	var i0 := virt.i0
	var i1 := virt.i1

	for i in virt.len_ideal - node_glyphs.get_child_count():
		node_glyphs.add_child(Glyph.create(self))

	var l := node_glyphs.get_child_count()
	for i in l - (i1 - i0):
		node_glyphs.get_child(l - 1 - i).hide()

	if viewmode == Mode.RANGE:
		(
			StateVars
			. db
			. query_with_named_bindings(
				(
					"""
					select name, code, dwidth, is_abs, bb_x, bb_y, off_x, off_y, img
					from font_{0}
					where code between :a and :b
					;"""
					. format([StateVars.font.id])
				),
				{a = start + i0, b = start + i1 - 1}
			)
		)
	else:
		(
			StateVars
			. db
			. query_with_named_bindings(
				(
					"""
					select a.name, a.code, b.dwidth, b.is_abs, b.bb_x, b.bb_y, b.off_x, b.off_y, b.img
					from temp.full as a
					left join font_{0} as b on a.name = b.name
					where a.row between :a and :b
					order by a.row
					;"""
					. format([StateVars.font.id])
				),
				{a = i0, b = i1 - 1}
			)
		)
	var qs := StateVars.db.query_result

	var prev := names.duplicate()
	names.clear()
	for c in range(i0, i1):
		var i := c - i0
		var g := node_glyphs.get_child(i)
		g.nop = false
		if viewmode == Mode.RANGE:
			c += start
			g.data_code = c
		else:
			if viewmode == Mode.PAGE:
				g.nop = qs[i].code < 0
			g.data_name = qs[i].name
			g.data_code = qs[i].code
		g.ind = c
		g.selected = sel.is_selected(g.ind)
		g.edit = (grid.pattern.bitmap.data_name and g.data_name == grid.pattern.bitmap.data_name)
		g.show()
		names[g.data_name] = g

	for q in qs:
		if q.is_abs != null and not (q.name in prev and q.name in thumbs):
			names[q.name].refresh_tex(q)


func update_tb() -> void:
	node_toolbox.scale = Vector2.ONE * int(not hide_tb)
