class_name NodeBDFWarn
extends PanelContainer

signal out(ok: bool)

@export var window: Window
@export var btn_ok: Button
@export var btn_cancel: Button
@export var input: TextEdit


func _ready() -> void:
	window.hide()

	out.connect(func(_ok: bool): window.hide())
	window.close_requested.connect(out.emit.bind(false))
	btn_ok.pressed.connect(out.emit.bind(true))
	btn_cancel.pressed.connect(out.emit.bind(false))


func warn(e: String) -> bool:
	input.text = e
	window.popup()
	return await out
