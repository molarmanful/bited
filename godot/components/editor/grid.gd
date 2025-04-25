class_name Grid
extends PanelContainer

@export var editor: Editor
@export var node_wrapper: Container
@export var node_cells: TextureRect
@export var node_sels: TextureRect
@export var node_view_lines: SubViewport
@export var node_lines: GridLines
@export var node_placeholder: Label

@export_group("Inputs")
@export var input_dwidth: SpinBox

@export_group("Button Groups")
@export var tools_group: ButtonGroup
@export var cmode_group: ButtonGroup

@export_group("Buttons")
@export var btn_is_abs: Button
@export var btn_prev_glyph: Button
@export var btn_next_glyph: Button
@export var btn_prev_uc: Button
@export var btn_next_uc: Button
@export var btn_undo: Button
@export var btn_redo: Button
@export var btn_flip_x: Button
@export var btn_flip_y: Button
@export var btn_rot_ccw: Button
@export var btn_rot_cw: Button
@export var btn_left: Button
@export var btn_down: Button
@export var btn_up: Button
@export var btn_right: Button
@export var btn_grid_clr: Button
@export var btn_selmode: Button
@export var btn_overwrite: Button
@export var btn_stamp: Button

var dim_grid: int:
	get:
		return StyleVars.grid_size_cor
var w_cell: int:
	get:
		return StyleVars.grid_px_size_cor
var w_grid: int:
	get:
		return dim_grid * w_cell
var size_grid: Vector2i:
	get:
		return Vector2i(w_grid, w_grid)

var to_update_cells := false
var pressed := false
var is_sel := false:
	set(s):
		is_sel = s
		btn_selmode.set_pressed_no_signal(s)
		node_sels.visible = s
		tool_sel = tool_sel

var cells := Image.create_empty(dim_grid, dim_grid, false, Image.FORMAT_LA8)
var tex_cells := ImageTexture.create_from_image(cells)
var sels := Image.create_empty(dim_grid, dim_grid, false, Image.FORMAT_LA8)
var tex_sels := ImageTexture.create_from_image(sels)

var table: Table
var toolman := Tool.new(self)
var tool_sel := "pen":
	set(t):
		tool_sel = t
		toolman.tools[tool_sel].pre()
var bitmap := Bitmap.new(dim_grid, cells)
var undoman := UndoRedo.new()

var layer_node: TextureRect:
	get:
		return node_sels if is_sel else node_cells
var layer_img: Image:
	get:
		return sels if is_sel else cells
var layer_tex: ImageTexture:
	get:
		return tex_sels if is_sel else tex_cells


func _ready() -> void:
	table = editor.table
	refresh()

	StateVars.settings.connect(refresh)
	StateVars.edit.connect(start_edit)
	StateVars.edit_refresh.connect(refresh)
	StyleVars.set_grid.connect(refresh.bind(true))

	theme_changed.connect(update_cells)

	input_dwidth.value_changed.connect(func(_new: float): dwidth())

	tools_group.pressed.connect(func(btn: BaseButton): tool_sel = btn.name)
	cmode_group.pressed.connect(
		func(btn: BaseButton): toolman.cmode = Tool.CMode[btn.name]
	)

	btn_is_abs.toggled.connect(is_abs)
	btn_prev_glyph.pressed.connect(off_glyph.bind(-1))
	btn_next_glyph.pressed.connect(off_glyph.bind(1))
	btn_prev_uc.pressed.connect(off_uc.bind(-1))
	btn_next_uc.pressed.connect(off_uc.bind(1))
	btn_undo.pressed.connect(undoman.undo)
	btn_redo.pressed.connect(undoman.redo)
	btn_flip_x.pressed.connect(flip_x)
	btn_flip_y.pressed.connect(flip_y)
	btn_rot_ccw.pressed.connect(rot_ccw)
	btn_rot_cw.pressed.connect(rot_cw)
	btn_left.pressed.connect(translate.bind(Vector2i.LEFT))
	btn_down.pressed.connect(translate.bind(Vector2i.DOWN))
	btn_up.pressed.connect(translate.bind(Vector2i.UP))
	btn_right.pressed.connect(translate.bind(Vector2i.RIGHT))
	btn_grid_clr.pressed.connect(clear)
	btn_selmode.toggled.connect(func(on: bool): is_sel = on)
	btn_overwrite.pressed.connect(overwrite)
	btn_stamp.pressed.connect(stamp)


func _process(_delta: float) -> void:
	toolman.tools[tool_sel].handle()
	update_cells()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		tt_line()
		return
	if e is not InputEventMouseButton:
		return
	if (
		e is InputEventMouseButton
		and [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_UP].has(e.button_index)
	):
		return

	pressed = e.pressed
	toolman.tools[tool_sel].handle(
		Tool.State.START if pressed else Tool.State.END
	)


