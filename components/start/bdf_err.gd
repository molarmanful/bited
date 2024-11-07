class_name BDFErr
extends Window

@export var btn_ok: Button
@export var input: TextEdit


func _ready() -> void:
	hide()

	close_requested.connect(hide)
	btn_ok.pressed.connect(hide)


func err(e: String) -> void:
	input.text = e
	popup()
