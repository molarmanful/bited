class_name Sel
extends Node

@export var table: Table

var ranges: Array[int] = []
var anchor := -1
var end := -1
var mode := true

var length: int:
	get:
		var sum := 0
		for i in range(0, ranges.size(), 2):
			var a := ranges[i]
			var b := ranges[i + 1]
			sum += b - a
		return sum


func all() -> void:
	if table.viewmode == Table.Mode.RANGE:
		anchor = table.start
		end = table.end
	else:
		anchor = 0
		end = table.virt.length
	ranges.assign(norm())
	refresh()


func filter_dwidth(dw: int, ia := false) -> void:
	(
		StateVars
		. db
		. query(
			(
				"""-- sql
				begin;

				drop table if exists temp.filter;

				create table temp.filter as
				select cast(null as integer) as row, name from font_{0} where 0;
				"""
				. format([StateVars.font.id])
			)
		)
	)

	for i in range(0, ranges.size(), 2):
		var a := ranges[i]
		var b := ranges[i + 1] - 1
		if table.viewmode == Table.Mode.RANGE:
			(
				StateVars
				. db
				. query_with_named_bindings(
					(
						"""-- sql
						insert into temp.filter(row, name)
						select code, name
						from font_{0}
						where
							(code between :a and :b)
							and is_abs = :is_abs
							and dwidth = :dwidth;
						"""
						. format([StateVars.font.id])
					),
					{a = a, b = b, is_abs = int(ia), dwidth = dw}
				)
			)
		else:
			(
				StateVars
				. db
				. query_with_named_bindings(
					(
						"""-- sql
						insert into temp.filter(row, name)
						select b.row, a.name
						from font_{0} as a
						join temp.tbl as b on a.name = b.name
						where
							(b.row between :a and :b)
							and a.is_abs = :is_abs
							and a.dwidth = :dwidth;
						"""
						. format([StateVars.font.id])
					),
					{a = a, b = b, is_abs = int(ia), dwidth = dw}
				)
			)

	clear()
	(
		StateVars
		. db
		. query(
			"""-- sql
			commit;

			with
				rows as (
					select row, row - (row_number() over (order by row)) as g from temp.filter
				)
			select min(row) as a, max(row) + 1 as b from rows group by g;
			"""
		)
	)
	var qs := StateVars.db.query_result
	for q in qs:
		ranges.push_back(q.a)
		ranges.push_back(q.b)
	if ranges:
		anchor = ranges[0]
	StateVars.db.query("drop table if exists temp.filter;")
	refresh()


func delete() -> void:
	if table.pick_layer or not ranges:
		return

	StateVars.db.query("begin;")

	var dels := []
	for i in range(0, ranges.size(), 2):
		var a := ranges[i]
		var b := ranges[i + 1] - 1
		(
			StateVars
			. db
			. query_with_named_bindings(
				(
					"""-- sql
					delete from font_{0}
					where
						name in (select name from {1} where {2} between :a and :b)
					returning name;
					"""
					. format(
						[
							StateVars.font.id,
							(
								"font_{0}".format([StateVars.font.id])
								if table.viewmode == Table.Mode.RANGE
								else "temp.tbl"
							),
							"code" if table.viewmode == Table.Mode.RANGE else "row"
						]
					)
				),
				{a = a, b = b}
			)
		)
		dels.append_array(StateVars.db.query_result.map(func(q): return q.name))

	var js := JSON.stringify(dels)
	StateVars.db.query_with_named_bindings(
		"delete from layers_{0} where parent in (select value from json_each(:names));".format(
			[StateVars.font.id]
		),
		{names = js}
	)
	StateVars.font.flatten_parents(dels)
	StateVars.db.query_with_named_bindings(
		"delete from layers_{0} where child in (select value from json_each(:names));".format(
			[StateVars.font.id]
		),
		{names = js}
	)

	StateVars.db.query("commit;")

	StateVars.edit_refresh.emit()
	table.thumbs.clear()
	table.reset_full()
	table.to_update = true


