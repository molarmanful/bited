extends PanelContainer

@export var btn_new: Button
@export var btn_db: Button
@export var btn_bdf: Button

@export var window_new: Window
@export var window_db: Window
@export var window_bdf: Window


func _ready() -> void:
	btn_new.pressed.connect(window_new.popup)
	btn_db.pressed.connect(window_db.popup)
	btn_bdf.pressed.connect(window_bdf.popup)
