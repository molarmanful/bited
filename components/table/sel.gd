class_name Sel
extends Resource

signal reselect

var sel := {}
var sel_anchor: String

var inv := {}
var inv_anchor: String


func clear() -> void:
	sel.clear()
	reselect.emit()
