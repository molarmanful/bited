class_name PgNew
extends PanelContainer

@export var pg_x: Container

@export var input_id: IDVal
@export var input_preset: OptionButton

@export var btn_start: Button
@export var btn_cancel: Button
@export var over_warn: PgOverWarn


func _ready() -> void:
	hide()
	btn_start.hide()

	btn_start.pressed.connect(start)
	btn_cancel.pressed.connect(
		func():
			hide()
			pg_x.show()
	)
	input_id.text_changed.connect(act_valid)


func focus() -> void:
	show()
	input_id.grab_focus()


func act_valid(_new := input_id.text) -> void:
	if input_id.validate():
		btn_start.hide()
		return
	btn_start.show()


func start() -> void:
	if input_id.validate():
		return

	hide()
	var ok := await over_warn.warn(input_id.text)
	if not ok:
		focus()
		return

	match input_preset.selected:
		1:
			StateVars.font = BFont.unifontex()

	StateVars.font.id = input_id.text
	StateVars.font.init_font()

	StateVars.start_all()
