class_name DelWarn
extends Window

signal out(ok: bool)

@export var btn_ok: Button
@export var btn_back: Button
@export var label: Label


func _ready() -> void:
	hide()

	out.connect(func(_ok: bool): hide())
	close_requested.connect(out.emit.bind(false))
	btn_ok.pressed.connect(out.emit.bind(true))
	btn_back.pressed.connect(out.emit.bind(false))


func warn(id: String) -> bool:
	label.text = "You are about to delete the font at ID '%s'. Continue?" % id
	popup()
	return await out
