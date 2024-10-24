extends PanelContainer

@export var font_name: Label
@export var settings: Window
@export var btn_settings: Button


func _ready() -> void:
	font_name.text = StateVars.font.family

	btn_settings.pressed.connect(settings.popup)
