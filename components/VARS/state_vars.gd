extends Node

signal edit(glyph: Glyph)
signal edit_refresh
signal refresh(gen: Dictionary)

var font := BFont.new()

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


class BFont:
	var id := "new_font"
	var foundry := "bited"
	var family := "new font"
	var weight := "Medium"
	var slant := "R"
	var setwidth := "Normal"
	var add_style := ""
	var px_size := 16
	var pt_size := 150
	var resolution := Vector2i(75, 75)
	var spacing := "P"
	var avg_w := 8
	var ch_reg := "ISO10646"
	var ch_enc := "1"
	var bb := Vector2i(8, 16)
	var bb_off := Vector2i(0, -2)
	var metricsset := 0
	var dwidth := Vector2i(8, 0)
	var dwidth1 := Vector2i(16, 0)
	var vvector := Vector2i(4, 14)
	var cap_h := 9
	var x_h := 7
	var asc := 14
	var desc := 2
	var props := {}

	var size_calc: Vector2i:
		get:
			return Vector2i(dwidth.x, px_size)

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
					avg_w * 10,
					ch_reg,
					ch_enc,
				]
			)
