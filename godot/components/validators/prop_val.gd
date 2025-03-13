class_name PropVal
extends LineVal

var props: Dictionary


func sub(new: String) -> String:
	var und := RegEx.create_from_string("\\s").sub(new.to_upper(), "_", true)
	return RegEx.create_from_string("\\W").sub(und, "", true)


func check() -> String:
	if not text:
		return "name cannot be empty"
	if text in props:
		return "name is reserved"
	if not BFontR.is_other_prop(text):
		return "name is already defined"
	return ""
