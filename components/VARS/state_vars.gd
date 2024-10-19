extends Node

signal table
signal edit(g: Glyph)

# TODO: change to class
var font := {
	id = "new_font",
	foundry = "bited",
	family = "new font",
	weight = "Medium",
	slant = "R",
	setwidth = "Normal",
	add_style = "",
	px_size = 16,
	pt_size = 150,
	resolution = Vector2i(75, 75),
	spacing = "P",
	avg_w = 80,
	ch_reg = "ISO10646",
	ch_enc = "1",
	bb = Vector2i(8, 16),
	bb_off = Vector2i(0, -2),
	metricsset = 0,
	dwidth = Vector2i(8, 0),
	dwidth1 = Vector2i(16, 0),
	vvector = Vector2i(4, 14),
	cap_h = 9,
	x_h = 7,
	asc = 14,
	desc = 2,
	props = {}
}

var font_size_calc: Vector2i:
	get:
		return Vector2i(font.dwidth.x, font.px_size)

var font_center: Vector2i:
	get:
		return StateVars.font_size_calc * Vector2i(1, -1) / 2

var font_xlfd: String:
	get:
		return (
			"-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s"
			% [
				font.foundry,
				font.family,
				font.weight,
				font.slant,
				font.setwidth,
				font.add_style,
				font.px_size,
				font.pt_size,
				font.resolution.x,
				font.resolution.y,
				font.spacing,
				font.avg_w,
				font.ch_reg,
				font.ch_enc,
			]
		)

var db_uc := SQLite.new()
var db_saves := SQLite.new()


func _ready():
	db_uc.path = "res://assets/uc.db"
	db_uc.read_only = true
	db_uc.open_db()

	db_saves.path = "user://saves.db"
	db_saves.open_db()

	init_font_metas()
	init_font(font.id)


func init_font_metas() -> bool:
	return (
		db_saves
		. create_table(
			"fonts",
			{
				id = {data_type = "text", not_null = true, primary_key = true, unique = true},
				data = {data_type = "blob", not_null = true},
			}
		)
	)


func init_font(id: String) -> bool:
	db_saves.query_with_bindings(
		"insert or ignore into fonts (id, data) values (?, ?)", [id, var_to_bytes(font)]
	)
	return (
		db_saves
		. create_table(
			"font_" + id,
			{
				name = {data_type = "text", not_null = true, primary_key = true, unique = true},
				code = {data_type = "int", not_null = true},
				dwidth_x = {data_type = "int", not_null = true},
				dwidth_y = {data_type = "int", not_null = true},
				dwidth1_x = {data_type = "int"},
				dwidth1_y = {data_type = "int"},
				vvector_x = {data_type = "int"},
				vvector_y = {data_type = "int"},
				off_x = {data_type = "int", not_null = true},
				off_y = {data_type = "int", not_null = true},
				img = {data_type = "blob"},
			}
		)
	)
