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
@export var win_new_glyph: WinGlyph
@export var win_rename_glyph: WinGlyph
@export var win_finder: WinFinder

@export var btn_home: Button
@export var btn_save: Button
@export var btn_load: Button
@export var btn_preview: Button
@export var btn_settings: Button
@export var btn_new_glyph: Button
@export var btn_rename_glyph: Button
@export var btn_finder: Button
@export var btn_sexify: Button
@export var btn_sepsexify: Button
@export var btn_octify: Button
@export var btn_braille: Button
@export var btn_undo: Button
@export var btn_redo: Button

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
	btn_rename_glyph.pressed.connect(rename_glyph)
	btn_finder.pressed.connect(win_finder.find)
	btn_sexify.pressed.connect(antgen.bind("p_block2x3"))
	btn_sepsexify.pressed.connect(antgen.bind("p_block2x3sep"))
	btn_octify.pressed.connect(antgen.bind("p_block2x4"))
	btn_braille.pressed.connect(antgen.bind("p_block2x4braille"))
	btn_undo.pressed.connect(undo)
	btn_redo.pressed.connect(undo.bind(true))


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
	var glyphs := FileAccess.open(path.trim_suffix(".bdf") + ".glyphs.toml", FileAccess.WRITE)
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
	var ok := await win_new_glyph.prompt()
	if not ok:
		return

	var gname := win_new_glyph.input.text
	StateVars.db.insert_row("font_" + StateVars.font.id, {name = gname})
	table.reset_full()
	table.to_update = true
	StateVars.edit.emit(gname, -1)


func rename_glyph() -> void:
	var old := table.sel.named()
	var ok := await win_rename_glyph.prompt(old)
	if not ok:
		return

	var gname := win_rename_glyph.input.text
	if not (
		StateVars
		. db
		. query_with_named_bindings(
			(
				"""-- sql
				begin;

				update font_{0} set name = :new where name = :old;

				update layers_{0}
				set
					parent = iif(parent = :old, :new, parent),
					child = iif(child = :old, :new, child)
				where
					:old in (parent, child);

				commit;
				"""
				. format([StateVars.font.id])
			),
			{new = gname, old = old}
		)
	):
		StateVars.db.query("rollback;")
		return

	if table.grid.pattern.bitmap.data_name == old:
		table.grid.pattern.bitmap.data_name = gname
	table.grid.refresh()
	table.reset_full()
	table.to_update = true


func finder(q: String) -> void:
	table.node_header.text = "FINDER"
	table.node_subheader.text = q
	table.charsets.deselect_all()
	table.set_finder(q)


func antgen(tbl: String) -> void:
	(
		StateVars
		. db
		. query(
			(
				"""-- sql
				with recursive
					src as (
						select r.row as key, f.name
						from uc.{1}_in as r
						left join font_{0} as f on f.code = r.code
					),
					down(name) as (
						select name from src where name is not null
						union
						select l.child
						from layers_{0} as l
						join down on l.parent = down.name
					),
					miss(m) as (
						select iif(min(key) = 0, -1, coalesce(sum(1 << (key - 1)), 0))
						from src
						where
							name is null
					)
				select
					json_group_array(json_object('row', g.key, 'code', g.code, 'name', g.name)) as gens,
					(select json_group_array(name order by key) from src) as srcs
				from (
					select row as key, code, format('U+%04X', code) as name from uc.{1}
				) as g, miss
				where
					(g.key & (g.key - 1))
					and not (g.key & miss.m)
					and g.name not in down;
				"""
				. format([StateVars.font.id, tbl])
			)
		)
	)
	var q := StateVars.db.query_result[0]
	if q.gens == "[]":
		return

	if not (
		StateVars
		. db
		. query_with_named_bindings(
			(
				"""-- sql
				begin;

				delete from layers_{0}
				where
					parent in (select value ->> 'name' from json_each(:gens));

				insert or replace into font_{0}(name, code, img)
				select value ->> 'name', value ->> 'code', x'' from json_each(:gens);

				insert into layers_{0}(parent, ord, child)
				select g.value ->> 'name', s.key, s.value
				from json_each(:gens) as g
				join json_each(:srcs) as s
					on s.key = 0
					or (((g.value ->> 'row') >> (s.key - 1)) & 1);
				"""
				. format([StateVars.font.id])
			),
			q
		)
	):
		StateVars.db.query("rollback;")
		return

	StateVars.font.flatten_parents(JSON.parse_string(q.srcs))
	StateVars.db.query("commit;")

	StateVars.table_refresh.emit()
	StateVars.edit_refresh.emit()


func undo(redo := false) -> void:
	StateVars.undo(redo)
	StateVars.edit_refresh.emit()
	table.thumbs.clear()
	table.reset_full()
	table.to_update = true
