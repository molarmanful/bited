class_name NodeBDFErr
extends PanelContainer

@export var window: Window
@export var btn_ok: Button
@export var input: TextEdit


func _ready() -> void:
	window.hide()

	window.close_requested.connect(window.hide)
	btn_ok.pressed.connect(window.hide)


func err(e: String) -> void:
	input.text = e
	window.popup()
