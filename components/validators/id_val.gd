class_name IDVal
extends LineVal


func _ready() -> void:
	text_changed.connect(validate)


func sub(new: String) -> String:
	var und := RegEx.create_from_string("\\s").sub(new, "_", true)
	return RegEx.create_from_string("\\W").sub(und, "", true)


func check() -> String:
	if text.is_empty():
		return "id cannot be empty"
	return ""
