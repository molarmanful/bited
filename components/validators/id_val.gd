class_name IDVal
extends LineEdit


func _ready() -> void:
	text_changed.connect(validate)


func validate(new := text) -> String:
	var r := RegEx.create_from_string("[^\\w]")
	var old_len := text.length()
	var old_caret := caret_column
	text = r.sub(new.to_lower(), "", true)
	caret_column = old_caret + text.length() - old_len

	if text.is_empty():
		var msg := "id cannot be empty"
		tooltip_text = msg
		theme_type_variation = "LineEditErr"
		return msg

	tooltip_text = ""
	theme_type_variation = ""
	return ""
