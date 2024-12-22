class_name WinNewGlyph
extends Window

signal out(ok: bool)

@export var input: GlyphVal

@export var btn_ok: Button
@export var btn_cancel: Button


func _ready() -> void:
	hide()
	btn_ok.hide()

	input.text_changed.connect(func(_new: String):
		if input.check():
			btn_ok.hide()
			return
		btn_ok.show()
	)
	out.connect(func(_ok: bool): hide())
	btn_ok.pressed.connect(out.emit.bind(true))
	btn_cancel.pressed.connect(out.emit.bind(false))


func new_glyph() -> bool:
	show()
	input.grab_focus()
	return await out
