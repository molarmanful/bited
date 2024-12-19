class_name SpinFoc
extends SpinBox


func _ready() -> void:
	var line := get_line_edit()
	line.text_changed.connect(
		func(new: String):
			if new.is_valid_int():
				value = new.to_int()
	)
	line.text_submitted.connect(func(_new: String): line.release_focus())
