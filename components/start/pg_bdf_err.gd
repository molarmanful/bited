class_name PgBDFErr
extends PanelContainer

@export var pg_x: Container

@export var input: TextEdit

@export var btn_ok: Button


func _ready() -> void:
	hide()

	btn_ok.pressed.connect(
		func():
			hide()
			pg_x.show()
	)


func err(e: String) -> void:
	input.text = e
	show()
