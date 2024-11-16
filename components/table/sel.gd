class_name Sel
extends Resource

var table: Table

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


func refresh() -> void:
	for g in table.names.values():
		g.selected = is_selected(g.ind)


func is_selected(i: int) -> bool:
	var a := mode and (i == anchor or (end >= 0 and Util.between(i, anchor, end)))
	var b := func(): return ranges.bsearch(i, false) % 2
	return a or b.call()


func select(g: Glyph) -> void:
	clear()
	anchor = g.ind
	ranges.assign([anchor, anchor + 1])
	g.selected = true
	table.node_info_text.text = StateVars.get_info(g.data_name, g.data_code, g.nop)
	table.node_info.show()


func select_range(g: Glyph) -> void:
	end = g.ind
	ranges.assign(norm())
	refresh()
	get_sel_text()


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
	get_sel_text()


func clear() -> void:
	anchor = -1
	end = -1
	mode = true
	ranges.clear()
	table.node_info.hide()
	refresh()


func delete() -> void:
	if is_empty():
		return

	StateVars.db_saves.query("begin transaction;")

	for i in range(0, ranges.size(), 2):
		var a := ranges[i]
		var b := ranges[i + 1] - 1
		if table.viewmode == Table.Mode.RANGE:
			(
				StateVars
				. db_saves
				. query_with_bindings(
					(
						"""
						delete from font_%s
						where code between ? and ?
						;"""
						% StateVars.font.id
					),
					[a, b]
				)
			)
		else:
			(
				StateVars
				. db_saves
				. query_with_bindings(
					(
						"""
						delete from font_%s
						where name in (
							select name
							from temp.full
							where row between ? and ?
						);"""
						% StateVars.font.id
					),
					[a, b]
				)
			)

	StateVars.db_saves.query("commit;")

	StateVars.edit_refresh.emit()
	table.thumbs.clear()
	table.reset_full()
	table.to_update = true


func copy() -> void:
	if is_empty():
		return

	StateVars.db_saves.query("begin transaction;")

	StateVars.db_saves.query("drop table if exists temp.clip;")
	(
		StateVars
		. db_saves
		. query(
			(
				"""
				create table temp.clip as
				select
					cast(null as integer) as row,
					name, code, dwidth, bb_x, bb_y, off_x, off_y, img
				from font_%s
				where 0
				;"""
				% StateVars.font.id
			)
		)
	)

	for i in range(0, ranges.size(), 2):
		var a := ranges[i]
		var b := ranges[i + 1] - 1
		if table.viewmode == Table.Mode.RANGE:
			(
				StateVars
				. db_saves
				. query_with_bindings(
					(
						"""
						insert into temp.clip (row, name, code, dwidth, bb_x, bb_y, off_x, off_y, img)
						select
							row_number() over (order by code, name) + (
								select case when count(*) > 0 then max(row) else -1 end
								from temp.clip
							),
							name, code, dwidth, bb_x, bb_y, off_x, off_y, img
						from font_%s
						where code between ? and ?
						;"""
						% StateVars.font.id
					),
					[a, b]
				)
			)
		else:
			(
				StateVars
				. db_saves
				. query_with_bindings(
					(
						"""
						insert into temp.clip (row, name, code, dwidth, bb_x, bb_y, off_x, off_y, img)
						select
							row_number() over (order by b.row) + (
								select case when count(*) > 0 then max(row) else -1 end
								from temp.clip
							),
							a.name, a.code, a.dwidth, a.bb_x, a.bb_y, a.off_x, a.off_y, a.img
						from font_%s as a
						join temp.full as b
						on a.name = b.name
						where b.row between ? and ?
						;"""
						% StateVars.font.id
					),
					[a, b]
				)
			)

	StateVars.db_saves.query("commit;")

	StateVars.db_saves.query("select name, code from temp.clip order by row;")
	var res := "".join(
		StateVars.db_saves.query_result.map(
			func(q: Dictionary): return q.name if q.code < 0 else char(q.code)
		)
	)
	DisplayServer.clipboard_set(res)


func paste() -> void:
	if is_empty():
		return
	if (
		StateVars
		. db_saves
		. select_rows("sqlite_temp_master", "name = 'clip' and type = 'table'", ["name"])
		. is_empty()
	):
		return

	StateVars.db_saves.query("begin transaction;")

	(
		StateVars
		. db_saves
		. query(
			(
				"""
				create table temp.sub as
				select
					cast(null as integer) as row,
					name, code
				from font_%s
				where 0
				;"""
				% StateVars.font.id
			)
		)
	)

	var row := 0
	for i in range(0, ranges.size(), 2):
		var a := ranges[i]
		var b := ranges[i + 1] - 1
		if table.viewmode == Table.Mode.RANGE:
			for code in range(a, b + 1):
				StateVars.db_saves.insert_row(
					"temp.sub", {row = row, name = "%04X" % code, code = code}
				)
				row += 1
		else:
			(
				StateVars
				. db_saves
				. query_with_bindings(
					"""
					insert into temp.sub (row, name, code)
					select
						row_number() over (order by row) - 1,
						name, code
					from temp.full as f
					where f.row between ? and ?
					;""",
					[a, b]
				)
			)

	(
		StateVars
		. db_saves
		. query(
			(
				"""
				with cyc as (
					select b.name, b.code, a.dwidth, a.bb_x, a.bb_y, a.off_x, a.off_y, a.img
					from temp.sub as b
					join temp.clip as a
					on b.row %% (select count(*) from temp.clip) = a.row
				)
				insert or replace into font_%s (name, code, dwidth, bb_x, bb_y, off_x, off_y, img)
				select name, code, dwidth, bb_x, bb_y, off_x, off_y, img
				from cyc
				;"""
				% StateVars.font.id
			)
		)
	)

	StateVars.db_saves.query("drop table temp.sub;")
	StateVars.db_saves.query("commit;")

	StateVars.edit_refresh.emit()
	table.thumbs.clear()
	table.reset_full()
	table.to_update = true


func norm() -> Array[int]:
	return [min(anchor, end) as int, (max(anchor, end) as int) + 1]


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
				x = min(a, x)
				y = max(b, y)

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


func is_alone() -> bool:
	return ranges.size() == 2 and ranges[1] - ranges[0] == 1


func is_empty() -> bool:
	return ranges.is_empty()


func get_sel_text() -> void:
	if is_empty():
		table.node_info.hide()
		return
	table.node_info.show()
	table.node_info_text.text = "%d item%s selected" % [length, "s" if length != 1 else ""]
