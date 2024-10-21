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
	var a := anchor
	clear()
	anchor = max(0, a)
	end = g.ind
	refresh()


func select_inv(g: Glyph) -> void:
	anchor = g.ind
	end = anchor
	mode = !is_selected(g.ind)
	g.selected = mode
	commit()


func select_range_inv(g: Glyph) -> void:
	if anchor < 0:
		return

	end = g.ind
	commit()
	refresh()


func commit() -> void:
	var a := min(anchor, end) as int
	var b := (max(anchor, end) as int) + 1

	var res: Array[int] = []
	for i in range(0, ranges.size(), 2):
		var ra := ranges[i]
		var rb := ranges[i + 1]
		if mode:
			if rb < a or ra > b:
				res.append_array([ra, rb])
			else:
				a = min(ra, a)
				b = max(rb, b)

	ranges.assign(res)
	print(ranges)
	end = -1


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
