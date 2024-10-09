class_name Tool
extends Node

enum { X, START, END }

var grid: Grid
var prev: Image
var a: bool
var pivot: Vector2i

var pos: Vector2i:
	get:
		return Vector2i(grid.get_local_mouse_position() / grid.w_cell)


func _init(g: Grid) -> void:
	grid = g


func pen(state := X) -> void:
	if not grid.pressed:
		return

	var p = pos
	if state == 1:
		a = not grid.cells.get_pixelv(p).a
		pivot = p

	interp(p, func(v): grid.cells.set_pixelv(v, Color(1, 1, 1, a)))
	pivot = p
	grid.to_update_cells = true


func line(state := X) -> void:
	if not grid.pressed:
		return

	var p = pos
	if state == 1:
		prev = grid.cells.get_region(Rect2i(0, 0, grid.dim_grid, grid.dim_grid))
		a = true
		pivot = p

	grid.cells.copy_from(prev)
	interp(p, func(v): grid.cells.set_pixelv(v, Color(1, 1, 1, a)))
	grid.to_update_cells = true


func interp(p: Vector2i, f: Callable) -> void:
	var pos0 := Vector2i(pivot)
	if not check_pos(pos0):
		return
	f.call(pos0)

	var d := (p - pos0).abs()
	var s := (p - pos0).sign()
	var e := d.x - d.y

	while p != pos0:
		var e2 := e * 2
		if e2 > -d.y:
			e -= d.y
			pos0.x += s.x
		if e2 < d.x:
			e += d.x
			pos0.y += s.y
		if not check_pos(pos0):
			return
		f.call(pos0)


func check_pos(p: Vector2i) -> bool:
	return 0 <= p.x and p.x < grid.dim_grid and 0 <= p.y and p.y < grid.dim_grid
