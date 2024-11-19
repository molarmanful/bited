class_name XLFDVal
extends LineVal


func sub(new: String) -> String:
	return RegEx.create_from_string("-").sub(new, "", true)
