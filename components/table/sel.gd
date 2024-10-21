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
	print("next")
	commit()
	g.selected = mode


func select_range_inv(g: Glyph) -> void:
	if anchor < 0:
		return

	commit()
	end = g.ind
	commit()
	refresh()


func commit() -> void:
	if anchor < 0 or end < 0:
		return

	var x := min(anchor, end) as int
	var y := (max(anchor, end) as int) + 1

	var res: Array[int] = []

	var stage := 0
	for i in range(0, ranges.size(), 2):
		var a := ranges[i]
		var b := ranges[i + 1]

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

	ranges.assign(res)
	printt(ranges)
	end = -1


# FIXME: remove
func test() -> void:
	ranges = [1, 9]
	anchor = 2
	end = 5
	mode = false
	commit()
	clear()
	print([1, 2, 6, 9])
	print("---")

	ranges = [1, 9]
	anchor = 1
	end = 3
	mode = false
	commit()
	clear()
	print([4, 9])
	print("---")

	ranges = [1, 9]
	anchor = 3
	end = 9
	mode = false
	commit()
	clear()
	print([1, 3])
	print("---")

	ranges = [1, 9]
	anchor = 1
	end = 9
	mode = false
	commit()
	clear()
	print([])
	print("---")

	ranges = [1, 9]
	anchor = 0
	end = 5
	mode = false
	commit()
	clear()
	print([6, 9])
	print("---")

	ranges = [1, 9]
	anchor = 3
	end = 10
	mode = false
	commit()
	clear()
	print([1, 3])
	print("---")


func clear() -> void:
	anchor = -1
	end = -1
	mode = true
	ranges.clear()
	refresh()


# TODO: clear grid if active
func delete() -> void:
	pass
	# for n in yay:
	# 	StateVars.db_saves.delete_rows("font_" + StateVars.font.id, "name = " + JSON.stringify(n))
	# 	table.thumbs.erase(n)
	# 	if n in table.vglyphs:
	# 		table.vglyphs[n].set_thumb()


func is_alone() -> bool:
	return anchor >= 0 and end < 0 and ranges.is_empty()
