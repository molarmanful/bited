class_name WinFilterDWidth
extends Window

@export var table: Table

@export var input: SpinBox

@export var btn_ok: Button
@export var btn_cancel: Button


func _ready() -> void:
	hide()

	close_requested.connect(hide)
	btn_ok.pressed.connect(
		func():
			table.sel.filter_dwidth(input.value)
			hide()
	)
	btn_cancel.pressed.connect(hide)


func open() -> void:
	popup()
	input.get_line_edit().grab_focus()
