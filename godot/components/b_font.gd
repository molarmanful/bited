class_name BFont
extends BFontR
## BDF font abstraction for holding (meta)data.

var id := "new_font"
var px_size: int:
	get:
		return bb.y
var pt_size: int:
	get:
		return px_size * 72 / resolution.y * 10
var dwidth: int:
	get:
		return bb.x
var asc: int:
	get:
		return px_size - desc
var center: Vector2i:
	get:
		return bb * Vector2i(1, -1) / 2


static func creep2() -> BFont:
	var res := BFont.new()
	res.bb = Vector2i(5, 11)
	res.desc = 2
	res.cap_h = 4
	res.x_h = 4
	return res


static func cozette() -> BFont:
	var res := BFont.new()
	res.bb = Vector2i(6, 13)
	res.desc = 3
	res.cap_h = 7
	res.x_h = 5
	return res


static func unifontex() -> BFont:
	var res := BFont.new()
	res.bb = Vector2i(8, 16)
	res.desc = 2
	res.cap_h = 9
	res.x_h = 7
	return res


func init_font(ignore := false) -> void:
	if not ignore:
		StateVars.db_saves.query("drop table if exists font_%s;" % id)
	(
		StateVars
		. db_saves
		. create_table(
			"font_" + id,
			{
				name =
				{
					data_type = "text",
					not_null = true,
					primary_key = true,
					unique = true
				},
				code = {data_type = "int", not_null = true, default = -1},
				dwidth = {data_type = "int", not_null = true, default = 0},
				is_abs = {data_type = "int", not_null = true, default = 0},
				bb_x = {data_type = "int", not_null = true, default = 0},
				bb_y = {data_type = "int", not_null = true, default = 0},
				off_x = {data_type = "int", not_null = true, default = 0},
				off_y = {data_type = "int", not_null = true, default = 0},
				img = {data_type = "blob"},
			}
		)
	)
	save_font(ignore)
	load_font()


func save_font(ignore = false) -> void:
	StateVars.db_saves.query_with_bindings(
		(
			"insert or %s into fonts (id, data) values (?, ?);"
			% ("ignore" if ignore else "replace")
		),
		[id, var_to_bytes(to_dict())]
	)


func load_font() -> void:
	(
		StateVars
		. db_saves
		. query_with_bindings(
			"""
			select data
			from fonts
			where id = ?
			;""",
			[id]
		)
	)
	var qs := StateVars.db_saves.query_result
	if not qs:
		return
	from_dict(bytes_to_var(qs[0].data))


func to_bdf() -> String:
	var fb := fbbx()
	var res := PackedStringArray(
		[
			"STARTFONT 2.1",
			"FONT %s" % xlfd(),
			"SIZE %d %d %d" % [pt_size / 10, resolution.x, resolution.y],
			(
				"FONTBOUNDINGBOX %d %d %d %d"
				% [fb.bb_x, fb.bb_y, fb.off_x, fb.off_y]
			),
		]
	)

	res.append_array(to_bdf_properties())
	res.append_array(to_bdf_chars(fb))

	res.push_back("ENDFONT")
	res.push_back("")
	return "\n".join(res)


func to_bdf_properties() -> PackedStringArray:
	var res: Array[String] = [
		"FOUNDRY %s" % stringify(foundry),
		"FAMILY_NAME %s" % stringify(family),
		"WEIGHT_NAME %s" % stringify(weight),
		"SLANT %s" % stringify(slant),
		"SETWIDTH_NAME %s" % stringify(setwidth),
		"ADD_STYLE_NAME %s" % stringify(add_style),
		"PIXEL_SIZE %d" % px_size,
		"POINT_SIZE %d" % pt_size,
		"RESOLUTION_X %d" % resolution.x,
		"RESOLUTION_Y %d" % resolution.y,
		"SPACING %s" % stringify(spacing),
		"AVERAGE_WIDTH %d" % avg_w(),
		"CHARSET_REGISTRY %s" % stringify(ch_reg),
		"CHARSET_ENCODING %s" % stringify(ch_enc),
		"FONT_ASCENT %d" % asc,
		"FONT_DESCENT %d" % desc,
		"CAP_HEIGHT %d" % cap_h,
		"X_HEIGHT %d" % x_h,
		"COPYRIGHT %s" % stringify(copyright),
		"BITED_DWIDTH %d" % dwidth,
		"BITED_WIDTHS %s" % stringify(width64()),
		"BITED_TABLE_WIDTH %d" % StyleVars.table_width,
		"BITED_TABLE_CELL_SCALE %d" % StyleVars.thumb_px_size,
		"BITED_EDITOR_GRID_SIZE %d" % StyleVars.grid_size,
		"BITED_EDITOR_CELL_SIZE %d" % StyleVars.grid_px_size,
	]

	for k in props:
		if is_other_prop(k):
			res.append("%s %s" % [k.to_upper(), JSON.stringify(props[k])])

	res.push_front("STARTPROPERTIES %d" % res.size())
	res.push_back("ENDPROPERTIES")
	return res