func copy() -> void:
	if table.pick_layer or not ranges:
		return

	(
		StateVars
		. db
		. query(
			(
				"""-- sql
				begin;

				drop table if exists temp.clip;

				create table temp.clip as
				select
					cast(null as integer) as row,
					name,
					code,
					dwidth,
					is_abs,
					bb_x,
					bb_y,
					off_x,
					off_y,
					img
				from font_{0}
				where
					0;
				"""
				. format([StateVars.font.id])
			)
		)
	)

	for i in range(0, ranges.size(), 2):
		var a := ranges[i]
		var b := ranges[i + 1] - 1
		if table.viewmode == Table.Mode.RANGE:
			(
				StateVars
				. db
				. query_with_named_bindings(
					(
						"""-- sql
						insert into temp.clip(
							row,
							name,
							code,
							dwidth,
							is_abs,
							bb_x,
							bb_y,
							off_x,
							off_y,
							img
						)
						select
							row_number() over (order by code, name) + (select count(*) from temp.clip) - 1,
							name,
							code,
							dwidth,
							is_abs,
							bb_x,
							bb_y,
							off_x,
							off_y,
							img
						from font_{0}
						where
							code between :a and :b;
						"""
						. format([StateVars.font.id])
					),
					{a = a, b = b}
				)
			)
		else:
			(
				StateVars
				. db
				. query_with_named_bindings(
					(
						"""-- sql
						insert into temp.clip(
							row,
							name,
							code,
							dwidth,
							is_abs,
							bb_x,
							bb_y,
							off_x,
							off_y,
							img
						)
						select
							row_number() over (order by b.row) + (select count(*) from temp.clip) - 1,
							a.name,
							a.code,
							a.dwidth,
							a.is_abs,
							a.bb_x,
							a.bb_y,
							a.off_x,
							a.off_y,
							a.img
						from font_{0} as a
						join temp.tbl as b on a.name = b.name
						where
							b.row between :a and :b;
						"""
						. format([StateVars.font.id])
					),
					{a = a, b = b}
				)
			)

	if not (
		StateVars
		. db
		. query(
			(
				"""-- sql
				drop table if exists temp.clip_layers;

				create table temp.clip_layers as
				select * from layers_{0} where parent in (select name from temp.clip);

				commit;
				"""
				. format([StateVars.font.id])
			)
		)
	):
		StateVars.db.query("rollback;")

	var res := ""
	for i in range(0, ranges.size(), 2):
		var a := ranges[i]
		var b := ranges[i + 1] - 1
		if table.viewmode == Table.Mode.RANGE:
			for code in range(a, b + 1):
				res += char(code)
		else:
			StateVars.db.query_with_named_bindings(
				"select name, code from temp.tbl where row between :a and :b;", {a = a, b = b}
			)
			for q in StateVars.db.query_result:
				res += q.name if q.code < 0 else char(q.code)

	DisplayServer.clipboard_set(res)


func paste() -> void:
	if table.pick_layer or not ranges:
		return
	if not StateVars.db.select_rows(
		"sqlite_temp_master", "name = 'clip' and type = 'table'", ["name"]
	):
		return

	(
		StateVars
		. db
		. query(
			(
				"""-- sql
				begin;

				create table temp.sub as
				select cast(null as integer) as row, name, code from font_{0} where 0;
				"""
				. format([StateVars.font.id])
			)
		)
	)

	var row := 0
	for i in range(0, ranges.size(), 2):
		var a := ranges[i]
		var b := ranges[i + 1] - 1
		if table.viewmode == Table.Mode.RANGE:
			for code in range(a, b + 1):
				StateVars.db.insert_row(
					"temp.sub", {row = row, name = "U+%04X" % code, code = code}
				)
				row += 1
		else:
			(
				StateVars
				. db
				. query_with_named_bindings(
					"""-- sql
					insert into temp.sub(row, name, code)
					select row_number() over (order by row) - 1, name, code
					from temp.tbl as f
					where
						f.row between :a and :b;
					""",
					{a = a, b = b}
				)
			)

	(
		StateVars
		. db
		. query(
			(
				"""-- sql
				insert or replace into font_{0}(
					name,
					code,
					dwidth,
					is_abs,
					bb_x,
					bb_y,
					off_x,
					off_y,
					img
				)
				select
					b.name,
					b.code,
					a.dwidth,
					a.is_abs,
					a.bb_x,
					a.bb_y,
					a.off_x,
					a.off_y,
					a.img
				from temp.sub as b
				join temp.clip as a on b.row % (select count(*) from temp.clip) = a.row;

				delete from layers_{0} where parent in (select name from temp.sub);

				with
					m as (
						select b.row, b.name, a.name as src
						from temp.sub as b
						join temp.clip as a on b.row % (select count(*) from temp.clip) = a.row
					)
				insert or ignore into layers_{0}(
					parent,
					ord,
					child,
					off_x,
					off_y,
					blend,
					xform
				)
				select
					coalesce(m.name, l.parent),
					l.ord,
					coalesce(
						(select name from font_{0} where name = l.child),
						(select k.name from m as k where k.src = l.child order by k.row limit 1)
					),
					l.off_x,
					l.off_y,
					l.blend,
					l.xform
				from temp.clip_layers as l
				left join m on m.src = l.parent
				where
					m.name is not null
					or l.parent in (
						select name from font_{0}
						except
						select name from temp.sub
					);

				delete from temp.clip_layers where parent not in (select name from temp.clip);

				with recursive
					down(top, name) as (
						select parent, child
						from layers_{0}
						where
							parent in (select name from temp.sub)
						union
						select d.top, l.child
						from layers_{0} as l
						join down as d on l.parent = d.name
					)
				delete from layers_{0}
				where
					parent in (select top from down where top = name);

				select name from temp.sub
				union
				select child from layers_{0} where parent in (select name from temp.sub);
				"""
				. format([StateVars.font.id])
			)
		)
	)

	StateVars.font.flatten_parents(StateVars.db.query_result.map(func(q): return q.name))
	if not StateVars.db.query("drop table temp.sub; commit;"):
		StateVars.db.query("rollback;")

	StateVars.edit_refresh.emit()
	table.thumbs.clear()
	table.reset_full()
	table.to_update = true


