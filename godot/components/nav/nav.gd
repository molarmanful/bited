extends PanelContainer

@export var table: Table
@export var preview: Preview
@export var font_name: Label
@export var settings: Window
@export var dialog_save: FileDialog
@export var dialog_load: FileDialog

@export var win_bdf_prog: Window
@export var txt_bdf_prog: Label
@export var win_bdf_err: WinBDFErr
@export var win_bdf_warn: WinBDFWarn
@export var win_new_glyph: WinNewGlyph
@export var win_finder: WinFinder

@export var btn_home: Button
@export var btn_save: Button
@export var btn_load: Button
@export var btn_preview: Button
@export var btn_settings: Button
@export var btn_new_glyph: Button
@export var btn_finder: Button
@export var btn_braille: Button

var font: BFont


func _ready() -> void:
	refresh()

	StateVars.settings.connect(refresh)
	win_finder.query.connect(finder)
	btn_home.pressed.connect(StateVars.all_start)
	btn_save.pressed.connect(save_font_pre)
	dialog_save.file_selected.connect(save_font)
	btn_load.pressed.connect(load_font_pre)
	dialog_load.file_selected.connect(load_font)
	btn_preview.pressed.connect(
		func():
			preview.window.hide()
			preview.preview()
	)
	btn_settings.pressed.connect(settings.popup)
	btn_new_glyph.pressed.connect(new_glyph)
	btn_finder.pressed.connect(win_finder.find)
	btn_braille.pressed.connect(braillegen)


func refresh() -> void:
	font_name.text = StateVars.font.family


func save_font_pre():
	var path := StateVars.path()
	if not path:
		dialog_save.popup()
		return
	save_font(path)


func save_font(path: String) -> void:
	if not path:
		return
	StateVars.set_path(path)

	var bdf := FileAccess.open(path, FileAccess.WRITE)
	var glyphs := FileAccess.open(
		path.trim_suffix(".bdf") + ".glyphs.toml", FileAccess.WRITE
	)
	bdf.store_string(StateVars.font.to_bdf())
	glyphs.store_string(StateVars.font.to_glyphs_toml())


func load_font_pre():
	var path := StateVars.path()
	if not path:
		dialog_load.popup()
		return
	load_font(path)


func load_font(path: String) -> void:
	if not path:
		return
	StateVars.set_path(path)

	font = BFont.new()
	await get_tree().process_frame
	win_bdf_prog.popup()
	await get_tree().process_frame
	var err := font.read_file(path)
	win_bdf_prog.hide()

	if err:
		win_bdf_err.err.call_deferred(font.e)
		return

	if font.warns:
		win_bdf_warn.warn.call_deferred("\n".join(font.warns))
		var ok: bool = await win_bdf_warn.out
		if not ok:
			return

	font.id = StateVars.font.id
	StateVars.load_parsed(font)
	StateVars.start_all()


func new_glyph() -> void:
	var ok := await win_new_glyph.new_glyph()
	if not ok:
		return

	var gname := win_new_glyph.input.text
	StateVars.db_saves.insert_row("font_" + StateVars.font.id, {name = gname})
	table.reset_full()
	table.to_update = true
	StateVars.edit.emit(gname, -1)


func finder(q: String) -> void:
	table.node_header.text = "FINDER"
	table.node_subheader.text = q
	table.charsets.deselect_all()
	table.set_finder(q)


func braillegen() -> void:
	(
		StateVars
		. db_saves
		. query(
			(
				"""
				select name, code, dwidth, is_abs, bb_x, bb_y, off_x, off_y, img
				from font_%s
				where code in (10240, 10241, 10242, 10244, 10248, 10256, 10272, 10304, 10368)
				order by code
				;"""
				% StateVars.font.id
			)
		)
	)

	var bms: Dictionary[int, Bitmap]
	var qs := StateVars.db_saves.query_result
	if qs.size() < 9:
		# TODO: warn abt missing
		return
	for q in StateVars.db_saves.query_result:
		var bm := Bitmap.new(StyleVars.grid_size_cor)
		bm.update_cells(q)
		bms[q.code - 10240] = bm

	for c in 256:
		var bm := Bitmap.new(
			StyleVars.grid_size_cor,
			Util.img_copy(bms[0].cells),
			10240 + c,
			"%04X" % (10240 + c)
		)
		var i := 1
		while c > 0:
			if c & 1:
				bm.cells.blend_rect(
					bms[i].cells,
					Rect2i(Vector2i.ZERO, bm.cells.get_size()),
					Vector2i.ZERO
				)
			c = c >> 1
			i = i << 1
		bm.save()
