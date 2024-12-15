extends SpinFoc

var line := get_line_edit()


func _ready() -> void:
	super()

	line.text_changed.connect(
		func(new: String):
			if new.is_valid_int():
				value = new.to_int()
	)