func start_edit(data_name: String, data_code: int) -> void:
	undoman.clear_history()
	bitmap.data_name = data_name
	bitmap.data_code = data_code
	bitmap.dwidth = 0
	bitmap.is_abs = false
	bitmap.clear_cells()
	bitmap.save(false)
	table.to_update = true
	refresh(true)


func refresh(hard := false) -> void:
	if hard:
		bitmap.dim = dim_grid
		cells.copy_from(
			Image.create_empty(dim_grid, dim_grid, false, Image.FORMAT_LA8)
		)
		tex_cells.set_image(cells)

	bitmap.load()

	if not bitmap.data_name:
		editor.node_info.hide()
		node_wrapper.hide()
		node_placeholder.show()
		return
	editor.node_info.show()
	node_placeholder.hide()
	node_wrapper.show()

	btn_is_abs.set_pressed_no_signal(bitmap.is_abs)
	btn_is_abs.tooltip_text = (
		"dwidth mode: %s" % ("dwidth" if bitmap.is_abs else "offset")
	)

	input_dwidth.allow_lesser = true
	input_dwidth.prefix = "w:" if bitmap.is_abs else "o:"
	input_dwidth.min_value = -StateVars.font.dwidth * int(not bitmap.is_abs)
	input_dwidth.set_value_no_signal(bitmap.dwidth)
	input_dwidth.allow_lesser = false

	editor.node_info_text.text = StateVars.get_info(
		bitmap.data_name, bitmap.data_code
	)
	node_cells.texture = tex_cells
	node_sels.texture = tex_sels
	to_update_cells = true
	update_grid()


func update_grid() -> void:
	tooltip_text = ""

	node_cells.custom_minimum_size = size_grid
	node_cells.self_modulate = get_theme_color("fg")

	var c_sel := get_theme_color("sel")
	c_sel.a = 0.69
	node_sels.custom_minimum_size = size_grid
	node_sels.self_modulate = c_sel

	node_view_lines.size = size_grid
	node_lines.queue_redraw()


func update_cells() -> void:
	if not to_update_cells:
		return
	to_update_cells = false

	tex_cells.update(cells)
	tex_sels.update(sels)


func tt_line() -> void:
	tooltip_text = ""
	var pos := get_local_mouse_position()
	var origin := bitmap.origin
	var e := w_cell / 2

	for k in node_lines.lines_h:
		var v: int = node_lines.lines_h[k]
		var n := origin.y - v
		var nw := n * w_cell
		var p := pos.y
		if nw - e <= p and p <= nw + e:
			tooltip_text += (
				"%s%s: %d\n"
				% [
					node_lines.names[k],
					" x" if k == "origin" else "",
					v,
				]
			)

	for k in node_lines.lines_v:
		var v: int = node_lines.lines_v[k]
		var n := origin.x + v
		var nw := n * w_cell
		var p := pos.x
		if nw - e <= p and p <= nw + e:
			tooltip_text += (
				"%s%s: %d\n"
				% [
					node_lines.names[k],
					" y" if k == "origin" else "",
					v,
				]
			)


func off_glyph(off: int) -> void:
	if table.viewmode == Table.Mode.RANGE:
		(
			StateVars
			. db_saves
			. query_with_bindings(
				(
					"""
					select name, code
					from font_{0}
					where (code between ? and ?) and (code {1} ?)
					order by code {2}, name {2}
					limit 1
					;"""
					. format(
						[
							StateVars.font.id,
							"<=" if off < 0 else ">=",
							"desc" if off < 0 else ""
						]
					)
				),
				[table.start, table.end, bitmap.data_code + off]
			)
		)
	else:
		(
			StateVars
			. db_saves
			. query_with_bindings(
				(
					"""
					select o.name, o.code
					from temp.full as o
					join font_%s as i on o.name = i.name
					where o.row %s (
						select row + ?
						from temp.full
						where name = ?
					)
					order by row %s
					limit 1
					;"""
					% [
						StateVars.font.id,
						"<=" if off < 0 else ">=",
						"desc" if off < 0 else ""
					]
				),
				[off, bitmap.data_name]
			)
		)

	var qs := StateVars.db_saves.query_result
	if not qs:
		return
	start_edit(qs[0].name, qs[0].code)