func commit() -> void:
	if anchor < 0 or end < 0:
		return

	var xy := norm()
	var x := xy[0]
	var y := xy[1]

	var res: Array[int] = []
	var merged := false

	for i in range(0, ranges.size(), 2):
		var a := ranges[i]
		var b := ranges[i + 1]

		if mode:
			if b < x:
				res.push_back(a)
				res.push_back(b)
			elif a > y:
				if not merged:
					res.push_back(x)
					res.push_back(y)
					merged = true
				res.push_back(a)
				res.push_back(b)
			else:
				x = mini(a, x)
				y = maxi(b, y)

		else:
			if b <= x or a >= y:
				res.push_back(a)
				res.push_back(b)
			elif a < x and b > x and b <= y:
				res.push_back(a)
				res.push_back(x)
			elif a >= x and a < y and b > y:
				res.push_back(y)
				res.push_back(b)
			elif a < x and b > y:
				res.push_back(a)
				res.push_back(x)
				res.push_back(y)
				res.push_back(b)

	if mode and not merged:
		res.push_back(x)
		res.push_back(y)

	ranges.assign(res)
	end = -1


func cut() -> void:
	copy()
	(
		StateVars
		. db
		. query(
			(
				"""-- sql
				insert into temp.clip_layers
				select *
				from layers_{0}
				where
					child in (select name from temp.clip)
					and parent not in (select name from temp.clip);
				"""
				. format([StateVars.font.id])
			)
		)
	)
	delete()


func select(g: Glyph) -> void:
	clear()
	anchor = g.ind
	ranges.assign([anchor, anchor + 1])
	g.selected = true
	get_sel_text()
	table.node_info_text.text = StateVars.get_info(g.data_name, g.data_code, g.nop)


func select_range(g: Glyph) -> void:
	anchor = maxi(0, anchor)
	end = g.ind
	ranges.assign(norm())
	refresh()


func select_inv(g: Glyph) -> void:
	mode = not is_selected(g.ind)
	anchor = g.ind
	end = g.ind
	commit()
	g.selected = mode
	get_sel_text()


func select_range_inv(g: Glyph) -> void:
	if anchor < 0:
		return
	end = g.ind
	commit()
	refresh()


func clear() -> void:
	anchor = -1
	end = -1
	mode = true
	ranges.clear()
	refresh()


func refresh(txt := true) -> void:
	for g in table.names.values():
		g.selected = is_selected(g.ind)
	if txt:
		get_sel_text()


func get_sel_text() -> void:
	update()
	if ranges:
		table.node_info_text.text = ("%d item%s selected" % [length, "s" if length != 1 else ""])


func update() -> void:
	table.get_tree().call_group("selshow", "show" if ranges else "hide")
	table.get_tree().call_group("sel_named", "set_visible", named() != "")
	if table.pick_layer:
		table.get_tree().call_group("hide_on_pick", "hide")


func is_selected(i: int) -> bool:
	var a := mode and (i == anchor or (end >= 0 and Util.between(i, anchor, end)))
	return a or ranges.bsearch(i, false) % 2


func named() -> String:
	if not is_alone() or table.viewmode != Table.Mode.GLYPHS:
		return ""
	StateVars.db.query_with_named_bindings(
		"select name from temp.tbl where row = :row and code < 0;", {row = ranges[0]}
	)
	var qs := StateVars.db.query_result
	return qs[0].name if qs else ""


func is_alone() -> bool:
	return ranges.size() == 2 and ranges[1] - ranges[0] == 1


func norm() -> Array[int]:
	return [mini(anchor, end), maxi(anchor, end) + 1]
