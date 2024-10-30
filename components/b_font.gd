class_name BFont
extends RefCounted

var id := "new_font"
var foundry := "bited"
var family := "new font"
var weight := "Medium"
var slant := "R"
var setwidth := "Normal"
var add_style := ""
var px_size: int:
	get:
		return bb.y
var pt_size: int:
	get:
		return px_size * 72 / resolution.y * 10
var resolution := Vector2i(75, 75)
var spacing := "P"
var ch_reg := "ISO10646"
var ch_enc := "1"
var bb := Vector2i(8, 16)
var bb_off := Vector2i(0, -2)
var metricsset := 0
var dwidth := 8
var dwidth1 := 16
var vvector: Vector2i:
	get:
		return Vector2i(bb.x / 2, bb.y + bb_off.y)
var cap_h := 9
var x_h := 7
var asc: int:
	get:
		return bb.y - desc
var desc: int:
	get:
		return -bb_off.y
var props := {}

var size_calc: Vector2i:
	get:
		return Vector2i(dwidth, bb.y)

var center: Vector2i:
	get:
		return size_calc * Vector2i(1, -1) / 2


func init_font() -> void:
	save_font(true)
	(
		StateVars
		. db_saves
		. create_table(
			"font_" + id,
			{
				name = {data_type = "text", not_null = true, primary_key = true, unique = true},
				code = {data_type = "int", not_null = true},
				dwidth = {data_type = "int", not_null = true},
				dwidth1 = {data_type = "int"},
				off_x = {data_type = "int", not_null = true},
				off_y = {data_type = "int", not_null = true},
				img = {data_type = "blob"},
			}
		)
	)
	load_font()


func save_font(ignore = false) -> void:
	StateVars.db_saves.query_with_bindings(
		"insert or %s into fonts (id, data) values (?, ?)" % ("ignore" if ignore else "replace"),
		[id, var_to_bytes(to_dict())]
	)


func load_font() -> void:
	var qs := StateVars.db_saves.select_rows("fonts", "id = " + JSON.stringify(id), ["data"])
	if qs.is_empty():
		return
	from_dict(bytes_to_var(qs[0].data))


func to_bdf() -> String:
	var res: Array[String] = [
		"STARTFONT 2.2",
		"FONT %s" % xlfd(),
		"SIZE %d %d %d" % [pt_size / 10, resolution.x, resolution.y],
		"FONTBOUNDINGBOX %d %d %d %d" % [bb.x, bb.y, bb_off.x, bb_off.y],
		"METRICSSET %d" % metricsset,
	]

	if metricsset % 2 == 0:
		res.append_array(["SWIDTH %d 0" % swidth(dwidth), "DWIDTH %d 0" % dwidth])
	if metricsset > 0:
		res.append_array(["SWIDTH1 %d 0" % swidth(dwidth1), "DWIDTH1 %d 0" % dwidth1])

	res.append_array(to_bdf_properties())
	res.append_array(to_bdf_chars())

	res.push_back("ENDFONT")
	return "\n".join(res)


func to_bdf_properties() -> Array[String]:
	var res: Array[String] = [
		"FOUNDRY %s" % foundry,
		"FAMILY_NAME %s" % family,
		"WEIGHT_NAME %s" % weight,
		"SLANT %s" % slant,
		"SETWIDTH_NAME %s" % setwidth,
		"ADD_STYLE_NAME %s" % add_style,
		"PIXEL_SIZE %d" % px_size,
		"POINT_SIZE %d" % pt_size,
		"RESOLUTION_X %d" % resolution.x,
		"RESOLUTION_Y %d" % resolution.y,
		"SPACING %s" % spacing,
		"AVERAGE_WIDTH %d" % avg_w(),
		"CHARSET_REGISTRY %s" % ch_reg,
		"CHARSET_ENCODING %s" % ch_enc,
		"FONT_ASCENT %d" % asc,
		"FONT_DESCENT %d" % desc,
		"CAP_HEIGHT %d" % cap_h,
		"X_HEIGHT %d" % x_h,
	]

	for k in props:
		res.append("%s %s" % [k.to_upper(), props[k]])

	res.push_front("START_PROPERTIES %d" % res.size())
	res.push_back("END_PROPERTIES")
	return res


func to_bdf_chars() -> Array[String]:
	var res: Array[String] = []

	(
		StateVars
		. db_saves
		. query(
			(
				"""
				select name, code, dwidth, dwidth1, off_x, off_y, img
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
		var img := Image.create_empty(1, 1, false, Image.FORMAT_LA8)
		var sz := Vector2i.ZERO
		if q.img:
			img.load_png_from_buffer(q.img)
			sz = img.get_size()

		res.append_array(
			[
				"STARTCHAR %s%s" % ["" if q.code < 0 else "U+", q.name],
				"ENCODING %d" % q.code,
				"BBX %d %d %d %d" % [sz.x, sz.y, q.off_x, q.off_y]
			]
		)

		if metricsset % 2 == 0:
			res.append_array(["SWIDTH %d 0" % swidth(q.dwidth), "DWIDTH %d 0" % q.dwidth])
		if metricsset > 0:
			res.append_array(["SWIDTH1 %d 0" % swidth(q.dwidth1), "DWIDTH1 %d 0" % q.dwidth1])

		res.push_back("BITMAP")
		res.append_array(Util.bits_to_hexes(Util.alpha_to_bits(img), img.get_width()))
		res.push_back("ENDCHAR")

	return res


func to_dict() -> Dictionary:
	return {
		id = id,
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
		bb_off = bb_off,
		metricsset = metricsset,
		dwidth = dwidth,
		dwidth1 = dwidth1,
		cap_h = cap_h,
		x_h = x_h,
		props = props,
	}


func from_dict(d: Dictionary) -> void:
	id = d.id
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
	bb_off = d.bb_off
	metricsset = d.metricsset
	dwidth = d.dwidth
	dwidth1 = d.dwidth1
	cap_h = d.cap_h
	x_h = d.x_h
	props = d.props


func xlfd() -> String:
	return (
		"-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s"
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
		"font_" + id, "", ["cast(avg(dwidth) * 10 as int) as avg"]
	)
	if qs.is_empty():
		return 0
	return qs[0].avg


func swidth(dw: int) -> int:
	return dw * 72000 / (pt_size / 10 * resolution.x)
