class_name WinFinder
extends Window

signal query(q: String)

@export var input: LineEdit
@export var btn_ok: Button


func _ready() -> void:
	hide()

	input.text_changed.connect(query.emit)
	close_requested.connect(hide)
	btn_ok.pressed.connect(hide)


func find() -> void:
	show()
	input.grab_focus()
