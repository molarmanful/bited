class_name IDVal
extends LineVal


func sub(new: String) -> String:
	var und := RegEx.create_from_string("\\s").sub(new.to_lower(), "_", true)
	return RegEx.create_from_string("\\W").sub(und, "", true)


func check() -> String:
	if not text:
		return "id cannot be empty"
	return ""
