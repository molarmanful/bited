class_name Bitmap
extends Node

var grid: Grid
var data_name: StringName


func _init(g: Grid, dn: StringName) -> void:
	grid = g
	data_name = dn


func gen() -> Dictionary:
	var bounds := grid.cells.get_used_rect()
	var bl = Vector2i(bounds.position.x, bounds.end.y)
	var img = grid.cells.get_region(bounds)

	return {
		name = data_name,
		img = img.save_png_to_buffer(),
		off = (bl - grid.origin) * Vector2i(1, -1) if bounds.size else bounds.size,
	}
