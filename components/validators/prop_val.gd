class_name PropVal
extends LineVal

var props: Dictionary


func sub(new: String) -> String:
	return RegEx.create_from_string("[^\\w]").sub(new.to_upper(), "", true)


func check() -> String:
	if text.is_empty():
		return "name cannot be empty"
	if text in props:
		return "name is reserved"
	if not BFont.is_other_prop(text):
		return "name is already defined"
	return ""
