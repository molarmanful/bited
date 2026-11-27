class_name GlyphVal
extends LineVal


func sub(new: String) -> String:
	return RegEx.create_from_string("(?:^\\d+)|[^\\w.]").sub(new, "", true)


func check() -> String:
	if not text:
		return "glyph name cannot be empty"
	StateVars.db.query_with_named_bindings(
		"select name from font_{0} where name = :name;".format([StateVars.font.id]), {name = text}
	)
	if StateVars.db.query_result:
		return "glyph already exists"
	return ""
