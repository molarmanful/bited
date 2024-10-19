class_name Sel
extends Resource

signal reselect

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
