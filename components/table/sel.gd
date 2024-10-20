class_name Sel
extends Resource

signal reselect

var table: Table

var sel := {}
var ranges_sel: Array[int] = []
var anchor_sel := -1

var inv := {}
var ranges_inv: Array[int] = []
var anchor_inv := -1


func clear() -> void:
	sel.clear()
	ranges_sel.clear()
	anchor_sel = -1
	inv.clear()
	ranges_inv.clear()
	anchor_inv = -1
	reselect.emit()


# TODO: clear grid if active
func delete() -> void:
	for n in sel:
		StateVars.db_saves.delete_rows("font_" + StateVars.font.id, "name = " + JSON.stringify(n))
		table.thumbs.erase(n)
		if n in table.vglyphs:
			table.vglyphs[n].set_thumb()
