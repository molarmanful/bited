extends PanelContainer

@export var window: Window
@export var btn_start: Button
@export var btn_cancel: Button
@export var input_id: IDVal
@export var input_preset: OptionButton


func _ready() -> void:
	window.close_requested.connect(window.hide)
	btn_start.pressed.connect(start)
	btn_cancel.pressed.connect(window.hide)


func start() -> void:
	# TODO: err msg
	# TODO: confirm overwrite of existing font
	if input_id.validate():
		return

	match input_preset.selected:
		1:
			StateVars.font = BFont.unifontex()

	StateVars.font.id = input_id.text
	StateVars.font.init_font()

	window.hide()
	StateVars.start_all()
