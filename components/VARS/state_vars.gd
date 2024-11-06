extends Node
## Global state and signal bus for non-style-related data.

## Emits when settings are saved.
signal settings
## Emits when a glyph is sent to the editor.
signal edit(glyph: Glyph)
## Emits when an action requires the editor to refresh (e.g. glyph deletion hiding grid).
signal edit_refresh
## Emits when an action requires the table to refresh (e.g. file loading).
signal table_refresh
## Emits when an action requires a specific glyph to refresh.
signal refresh(gen: Dictionary)

## Current font data.
var font := BFont.new()

## Static database for Unicode metadata.
var db_uc := SQLite.new()
## Database for font data.
var db_saves := SQLite.new()

var root: Node
var start: Node
var scn_all: Resource


func _ready():
	db_uc.path = "res://assets/uc.db"
	db_uc.read_only = true
	db_uc.open_db()

	db_saves.path = "user://saves.db"
	db_saves.open_db()

	init_font_metas()

	ResourceLoader.load_threaded_request("res://components/all.tscn")
	root = get_tree().root
	start = root.get_child(root.get_child_count() - 1)

	# var bdfp = BDFParser.new()
	# bdfp.from_file("res://assets/test.bdf")
	# font = bdfp.font
	# font.init_font()
	# var gens: Array[Dictionary]
	# gens.assign(bdfp.glyphs.values())
	# font.save_glyphs(gens)
	# print(font.to_bdf())


## Transitions from "start" to "all."
func start_all() -> void:
	start_all_defer.call_deferred()


func start_all_defer() -> void:
	if not scn_all:
		scn_all = ResourceLoader.load_threaded_get("res://components/all.tscn")

	root.remove_child(start)
	root.add_child(scn_all.instantiate())


## Transitions from "all" to "start."
func all_start() -> void:
	all_start_defer.call_deferred()


func all_start_defer() -> void:
	root.get_child(root.get_child_count() - 1).free()
	root.add_child(start)


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


## Retrieves Unicode metadata.
func get_info(data_name: String, data_code: int, nop = false) -> String:
	if nop:
		return "%s\n(undefined)" % data_name
	if data_code < 0:
		return "%s\n(custom)" % data_name

	(
		StateVars
		. db_uc
		. query_with_bindings(
			"""
			select name, category
			from data
			where id = ?
			;""",
			[data_code]
		)
	)
	var qs := StateVars.db_uc.query_result

	return (
		"U+%s  #%d%s\n%s"
		% [
			data_name,
			data_code,
			"" if qs.is_empty() else "  " + qs[0].category,
			"(undefined)" if qs.is_empty() else qs[0].name,
		]
	)
