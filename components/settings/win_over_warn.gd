class_name WinOverWarn
extends Window

signal out(ok: bool)

@export var btn_ok: Button
@export var btn_nvm: Button
@export var label: Label


func _ready() -> void:
	hide()

	out.connect(func(_ok: bool): hide())
	close_requested.connect(out.emit.bind(false))
	btn_ok.pressed.connect(out.emit.bind(true))
	btn_nvm.pressed.connect(out.emit.bind(false))


func warn(id: String) -> bool:
	if not StateVars.has_font(id):
		return true

	label.text = (
		"Font with ID '%s' already exists in the database. Overwrite?" % id
	)
	show()
	btn_nvm.grab_focus()
	return await out
