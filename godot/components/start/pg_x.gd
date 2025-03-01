extends VBoxContainer

@export var pg_new: PgNew
@export var pg_db: PgDB
@export var pg_bdf: PgBDF

@export var btn_new: Button
@export var btn_db: Button
@export var btn_bdf: Button


func _ready() -> void:
	show()

	btn_new.pressed.connect(
		func():
			hide()
			pg_new.begin()
	)
	btn_db.pressed.connect(
		func():
			hide()
			pg_db.begin()
	)
	btn_bdf.pressed.connect(
		func():
			hide()
			pg_bdf.begin()
	)
