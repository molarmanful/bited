class_name WinBDFWarn
extends Window

signal out(ok: bool)

@export var input: TextEdit

@export var btn_ok: Button
@export var btn_cancel: Button


func _ready() -> void:
	hide()

	out.connect(func(_ok: bool): hide())
	close_requested.connect(out.emit.bind(false))
	btn_ok.pressed.connect(out.emit.bind(true))
	btn_cancel.pressed.connect(out.emit.bind(false))


func warn(e: String) -> bool:
	input.text = e
	show()
	btn_cancel.grab_focus()
	return await out
