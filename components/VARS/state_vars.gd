extends Node
## Global state and signal bus for non-style-related data.

## Emits when settings are saved.
signal settings
## Emits when a glyph is sent to the editor.
signal edit(glyph: Glyph)
## Emits when an action requires the editor to refresh (e.g. glyph deletion hiding grid).
signal edit_refresh
## Emits when an action requires the table to refresh.
signal refresh(gen: Dictionary)

## Current font data.
var font := BFont.sensible()

## Static database for Unicode metadata.
var db_uc := SQLite.new()
## Database for font data.
var db_saves := SQLite.new()


func _ready():
	db_uc.path = "res://assets/uc.db"
	db_uc.read_only = true
	db_uc.open_db()

	db_saves.path = "user://saves.db"
	db_saves.open_db()

	init_font_metas()
	# TODO: prompt for font at startup
	var bdfp = BDFParser.new()
	bdfp.from_file("res://assets/test.bdf")
	font = bdfp.font
	font.init_font()
	var gsv: Array[Dictionary] = []
	gsv.assign(bdfp.glyphs.values())
	font.save_glyphs(gsv)
	bdfp.glyphs.clear()
	# print(font.to_bdf())


## Initializes master table for saved fonts.
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
