class_name WinAddProp
extends Window

signal out(ok: bool)

@export var prop_val: PropVal
@export var btn_ok: Button
@export var btn_cancel: Button


func _ready() -> void:
	hide()

	out.connect(func(_ok: bool): hide())
	close_requested.connect(out.emit.bind(false))
	btn_ok.pressed.connect(emit_ok)
	btn_cancel.pressed.connect(out.emit.bind(false))


func add(p: Dictionary) -> bool:
	prop_val.props = p
	prop_val.f = func(ok: bool):
		if ok:
			btn_ok.show()
		else:
			btn_ok.hide()
	prop_val.text = ""
	popup()
	prop_val.grab_focus()
	return await out


func emit_ok() -> void:
	if prop_val.validate():
		return
	out.emit(true)