func width64() -> String:
	(
		StateVars
		. db_saves
		. query(
			(
				"""
				select is_abs
				from font_%s
				order by code, name
				;"""
				% id
			)
		)
	)
	var qs := StateVars.db_saves.query_result

	var res := BitMap.new()
	res.create(Vector2i(qs.size(), 1))
	var i := 0
	for q in qs:
		res.set_bit(i, 0, bool(q.is_abs))
		i += 1
	return (
		"%d %s"
		% [
			res.get_size().x,
			Marshalls.raw_to_base64(
				res.data.data.compress(FileAccess.COMPRESSION_GZIP)
			)
		]
	)


func to_bdf_chars(fb: Dictionary) -> PackedStringArray:
	var res := PackedStringArray()

	(
		StateVars
		. db_saves
		. query(
			(
				"""
				select name, code, dwidth, is_abs, bb_x, bb_y, off_x, off_y, img
				from font_%s
				order by code, name
				;"""
				% id
			)
		)
	)
	var qs := StateVars.db_saves.query_result

	res.push_back("CHARS %d" % qs.size())

	for q in qs:
		var dw: int = dwidth * int(not q.is_abs) + q.dwidth
		(
			res
			. append_array(
				[
					"STARTCHAR %s%s" % ["U+" if q.code >= 0 else "", q.name],
					"ENCODING %d" % q.code,
					"SWIDTH %d 0" % swidth(fb.bb_x, dw),
					"DWIDTH %d 0" % dw,
					"BBX %d %d %d %d" % [q.bb_x, q.bb_y, q.off_x, q.off_y],
					"BITMAP",
				]
			)
		)

		if q.img:
			res.append_array(Util.bits_to_hexes(q.img, q.bb_x, q.bb_y))
		res.push_back("ENDCHAR")

	return res


func save_glyphs(gens: Array[Dictionary], over := true) -> void:
	StateVars.db_saves.query("begin transaction;")
	for gen in gens:
		save_glyph(gen, over)
	StateVars.db_saves.query("commit;")
	StateVars.table_refresh.emit()


func save_glyph(gen: Dictionary, over := true) -> void:
	(
		StateVars
		. db_saves
		. query_with_bindings(
			(
				"""
				insert or %s
				into font_%s
				(name, code, dwidth, is_abs, bb_x, bb_y, off_x, off_y, img)
				values
				(?, ?, ?, ?, ?, ?, ?, ?, ?)
				;"""
				% ["replace" if over else "ignore", StateVars.font.id]
			),
			[
				gen.name,
				gen.code,
				gen.dwidth,
				int(gen.is_abs),
				gen.bb_x,
				gen.bb_y,
				gen.off_x,
				gen.off_y,
				gen.img
			]
		)
	)


func to_dict() -> Dictionary:
	return {
		foundry = foundry,
		family = family,
		weight = weight,
		slant = slant,
		setwidth = setwidth,
		add_style = add_style,
		resolution = resolution,
		spacing = spacing,
		ch_reg = ch_reg,
		ch_enc = ch_enc,
		bb = bb,
		desc = desc,
		cap_h = cap_h,
		x_h = x_h,
		copyright = copyright,
		props = props,
		table_width = StyleVars.table_width,
		thumb_px_size = StyleVars.thumb_px_size_cor,
		grid_size = StyleVars.grid_size_cor,
		grid_px_size = StyleVars.grid_px_size_cor,
	}


func from_dict(d: Dictionary) -> void:
	foundry = d.foundry
	family = d.family
	weight = d.weight
	slant = d.slant
	setwidth = d.setwidth
	add_style = d.add_style
	resolution = d.resolution
	spacing = d.spacing
	ch_reg = d.ch_reg
	ch_enc = d.ch_enc
	bb = d.bb
	desc = d.desc
	cap_h = d.cap_h
	x_h = d.x_h
	copyright = d.copyright
	props = d.props
	StyleVars.table_width = d.table_width
	StyleVars.thumb_px_size = d.thumb_px_size
	StyleVars.grid_size = d.grid_size
	StyleVars.grid_px_size = d.grid_px_size


func xlfd() -> String:
	return (
		"-%s-%s-%s-%s-%s-%s-%d-%d-%d-%d-%s-%d-%s-%s"
		% [
			foundry,
			family,
			weight,
			slant,
			setwidth,
			add_style,
			px_size,
			pt_size,
			resolution.x,
			resolution.y,
			spacing,
			avg_w(),
			ch_reg,
			ch_enc,
		]
	)


func avg_w() -> int:
	var qs := StateVars.db_saves.select_rows(
		"font_" + id,
		"",
		["cast(avg(%d * (is_abs = 0) + dwidth) * 10 as int) as avg" % dwidth]
	)
	if not qs:
		return 0
	return qs[0].avg if qs[0].avg else 0


func swidth(max_w: int, dw: int) -> int:
	return dw * 72000 / (resolution.x * max_w)


func fbbx() -> Dictionary:
	var qs := StateVars.db_saves.select_rows(
		"font_" + id,
		"",
		[
			"coalesce(max(bb_x), 0) as bb_x",
			"coalesce(max(bb_y), 0) as bb_y",
			"coalesce(min(off_x), 0) as off_x",
			"coalesce(min(off_y), 0) as off_y",
			"coalesce(max(%d * (is_abs = 0) + dwidth), 0) as dwidth" % dwidth
		]
	)
	return qs[0]


func stringify(s: String) -> String:
	return '"%s"' % s.replace('"', '""')
