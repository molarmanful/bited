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

var tools: Dictionary


func _init(g: Grid) -> void:
	grid = g
	tools = {pen = ToolPen.new(self), line = ToolLine.new(self)}


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


class _Tool:
	var c_grid: Grid
	var c_tool: Tool
	var p: Vector2i

	func _init(t: Tool) -> void:
		c_tool = t
		c_grid = c_tool.grid

	func handle(state := X) -> void:
		if state == END:
			end()
			return

		if not c_grid.pressed:
			return

		p = c_tool.pos
		if state == START:
			start()

		update()
		c_grid.to_update_cells = true

	func start() -> void:
		pass

	func update() -> void:
		pass

	func end() -> void:
		c_grid.bitmap.save()


class ToolPen:
	extends _Tool

	func start() -> void:
		super()
		c_tool.a = not c_grid.cells.get_pixelv(p).a
		c_tool.pivot = p

	func update() -> void:
		super()
		c_tool.interp(p, func(v): c_grid.cells.set_pixelv(v, Color(1, 1, 1, c_tool.a)))
		c_tool.pivot = p


class ToolLine:
	extends _Tool

	func start() -> void:
		super()
		c_tool.prev = c_grid.cells.get_region(Rect2i(0, 0, c_grid.dim_grid, c_grid.dim_grid))
		c_tool.a = true
		c_tool.pivot = p

	func update() -> void:
		super()
		c_grid.cells.copy_from(c_tool.prev)
		c_tool.interp(p, func(v): c_grid.cells.set_pixelv(v, Color(1, 1, 1, c_tool.a)))
