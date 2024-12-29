class_name WinFilterDWidth
extends Window

@export var table: Table

@export var input: SpinBox

@export var btn_is_abs: Button
@export var btn_ok: Button
@export var btn_cancel: Button


func _ready() -> void:
	hide()

	close_requested.connect(hide)

	btn_is_abs.toggled.connect(
		func(on: bool):
			btn_is_abs.tooltip_text = "dwidth mode: %s" % ("dwidth" if on else "offset")

			var d := input.value
			input.prefix = "w:" if on else "o:"
			input.min_value = -StateVars.font.dwidth * int(not on)
			input.value = d + StateVars.font.dwidth * (int(on) * 2 - 1)
	)
	btn_ok.pressed.connect(
		func():
			table.sel.filter_dwidth(input.value, btn_is_abs.button_pressed)
			hide()
	)
	btn_cancel.pressed.connect(hide)

	btn_is_abs.button_pressed = true
	btn_is_abs.button_pressed = false


func open() -> void:
	popup()
	btn_is_abs.button_pressed = true
	btn_is_abs.button_pressed = false
	input.get_line_edit().grab_focus()
