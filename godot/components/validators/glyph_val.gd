class_name GlyphVal
extends LineVal


func sub(new: String) -> String:
	return RegEx.create_from_string("(?:^\\d+)|[^\\w.]").sub(new, "", true)


func check() -> String:
	if not text:
		return "glyph name cannot be empty"
	StateVars.db_saves.query_with_bindings(
		"select name from font_%s where name = ?;" % StateVars.font.id, [text]
	)
	if StateVars.db_saves.query_result:
		return "glyph already exists"
	return ""
