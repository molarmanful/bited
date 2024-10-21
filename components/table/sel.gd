class_name Sel
extends Resource

var table: Table

var ranges: Array[int] = []
var anchor := -1
var end := -1
var mode := true


func refresh() -> void:
	for g1 in table.vglyphs.values():
		g1.selected = is_selected(g1.ind)


func is_selected(i: int) -> bool:
	var a := mode and (i == anchor or (end >= 0 and Util.between(i, anchor, end)))
	var b := func(): return ranges.bsearch(i, false) % 2
	return a or b.call()


func select(g: Glyph) -> void:
	clear()
	anchor = g.ind
	ranges.assign([anchor, anchor + 1])
	g.selected = true


func select_range(g: Glyph) -> void:
	end = g.ind
	ranges.assign(norm())
	refresh()


func select_inv(g: Glyph) -> void:
	anchor = g.ind
	end = anchor
	mode = !is_selected(g.ind)
	commit()
	g.selected = mode


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


# TODO: clear editor if active
# FIXME
func delete() -> void:
	for i in range(0, ranges.size(), 2):
		var a := ranges[i]
		var b := ranges[i + 1]

		var q := (
			StateVars
			. db_saves
			. query_with_bindings(
				(
					"""
					delete from font_{0}
					where name in (
						select name from font_{0}
						order by code, name
						limit ? offset ?
					);"""
					. format([StateVars.font.id])
				),
				[b - a, a]
			)
		)
		if not q:
			return

	var gs: Array[Glyph]
	gs.assign(table.vglyphs.values())
	table.update_imgs(gs)


func norm() -> Array[int]:
	return [min(anchor, end) as int, (max(anchor, end) as int) + 1]


func commit() -> void:
	if anchor < 0 or end < 0:
		return

	var xy := norm()
	var x := xy[0]
	var y := xy[1]

	var res: Array[int] = []
	var merged = false

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
