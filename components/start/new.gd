extends PanelContainer

@export var window: Window
@export var btn_start: Button
@export var btn_cancel: Button


func _ready() -> void:
	window.close_requested.connect(window.hide)
	btn_start.pressed.connect(start)
	btn_cancel.pressed.connect(window.hide)


func start() -> void:
	pass
