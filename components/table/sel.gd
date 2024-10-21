class_name Sel
extends Resource

var table: Table

var anchor0 := -1
var anchor1 := -1

var anchor0_inv := -1
var anchor1_inv := -1

var inv := {}


func refresh() -> void:
	for g1 in table.vglyphs.values():
		g1.selected = is_selected(g1.ind)


func is_selected(i: int) -> bool:
	var a := i == anchor0 or (anchor1 >= 0 and Util.between(i, anchor0, anchor1))
	var b := i == anchor0_inv or (anchor1_inv >= 0 and Util.between(i, anchor0_inv, anchor1_inv))
	return a != b != (i in inv)


func select(g: Glyph) -> void:
	clear()
	anchor0 = g.ind
	g.selected = true


func select_range(g: Glyph) -> void:
	if anchor0 < 0:
		select(g)
		return

	anchor1 = g.ind
	refresh()


func select_inv(g: Glyph) -> void:
	anchor0_inv = g.ind
	g.selected = !g.selected


func select_range_inv(g: Glyph) -> void:
	if anchor0_inv < 0:
		select_inv(g)
		return

	anchor1_inv = g.ind
	refresh()


func clear() -> void:
	anchor0 = -1
	anchor1 = -1
	anchor0_inv = -1
	anchor1_inv = -1
	inv.clear()
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
	return anchor0 >= 0 and anchor1 < 0 and anchor0_inv < 0 and anchor1_inv < 0 and inv.is_empty()
