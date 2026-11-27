extends Node
## Global state and signal bus for non-style-related data.

## Emits when settings are saved.
signal settings
## Emits when a glyph is sent to the editor.
signal edit(data_name: String, data_code: int)
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

## SQLite DB connection.
var db := SQLite.new()

var root: Window
var scn_all: Resource
var scn_start: Resource


func _ready() -> void:
	DisplayServer.window_set_title("bited")
	root = get_tree().root
	root.borderless = false
	root.mode = Window.MODE_MAXIMIZED

	var d := SQLite.new()
	d.path = "res://assets/uc.db"
	d.read_only = true
	d.open_db()
	d.close_db()

	db.path = "user://saves.db"
	db.open_db()
	db.query("attach 'file:res://assets/uc.db?vfs=godot&mode=ro' as uc;")
	db.query_with_bindings(
		"attach ? as locals;", [ProjectSettings.globalize_path("user://locals.db")]
	)

	init_font_metas()
	migrate()
	init_locals_paths()
	init_cfg()

	ResourceLoader.load_threaded_request("res://components/start/start.tscn")
	ResourceLoader.load_threaded_request("res://components/all.tscn")


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		db.query("pragma main.optimize; pragma locals.optimize;")


## Transitions from "start" to "all".
func start_all() -> void:
	init_undo()
	if not scn_all:
		scn_all = ResourceLoader.load_threaded_get("res://components/all.tscn")
	start_all_defer.call_deferred()


func start_all_defer() -> void:
	root.get_child(root.get_child_count() - 1).free()
	root.add_child(scn_all.instantiate())
	DisplayServer.window_set_title(
		"bited - %s %s %d\u00d7%d" % [font.family, font.weight, font.bb.x, font.bb.y]
	)


## Transitions from "all" to "start".
func all_start() -> void:
	if not scn_start:
		scn_start = ResourceLoader.load_threaded_get("res://components/start/start.tscn")
	all_start_defer.call_deferred()
	DisplayServer.window_set_title("bited")


func all_start_defer() -> void:
	root.get_child(root.get_child_count() - 1).free()
	root.add_child(scn_start.instantiate())


## Initializes master table for saved fonts.
func init_font_metas() -> void:
	(
		db
		. create_table(
			"fonts",
			{
				id = {data_type = "text", primary_key = true},
				data = {data_type = "blob"},
			}
		)
	)


func migrate() -> void:
	db.query("pragma user_version;")
	if db.query_result[0].user_version >= 1:
		return

	db.query("begin;")
	db.query("select id from fonts;")
	for f in db.query_result:
		if not (
			db
			. query(
				(
					"""
					drop table if exists layers_{0};
					update font_{0} set name = 'U+' || name where code >= 0;
					"""
					. format([f.id])
				)
			)
		):
			db.query("rollback;")
			return
	db.query("pragma user_version = 1; commit;")


