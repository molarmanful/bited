extends PanelContainer

@export var preview: Preview
@export var font_name: Label
@export var settings: Window
@export var dialog_save: FileDialog
@export var dialog_load: FileDialog

@export var win_bdf_prog: Window
@export var txt_bdf_prog: Label
@export var win_bdf_err: WinBDFErr
@export var win_bdf_warn: WinBDFWarn

@export var btn_home: Button
@export var btn_save: Button
@export var btn_load: Button
@export var btn_preview: Button
@export var btn_settings: Button

var bdfp: BDFParser


func _ready() -> void:
	refresh()

	btn_home.pressed.connect(StateVars.all_start)
	btn_save.pressed.connect(save)
	btn_load.pressed.connect(load)
	btn_preview.pressed.connect(
		func():
			preview.window.hide()
			preview.preview()
	)
	btn_settings.pressed.connect(settings.popup)
	StateVars.settings.connect(refresh)


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

	if not bdfp.warns.is_empty():
		win_bdf_warn.warn.call_deferred("\n".join(bdfp.warns))
		var ok: bool = await win_bdf_warn.out
		if not ok:
			return

	bdfp.font.id = StateVars.font.id
	StateVars.load_parsed(bdfp)
	StateVars.start_all()
