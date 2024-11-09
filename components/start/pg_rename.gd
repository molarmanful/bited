class_name PgRename
extends PanelContainer

@export var pg_db: PgDB
@export var pg_over_warn: PgOverWarn

@export var input_old_id: LineEdit
@export var input_new_id: IDVal

@export var btn_start: Button
@export var btn_cancel: Button


func _ready() -> void:
	hide()
	btn_start.hide()

	btn_start.pressed.connect(start)
	btn_cancel.pressed.connect(
		func():
			hide()
			pg_db.show()
	)
	input_new_id.text_changed.connect(act_valid)


func begin(id: String) -> void:
	input_old_id.text = id
	focus()


func focus() -> void:
	show()
	input_new_id.grab_focus()


func act_valid(_new := input_new_id.text) -> void:
	if input_new_id.validate():
		btn_start.hide()
		return
	btn_start.show()


func start() -> void:
	if input_new_id.validate():
		return

	hide()
	var old = input_old_id.text
	var new = input_new_id.text
	if old == new:
		pg_db.show()
		return

	var ok := await pg_over_warn.warn(new)
	if not ok:
		focus()
		return

	StateVars.db_saves.query("alter table font_%s rename to font_%s;" % [old, new])
	StateVars.db_saves.query_with_bindings("update fonts set id = ? where id = ?;", [new, old])

	pg_db.begin()
