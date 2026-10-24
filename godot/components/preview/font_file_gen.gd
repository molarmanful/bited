class_name FontFileGen
extends FontFile

var queried: Dictionary[int, bool]


func _init() -> void:
	allow_system_fallback = false
	antialiasing = TextServer.FONT_ANTIALIASING_NONE
	fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	fixed_size = StateVars.font.px_size
	set_cache_ascent(0, 0, StateVars.font.asc)
	set_cache_descent(0, 0, StateVars.font.desc)


func load_str(text: String) -> bool:
	var codes: Array[int] = []
	for uc in text.to_utf32_buffer().to_int32_array():
		if uc not in queried:
			queried[uc] = true
			codes.push_back(uc)
	if not codes:
		return false

	var s := PackedStringArray()
	s.resize(codes.size())
	s.fill("?")

	(
		StateVars
		. db_saves
		. query_with_bindings(
			(
				"""
				select code, dwidth, is_abs, bb_x, bb_y, off_x, off_y, img
				from font_%s
				where code in (%s)
				"""
				% [StateVars.font.id, ",".join(s)]
			),
			codes
		)
	)

	add_glyphs(StateVars.db_saves.query_result)
	return true


func add_glyphs(gens: Array[Dictionary]) -> void:
	for gen in gens:
		if gen.code < 0:
			continue

		set_glyph_advance(
			0, 0, gen.code, Vector2(StateVars.font.dwidth * int(not gen.is_abs) + gen.dwidth, 0)
		)

		var idx := -1
		if gen.img:
			var bb := Vector2i(gen.bb_x, gen.bb_y)
			idx = get_glyph_texture_idx(0, Vector2i.ZERO, gen.code)
			if idx < 0:
				idx = get_texture_count(0, Vector2i.ZERO)
			set_texture_image(
				0, Vector2i.ZERO, idx, BitGlyph.create_from_bytes(bb, gen.img).to_image()
			)
			set_glyph_uv_rect(0, Vector2i.ZERO, gen.code, Rect2(Vector2.ZERO, bb))
			set_glyph_size(0, Vector2i.ZERO, gen.code, bb)
			set_glyph_offset(0, Vector2i.ZERO, gen.code, Vector2(gen.off_x, -gen.bb_y - gen.off_y))
		set_glyph_texture_idx(0, Vector2i.ZERO, gen.code, idx)

	emit_changed()
