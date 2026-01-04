class_name GridLines
extends Node2D

@export var grid: Grid

var lines_h: Dictionary[String, int] = {
	origin = 0,
	asc = 0,
	cap = 0,
	x = 0,
	desc = 0,
}

var lines_v: Dictionary[String, int] = {
	origin = 0,
	w = 0,
}

var names: Dictionary[String, String] = {
	origin = "baseline",
	asc = "ascent",
	cap = "cap height",
	x = "x-height",
	desc = "descent",
	w = "dwidth",
}


func _draw() -> void:
	var w_cell := grid.w_cell
	var w_grid := grid.w_grid
	var origin := grid.layer_root.bitmap.origin

	var res: Array[Vector2i] = []
	for i in w_grid:
		var iw := i * w_cell
		res.push_back(Vector2i(0, iw))
		res.push_back(Vector2i(w_grid, iw))
		res.push_back(Vector2i(iw, 0))
		res.push_back(Vector2i(iw, w_grid))

	draw_multiline(res, grid.get_theme_color("border"))

	lines_h = {
		origin = 0,
		asc = StateVars.font.asc,
		cap = StateVars.font.cap_h,
		x = StateVars.font.x_h,
		desc = -StateVars.font.desc,
	}

	for k in lines_h:
		var y: int = (origin.y - lines_h[k]) * w_cell
		draw_line(Vector2i(0, y), Vector2i(w_grid, y), grid.get_theme_color(k))

	lines_v = {
		origin = 0,
		w = grid.layer_root.bitmap.dwidth_calc,
	}

	for k in lines_v:
		var x: int = (origin.x + lines_v[k]) * w_cell
		draw_line(Vector2i(x, 0), Vector2i(x, w_grid), grid.get_theme_color(k))
