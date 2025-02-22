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

var bdfp: BDFParser


func _ready() -> void:
	refresh()

	StateVars.settings.connect(refresh)
	win_finder.query.connect(finder)
	btn_home.pressed.connect(StateVars.all_start)
	btn_save.pressed.connect(save)
	btn_load.pressed.connect(load)
	btn_preview.pressed.connect(
		func():
			preview.window.hide()
			preview.preview()
	)
	btn_settings.pressed.connect(settings.show)
	btn_new_glyph.pressed.connect(new_glyph)
	btn_finder.pressed.connect(win_finder.find)
	btn_braille.pressed.connect(braillegen)


func refresh() -> void:
	font_name.text = StateVars.font.family


func save() -> void:
	var path := StateVars.path()
	if not path:
		dialog_save.popup()
		path = dialog_save.current_file
		if not path:
			return
		StateVars.set_path(path)

	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(StateVars.font.to_bdf())


func load() -> void:
	var path := StateVars.path()
	if not path:
		dialog_load.popup()
		path = dialog_load.current_file
		if not path:
			return
		StateVars.set_path(path)

	bdfp = BDFParser.new()
	txt_bdf_prog.text = ""
	win_bdf_prog.popup.call_deferred()
	await bdfp.from_file(
		path,
		func():
			txt_bdf_prog.text = "Loaded %d chars" % bdfp.glyphs.size()
			await get_tree().process_frame
	)
	win_bdf_prog.hide()

	if bdfp.e:
		win_bdf_err.err.call_deferred(bdfp.e)
		return

	if bdfp.warns:
		win_bdf_warn.warn.call_deferred("\n".join(bdfp.warns))
		var ok: bool = await win_bdf_warn.out
		if not ok:
			return

	bdfp.font.id = StateVars.font.id
	StateVars.load_parsed(bdfp)
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
				where code in (10240, 10241, 10242, 10244, 10248, 10256, 10272, 10304, 10368, 10495)
				order by code
				;"""
				% StateVars.font.id
			)
		)
	)

	var bms := {}
	var qs := StateVars.db_saves.query_result
	if qs.size() < 10:
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
