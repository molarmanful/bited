extends Node2D

var w_cell: int
var w_grid: int
var color: Color


func _draw() -> void:
	var res: Array[Vector2i] = []
	for i in w_grid:
		res.push_back(Vector2i(0, i * w_cell))
		res.push_back(Vector2i(w_grid, i * w_cell))
		res.push_back(Vector2i(i * w_cell, 0))
		res.push_back(Vector2i(i * w_cell, w_grid))

	draw_multiline(res, color)
