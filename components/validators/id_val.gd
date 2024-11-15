class_name IDVal
extends LineVal


func _ready() -> void:
	text_changed.connect(validate)


func sub(new: String) -> String:
	return RegEx.create_from_string("[^\\w]").sub(new, "", true)


func check() -> String:
	if text.is_empty():
		return "id cannot be empty"
	return ""
