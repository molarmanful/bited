extends Node

signal settings
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
	# TODO: prompt for font at startup
	font.init_font()
	print(font.to_bdf())


func init_font_metas() -> void:
	(
		db_saves
		. create_table(
			"fonts",
			{
				id = {data_type = "text", not_null = true, primary_key = true, unique = true},
				data = {data_type = "blob", not_null = true},
			}
		)
	)
