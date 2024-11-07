extends PanelContainer

@export var window: Window
@export var btn_start: Button
@export var btn_cancel: Button
@export var over_warn: NodeOverWarn
@export var input_id: IDVal
@export var input_preset: OptionButton


func _ready() -> void:
	btn_start.hide()

	window.close_requested.connect(window.hide)
	btn_start.pressed.connect(start)
	btn_cancel.pressed.connect(window.hide)
	input_id.text_changed.connect(act_valid)


# TODO: err msg
func act_valid(_new := input_id.text) -> void:
	if input_id.validate():
		btn_start.hide()
		return
	btn_start.show()


# TODO: confirm overwrite of existing font
func start() -> void:
	if input_id.validate():
		return

	var ok := await over_warn.warn(input_id.text)
	if not ok:
		window.show()
		return

	match input_preset.selected:
		1:
			StateVars.font = BFont.unifontex()

	StateVars.font.id = input_id.text
	StateVars.font.init_font()

	window.hide()
	StateVars.start_all()
