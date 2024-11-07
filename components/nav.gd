extends PanelContainer

@export var font_name: Label
@export var settings: Window
@export var btn_settings: Button


func _ready() -> void:
	refresh()

	btn_settings.pressed.connect(settings.popup)
	StateVars.settings.connect(refresh)

func refresh() -> void:
	font_name.text = StateVars.font.family