## Initializes local table for font save paths.
func init_locals_paths() -> void:
	(
		db
		. create_table(
			"locals.paths",
			{
				id = {data_type = "text", not_null = true, primary_key = true},
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
		. db
		. query_with_named_bindings(
			"""
			select name, category
			from uc.data
			where id = :id
			;""",
			{id = data_code}
		)
	)
	var qs := StateVars.db.query_result

	return (
		"%s  #%d%s\n%s"
		% [
			data_name,
			data_code,
			"  " + qs[0].category if qs else "",
			qs[0].name if qs else "(undefined)",
		]
	)


## Returns whether font [param id] already exists in the fonts database.
func has_font(id: String) -> bool:
	StateVars.db.query_with_named_bindings("select 1 from fonts where id = :id", {id = id})
	return not not StateVars.db.query_result


## Deletes font [param id].
func delete_font(id: String) -> void:
	if not (
		StateVars
		. db
		. query_with_named_bindings(
			(
				"""
				begin;
				delete from fonts where id = :id;
				delete from locals.paths where id = :id;
				drop table if exists font_{0};
				drop table if exists layers_{0};
				commit;
				"""
				. format([id])
			),
			{id = id}
		)
	):
		StateVars.db.query("rollback;")


## Renames font [param old] to [param new].
func rename_font(old: String, new: String) -> void:
	if not (
		StateVars
		. db
		. query_with_named_bindings(
			(
				"""
				begin;
				drop table if exists font_{1};
				drop index if exists font_{0}_code;
				alter table font_{0} rename to font_{1};
				drop table if exists layers_{1};
				drop index if exists layers_{0}_child;
				alter table layers_{0} rename to layers_{1};
				update or replace fonts set id = :new where id = :old;
				delete from locals.paths where id = :new;
				update locals.paths set id = :new where id = :old;
				commit;
				"""
				. format([old, new])
			),
			{new = new, old = old}
		)
	):
		StateVars.db.query("rollback;")
		return
	if new == font.id:
		init_undo()


## Initializes undo/redo triggers on the font.
func init_undo() -> void:
	(
		db
		. query(
			(
				"""
				pragma recursive_triggers = on;
				drop table if exists temp.undolog;
				create table temp.undolog (
					seq integer primary key,
					step int not null default 0,
					sql text not null
				);
				create index temp.undolog_step on undolog (step);

				drop trigger if exists temp.undo_font_i;
				drop trigger if exists temp.undo_font_d;
				drop trigger if exists temp.undo_font_u;
				drop trigger if exists temp.undo_layers_i;
				drop trigger if exists temp.undo_layers_d;
				drop trigger if exists temp.undo_layers_u;

				create trigger temp.undo_font_i after insert on font_{0} begin
					insert into undolog (sql) values
					(format('delete from font_{0} where name = %Q', new.name));
				end;

				create trigger temp.undo_font_d after delete on font_{0} begin
					insert into undolog (sql) values
					(format(
						'insert into font_{0} values (%Q, %d, %d, %d, %d, %d, %d, %d, %s)',
						old.name, old.code, old.dwidth, old.is_abs,
						old.bb_x, old.bb_y, old.off_x, old.off_y, quote(old.img)
					));
				end;

				create trigger temp.undo_font_u after update on font_{0} begin
					insert into undolog (sql) values
					(format(
						'insert into font_{0} values (%Q, %d, %d, %d, %d, %d, %d, %d, %s)',
						old.name, old.code, old.dwidth, old.is_abs,
						old.bb_x, old.bb_y, old.off_x, old.off_y, quote(old.img)
					)),
					(format('delete from font_{0} where name = %Q', new.name));
				end;

				create trigger temp.undo_layers_i after insert on layers_{0} begin
					insert into undolog (sql) values
					(format('delete from layers_{0} where parent = %Q and ord = %d', new.parent, new.ord));
				end;

				create trigger temp.undo_layers_d after delete on layers_{0} begin
					insert into undolog (sql) values
					(format(
						'insert into layers_{0} values (%Q, %d, %Q, %d, %d, %d, %d)',
						old.parent, old.ord, old.child, old.off_x, old.off_y, old.blend, old.xform
					));
				end;

				create trigger temp.undo_layers_u after update on layers_{0} begin
					insert into undolog (sql) values
					(format(
						'insert into layers_{0} values (%Q, %d, %Q, %d, %d, %d, %d)',
						old.parent, old.ord, old.child, old.off_x, old.off_y, old.blend, old.xform
					)),
					(format('delete from layers_{0} where parent = %Q and ord = %d', new.parent, new.ord));
				end;
				"""
				. format([font.id])
			)
		)
	)


## Commits pending undo log entries as a step.
func undo_step() -> void:
	(
		db
		. query(
			"""
			delete from temp.undolog where step < 0 and exists (select 1 from temp.undolog where step = 0);
			update temp.undolog set step = (select max(step) + 1 from temp.undolog) where step = 0;
			"""
		)
	)


## Performs an undo/redo.
func undo(redo := false) -> void:
	undo_step()
	(
		db
		. query_with_named_bindings(
			"""
			select step, sql from temp.undolog
			where step = (select max(step) from temp.undolog where iif(:redo, step < 0, step > 0))
			order by seq desc
			;""",
			{redo = redo}
		)
	)
	var qs := db.query_result
	if not qs:
		return
	db.query("begin;")
	if not (
		qs.all(func(q): return db.query(q.sql))
		and (
			db
			. query_with_named_bindings(
				"""
				delete from temp.undolog where step = :s;
				update temp.undolog set step = -:s where step = 0;
				commit;
				""",
				{s = qs[0].step}
			)
		)
	):
		db.query("rollback;")


## Saves [param font] to the fonts database.
func load_parsed(bf: BFont) -> void:
	font = bf
	StyleVars.table_width = font.table_width
	StyleVars.thumb_px_size = font.thumb_px_size
	StyleVars.grid_size = font.grid_size
	StyleVars.grid_px_size = font.grid_px_size
	font.init_font()
	font.insert_layers(font.layers)
	font.save_glyphs(font.glyphs)


## Returns the save path of the current font.
func path() -> String:
	StateVars.db.query_with_named_bindings(
		"select path from locals.paths where id = :id", {id = StateVars.font.id}
	)
	var qs := StateVars.db.query_result
	return qs[0].path if qs else ""


## Sets the save path of the current font to [param p].
func set_path(p: String) -> void:
	StateVars.db.query_with_named_bindings(
		"insert or replace into locals.paths (id, path) values (:id, :path);",
		{id = font.id, path = p}
	)
