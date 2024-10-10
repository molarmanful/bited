class_name Bitmap
extends Node

var grid: Grid
var data_code := -1
var data_name := &""
var dwidth := StateVars.font.dwidth
var dwidth1 := StateVars.font.dwidth1
var vvector := StateVars.font.vvector


func _init(g: Grid, dc := -1, dn := &"") -> void:
	grid = g
	data_code = dc
	data_name = dn


func gen() -> Dictionary:
	var bounds := grid.cells.get_used_rect()
	var bl = Vector2i(bounds.position.x, bounds.end.y)
	var img = grid.cells.get_region(bounds)

	return {
		name = data_name,
		code = data_code,
		dwidth_x = meta.dwidth.x,
		dwidth_y = meta.dwidth.y,
		dwidth1_x = meta.dwidth1.x,
		dwidth1_y = meta.dwidth1.y,
		vvector_x = meta.vvector.x,
		vvector_y = meta.vvector.y,
		off = (bl - grid.origin) * Vector2i(1, -1) if bounds.size else bounds.size,
		img = img.save_png_to_buffer(),
	}
