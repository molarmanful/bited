class_name SpinFoc
extends SpinBox


func _ready() -> void:
	var line := get_line_edit()
	line.text_submitted.connect(func(_new: String): line.release_focus())
