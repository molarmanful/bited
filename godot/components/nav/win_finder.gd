class_name WinFinder
extends Window

signal query(q: String)

@export var input: LineEdit
@export var btn_ok: Button

var timer_input := Timer.new()


func _init() -> void:
	timer_input.one_shot = true
	add_child(timer_input)


func _ready() -> void:
	hide()

	input.text_changed.connect(
		func(_q):
			timer_input.stop()
			timer_input.start(0.4)
	)
	input.text_submitted.connect(
		func():
			timer_input.stop()
			timer_input.timeout.emit()
	)
	timer_input.timeout.connect(func(): query.emit(input.text))
	close_requested.connect(hide)
	btn_ok.pressed.connect(hide)


func find() -> void:
	show()
	input.grab_focus()
