class_name LineVal
extends LineEdit

var f := func(_ok: bool): pass


func _ready() -> void:
	text_changed.connect(validate)


func sub(new: String) -> String:
	return new


func check() -> String:
	return ""


func validate(new := text) -> String:
	var old_len := text.length()
	var old_caret := caret_column
	text = sub(new)
	caret_column = old_caret + text.length() - old_len

	var err := check()
	if err:
		tooltip_text = err
		theme_type_variation = "LineEditErr"
		f.call(false)
		return err

	tooltip_text = ""
	theme_type_variation = ""
	f.call(true)
	return ""
