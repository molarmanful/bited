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
## Editor settings.
var cfg := ConfigFile.new()

## Static database for Unicode metadata.
var db_uc := SQLite.new()
## Database for font data.
var db_saves := SQLite.new()
## Database for local data (i.e. machine-specific, not meant to be synced).
var db_locals := SQLite.new()

var root: Node
var scn_all: Resource
var scn_start: Resource


func _ready() -> void:
	db_uc.path = "res://assets/uc.db"
	db_uc.read_only = true
	db_uc.open_db()

	db_saves.path = "user://saves.db"
	db_saves.open_db()

	db_locals.path = "user://locals.db"
	db_locals.open_db()

	init_font_metas()
	init_locals_paths()
	init_cfg()

	ResourceLoader.load_threaded_request("res://components/start/start.tscn")
	ResourceLoader.load_threaded_request("res://components/all.tscn")
	root = get_tree().root


## Transitions from "start" to "all."
func start_all() -> void:
	if not scn_all:
		scn_all = ResourceLoader.load_threaded_get("res://components/all.tscn")
	start_all_defer.call_deferred()


func start_all_defer() -> void:
	root.get_child(root.get_child_count() - 1).free()
	root.add_child(scn_all.instantiate())


## Transitions from "all" to "start."
func all_start() -> void:
	if not scn_start:
		scn_start = ResourceLoader.load_threaded_get("res://components/start/start.tscn")
	all_start_defer.call_deferred()


func all_start_defer() -> void:
	root.get_child(root.get_child_count() - 1).free()
	root.add_child(scn_start.instantiate())


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


## Initializes local table for font save paths.
func init_locals_paths() -> void:
	(
		db_locals
		. create_table(
			"paths",
			{
				id = {data_type = "text", not_null = true, primary_key = true, unique = true},
				path = {data_type = "string", not_null = true},
			}
		)
	)


## Initializes local table for editor settings.
func init_cfg() -> void:
	cfg.load("user://settings.ini")


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


## Returns whether font [param id] already exists in the fonts database.
func has_font(id: String) -> bool:
	StateVars.db_saves.query_with_bindings("select 1 from fonts where id = ?", [id])
	return not StateVars.db_saves.query_result.is_empty()


## Deletes font [param id].
func delete_font(id: String) -> void:
	StateVars.db_saves.query_with_bindings("delete from fonts where id = ?;", [id])
	StateVars.db_saves.drop_table("font_" + id)


## Renames font [param old] to [param new].
func rename_font(old: String, new: String) -> void:
	StateVars.db_saves.query("begin transaction;")
	StateVars.db_saves.query("drop table if exists font_%s;" % new)
	StateVars.db_saves.query("alter table font_%s rename to font_%s;" % [old, new])
	StateVars.db_saves.query_with_bindings("delete from fonts where id = ?;", [new])
	StateVars.db_saves.query_with_bindings("update fonts set id = ? where id = ?;", [new, old])
	StateVars.db_saves.query("commit;")

	StateVars.db_locals.query("begin transaction;")
	StateVars.db_locals.query_with_bindings("delete from paths where id = ?;", [new])
	StateVars.db_locals.query_with_bindings("update paths set id = ? where id = ?;", [new, old])
	StateVars.db_locals.query("commit;")


## Returns the save path of the current font.
func path() -> String:
	StateVars.db_locals.query_with_bindings(
		"select path from paths where id = ?", [StateVars.font.id]
	)
	var qs := StateVars.db_locals.query_result
	return "" if qs.is_empty() else qs[0].path


## Sets the save path of the current font to [param p].
func set_path(p: String) -> void:
	StateVars.db_locals.query_with_bindings(
		"insert or replace into paths (id, path) values (?, ?);", [font.id, p]
	)
