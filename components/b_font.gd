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
		return abs(bb_off.y)
var props := {}

var size_calc: Vector2i:
	get:
		return Vector2i(dwidth, bb.y)

var center: Vector2i:
	get:
		return size_calc * Vector2i(1, -1) / 2

var xlfd: String:
	get:
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
				avg_w() * 10,
				ch_reg,
				ch_enc,
			]
		)


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


func avg_w() -> int:
	var qs := StateVars.db_saves.select_rows("font_" + id, "", ["avg(dwidth) as avg"])
	if qs.is_empty():
		return 0
	return qs[0].avg
