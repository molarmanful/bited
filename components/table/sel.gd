class_name Sel
extends Resource

var table: Table

var ranges: Array[int] = []
var names := {}
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
	for g in table.vglyphs.values():
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
	table.node_info_text.text = StateVars.get_info(g.data_name, g.data_code)
	table.node_info.show()
	add_name(g)


func select_range(g: Glyph) -> void:
	end = g.ind
	ranges.assign(norm())
	refresh()
	get_sel_text()
	add_name(g)


func select_inv(g: Glyph) -> void:
	mode = not is_selected(g.ind)
	anchor = g.ind
	end = g.ind
	commit()
	g.selected = mode
	get_sel_text()
	add_name(g)


func select_range_inv(g: Glyph) -> void:
	if anchor < 0:
		return

	end = g.ind
	commit()
	refresh()
	get_sel_text()
	add_name(g)


func clear() -> void:
	anchor = -1
	end = -1
	mode = true
	ranges.clear()
	names.clear()
	table.node_info.hide()
	refresh()


# TODO: account for def-glyphs filter
func delete() -> void:
	StateVars.db_saves.query("begin transaction;")
	(
		StateVars
		. db_saves
		. query(
			(
				"""
				create table temp.to_del as
				select name from font_%s where 0
				;"""
				% StateVars.font.id
			)
		)
	)

	for i in range(0, ranges.size(), 2):
		var a := ranges[i]
		var b := ranges[i + 1]
		(
			StateVars
			. db_saves
			. query_with_bindings(
				(
					"""
					insert into temp.to_del (name)
					select name from font_%s
					order by code, name
					limit ? offset ?
					;"""
					% StateVars.font.id
				),
				[b - a, a]
			)
		)

	(
		StateVars
		. db_saves
		. query(
			(
				"""
				delete from font_%s
				where name in (select name from temp.to_del)
				;
				drop table temp.to_del;
				"""
				% StateVars.font.id
			)
		)
	)
	StateVars.db_saves.query("commit;")

	StateVars.edit_refresh.emit()
	table.thumbs.clear()
	if not table.ranged:
		table.set_glyphs()
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


func add_name(g: Glyph) -> void:
	names[g.ind] = {name = g.data_name, code = g.data_code}


func get_sel_text() -> void:
	if is_empty():
		table.node_info.hide()
		return
	table.node_info.show()
	table.node_info_text.text = "%d item%s selected" % [length, "s" if length != 1 else ""]
