class_name PgOverWarn
extends PanelContainer

signal out(ok: bool)

@export var btn_ok: Button
@export var btn_back: Button
@export var label: Label


func _ready() -> void:
	hide()

	out.connect(func(_ok: bool): hide())
	btn_ok.pressed.connect(out.emit.bind(true))
	btn_back.pressed.connect(out.emit.bind(false))


func warn(id: String) -> bool:
	StateVars.db_saves.query_with_bindings("select 1 from fonts where id = ?", [id])
	if StateVars.db_saves.query_result.is_empty():
		return true

	label.text = "Font with ID '%s' already exists in the database. Overwrite?" % id
	show()
	return await out
