class_name WinBDFErr
extends Window

@export var input: TextEdit

@export var btn_ok: Button


func _ready() -> void:
	hide()

	btn_ok.pressed.connect(hide)


func err(e: String) -> void:
	input.text = e
	popup()
	btn_ok.grab_focus()
