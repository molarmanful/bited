class_name NodeBDFWarn
extends PanelContainer

signal close(ok: bool)

@export var window: Window
@export var btn_ok: Button
@export var btn_cancel: Button
@export var input: TextEdit


func _ready() -> void:
	window.hide()

	close.connect(func(_ok: bool): window.hide())
	window.close_requested.connect(close.emit.bind(false))
	btn_ok.pressed.connect(close.emit.bind(true))
	btn_cancel.pressed.connect(close.emit.bind(false))


func warn(e: String) -> void:
	input.text = e
	window.popup()
