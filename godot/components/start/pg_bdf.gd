class_name PgBDF
extends PanelContainer

@export var pg_x: Container
@export var pg_bdf_prog: PgBDFProg
@export var pg_bdf_err: PgBDFErr
@export var pg_bdf_warn: PgBDFWarn
@export var over_warn: PgOverWarn

@export var dialog_file: FileDialog
@export var input_path: LineEdit
@export var input_id: IDVal
@export var input_w: SpinBox

@export var btn_start: Button
@export var btn_cancel: Button

var font: BFont


func _ready() -> void:
	btn_start.hide()

	btn_start.pressed.connect(start)
	btn_cancel.pressed.connect(
		func():
			hide()
			pg_x.show()
	)
	dialog_file.file_selected.connect(file_sel)
	dialog_file.canceled.connect(
		func():
			hide.call_deferred()
			pg_x.show.call_deferred()
	)
	input_id.text_changed.connect(act_valid)


func begin() -> void:
	dialog_file.popup()


func file_sel(path: String) -> void:
	font = BFont.new()
	await get_tree().process_frame
	hide()
	pg_bdf_prog.show()
	await get_tree().process_frame
	var err := font.from_file(path)
	pg_bdf_prog.hide()

	if err:
		pg_bdf_err.err.call_deferred(err)
		return

	if font.warns:
		hide.call_deferred()
		pg_bdf_warn.warn.call_deferred("\n".join(font.warns))
		var ok: bool = await pg_bdf_warn.out
		if not ok:
			pg_x.show()
			return

	input_id.text = ""
	show()
	input_id.grab_focus()
	input_path.text = path
	input_path.caret_column = input_path.text.length()
	input_w.value = font.dwidth


func act_valid(_new := input_id.text) -> void:
	if input_id.validate() or not dialog_file.current_file:
		btn_start.hide()
		return
	btn_start.show()


func start() -> void:
	if input_id.validate() or not dialog_file.current_file:
		return

	hide()
	var ok := await over_warn.warn(input_id.text)
	if not ok:
		show()
		return

	font.id = input_id.text
	font.bb.x = input_w.value
	printt("FONT", font.id)
	StateVars.db_locals.query_with_bindings(
		"delete from paths where id = ?", [font.id]
	)
	StateVars.load_parsed(font)
	StateVars.start_all()