func off_uc(off: int) -> void:
	if table.viewmode == Table.Mode.RANGE:
		var code1 := bitmap.data_code + off
		if code1 < table.start or code1 > table.end:
			return
		start_edit("%04X" % code1, code1)

	else:
		match table.viewmode:
			Table.Mode.GLYPHS:
				(
					StateVars
					. db_saves
					. query_with_bindings(
						"""
						select o.name, o.code
						from temp.full as o
						join temp.full as i on o.row = i.row + ?
						where i.name = ?
						;""",
						[off, bitmap.data_name]
					)
				)

			Table.Mode.PAGE:
				(
					StateVars
					. db_saves
					. query_with_bindings(
						(
							"""
							select name, code
							from temp.full
							where code >= 0 and row %s (
								select row + ?
								from temp.full
								where name = ?
							)
							order by row %s
							limit 1
							;"""
							% [
								"<=" if off < 0 else ">=",
								"desc" if off < 0 else ""
							]
						),
						[off, bitmap.data_name]
					)
				)

		var qs := StateVars.db_saves.query_result
		if not qs:
			return
		start_edit(qs[0].name, qs[0].code)


func act_cells(prev: Image) -> void:
	var cs := Util.img_copy(cells)

	undoman.create_action(name)

	undoman.add_undo_method(
		func():
			cells.copy_from(prev)
			bitmap.save()
			to_update_cells = true
	)
	undoman.add_undo_reference(prev)

	undoman.add_do_method(
		func():
			cells.copy_from(cs)
			bitmap.save()
			to_update_cells = true
	)
	undoman.add_do_reference(cs)

	undoman.commit_action(false)


func op(f: Callable, cells_only := false) -> void:
	var prev := Util.img_copy(cells if cells_only else layer_img)
	f.call(prev)
	to_update_cells = true
	if !is_sel:
		act_cells(prev)
		bitmap.save()


func dim_norm(f: Callable) -> void:
	var dx := bitmap.dim - posmod(bitmap.dim - bitmap.dwidth_calc, 2)
	var dy := bitmap.dim - posmod(bitmap.dim - StateVars.font.bb.y, 2)
	layer_img.crop(dx, dy)
	f.call()
	layer_img.crop(bitmap.dim, bitmap.dim)


func flip_x() -> void:
	op(func(_prev: Image): dim_norm(layer_img.flip_x))


func flip_y() -> void:
	op(func(_prev: Image): dim_norm(layer_img.flip_y))


func rot_ccw() -> void:
	op(func(_prev: Image): dim_norm(layer_img.rotate_90.bind(COUNTERCLOCKWISE)))


func rot_cw() -> void:
	op(func(_prev: Image): dim_norm(layer_img.rotate_90.bind(CLOCKWISE)))


func translate(dst: Vector2i) -> void:
	op(
		func(prev: Image):
			bitmap.clear_cells()
			layer_img.blit_rect(
				prev, Rect2i(Vector2i.ZERO, prev.get_size()), dst
			)
	)


func clear() -> void:
	op(func(_prev: Image): layer_img.fill(Color.TRANSPARENT))

func overwrite() -> void:
	op(
		func(_prev: Image):
			var layer_img1 := cells if is_sel else sels
			layer_img1.blit_rect(
				layer_img,
				Rect2i(Vector2i.ZERO, layer_img.get_size()),
				Vector2i.ZERO
			)
			is_sel = !is_sel,
		true
	)
	is_sel = true

func stamp() -> void:
	op(
		func(_prev: Image):
			var layer_img1 := cells if is_sel else sels
			match toolman.cmode:
				Tool.CMode.DEFAULT, Tool.CMode.T:
					Util.img_or(layer_img1, layer_img)
				Tool.CMode.F:
					Util.img_andn(layer_img1, layer_img)
				Tool.CMode.INV:
					Util.img_xor(layer_img1, layer_img)
				Tool.CMode.CELL:
					Util.img_and(layer_img1, layer_img)
			is_sel = !is_sel,
		true
	)
	is_sel = true


func dwidth() -> void:
	var old := bitmap.dwidth
	var new: int = input_dwidth.value
	undoman.create_action("dwidth")
	undoman.add_undo_method(
		func():
			bitmap.dwidth = old
			bitmap.save_dwidth()
			refresh(true)
	)
	undoman.add_do_method(
		func():
			bitmap.dwidth = new
			bitmap.save_dwidth()
			refresh(true)
	)
	undoman.commit_action()


func is_abs(on: bool) -> void:
	undoman.create_action("is_abs")
	undoman.add_undo_method(
		func():
			bitmap.set_is_abs(not on)
			bitmap.save_dwidth()
			refresh()
	)
	undoman.add_do_method(
		func():
			bitmap.set_is_abs(on)
			bitmap.save_dwidth()
			refresh()
	)
	undoman.commit_action()
