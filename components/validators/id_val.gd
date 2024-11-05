class_name IDVal
extends LineEdit


func _ready() -> void:
	text_changed.connect(validate)


func validate(new: String) -> String:
	var r := RegEx.create_from_string("[^\\w]")
	var old_len := text.length()
	var old_caret := caret_column
	text = r.sub(new.to_lower(), "", true)
	caret_column = old_caret + text.length() - old_len

	if text.is_empty():
		return "id cannot be empty"
	return ""
