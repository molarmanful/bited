extends Window

@export var btn_start: Button
@export var btn_cancel: Button
@export var over_warn: OverWarn
@export var input_id: IDVal
@export var input_preset: OptionButton


func _ready() -> void:
	btn_start.hide()

	close_requested.connect(hide)
	btn_start.pressed.connect(start)
	btn_cancel.pressed.connect(hide)
	input_id.text_changed.connect(act_valid)


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
		show()
		return

	match input_preset.selected:
		1:
			StateVars.font = BFont.unifontex()

	StateVars.font.id = input_id.text
	StateVars.font.init_font()

	StateVars.start_all()
