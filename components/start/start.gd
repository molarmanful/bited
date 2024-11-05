extends CenterContainer

@export var btn_new: Button
@export var btn_db: Button
@export var btn_bdf: Button

@export var window_new: Window
@export var window_db: Window
@export var window_bdf: Window


func _ready() -> void:
	window_new.hide()
	# window_db.hide()
	# window_bdf.hide()

	btn_new.pressed.connect(act_new)
	btn_db.pressed.connect(act_db)
	btn_bdf.pressed.connect(act_bdf)


func act_new() -> void:
	window_new.show()


func act_db() -> void:
	pass


func act_bdf() -> void:
	pass
