class_name PgDelWarn
extends PanelContainer

signal out(ok: bool)

@export var label: Label

@export var btn_ok: Button
@export var btn_back: Button


func _ready() -> void:
	hide()

	out.connect(func(_ok: bool): hide())
	btn_ok.pressed.connect(out.emit.bind(true))
	btn_back.pressed.connect(out.emit.bind(false))


func warn(id: String) -> bool:
	label.text = "You are about to delete the font at ID '%s'. Continue?" % id
	show()
	btn_back.grab_focus()
	return await out
