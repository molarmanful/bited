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
	g.selected = true


func select_range(g: Glyph) -> void:
	end = g.ind
	var rs := [anchor, end + 1]
	rs.sort()
	ranges.assign(rs)
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

	commit()
	end = g.ind
	commit()
	refresh()


func clear() -> void:
	anchor = -1
	end = -1
	mode = true
	ranges.clear()
	refresh()


# TODO: clear grid if active
func delete() -> void:
	for i in range(0, ranges.size(), 2):
		var a := ranges[i]
		var b := ranges[i + 1]

		(
			StateVars
			. query_with_bindings(
				(
					"""
					delete from font_%s
					limit ? offset ?
					;"""
					% StateVars.font.id
				),
				[a - b, a]
			)
		)
		# table.thumbs.erase(n)
		# if n in table.vglyphs:
		# 	table.vglyphs[n].set_thumb()


func commit() -> void:
	if anchor < 0 or end < 0:
		return

	var x := min(anchor, end) as int
	var y := (max(anchor, end) as int) + 1

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
	return anchor >= 0 and end < 0 and ranges.is_empty()
