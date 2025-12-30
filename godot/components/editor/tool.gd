class_name Tool
extends RefCounted

enum State { X, START, END }
enum CMode { DEFAULT, T, F, INV, CELL, MAX }

var grid: Grid
var prev: Image
var cmode := CMode.DEFAULT
var pivot: Vector2i

var pos: Vector2i:
	get:
		return Vector2i(grid.get_local_mouse_position() / grid.w_cell)

var tools: Dictionary[String, _Tool]


func _init(g: Grid) -> void:
	grid = g
	tools = {
		pen = ToolPen.new(self),
		line = ToolLine.new(self),
		rect = ToolRect.new(self),
		move = ToolMove.new(self)
	}


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
	return (
		0 <= p.x
		and p.x < grid.pattern_root.bitmap.dim
		and 0 <= p.y
		and p.y < grid.pattern_root.bitmap.dim
	)


class _Tool:
	var name := "tool"
	var c_grid: Grid
	var c_tool: Tool
	var p: Vector2i
	var a := true

	func _init(t: Tool) -> void:
		c_tool = t
		c_grid = c_tool.grid

	func pre() -> void:
		c_grid.pattern_top.node.mouse_default_cursor_shape = (Control.CURSOR_CROSS)

	func handle(state := State.X) -> void:
		if state == State.END:
			end()
			return

		if not c_grid.pressed:
			return

		p = c_tool.pos
		if state == State.START:
			start()

		update()
		c_grid.to_update_cells = true

	func start() -> void:
		a = true
		if c_tool.cmode == CMode.CELL:
			a = not c_grid.pattern_top.cells.get_pixelv(p).a
		c_tool.prev = Util.img_copy(c_grid.pattern_top.cells)
		c_grid.grab_focus()

	func update() -> void:
		pass

	func end() -> void:
		if c_grid.is_sel:
			return
		c_grid.act_cells(Util.img_copy(c_tool.prev))
		c_grid.pattern_root.bitmap.save()

	func get_c(v: Vector2i) -> Color:
		return Color(1, 1, 1, get_a(v))

	func get_a(v: Vector2i) -> bool:
		match c_tool.cmode:
			CMode.T:
				return true
			CMode.F:
				return false
			CMode.INV:
				return not c_tool.prev.get_pixelv(v).a
			_:
				return a


class ToolPen:
	extends _Tool

	func _init(t: Tool) -> void:
		super(t)
		name = "pen"

	func start() -> void:
		super()
		a = not c_grid.pattern_top.cells.get_pixelv(p).a
		c_tool.pivot = p

	func update() -> void:
		super()
		c_tool.interp(p, func(v): c_grid.pattern_top.cells.set_pixelv(v, get_c(v)))
		c_tool.pivot = p


class ToolLine:
	extends _Tool

	func _init(t: Tool) -> void:
		super(t)
		name = "line"

	func start() -> void:
		super()
		c_tool.pivot = p

	func update() -> void:
		super()
		c_grid.pattern_top.cells.copy_from(c_tool.prev)
		c_tool.interp(p, func(v): c_grid.pattern_top.cells.set_pixelv(v, get_c(v)))


class ToolRect:
	extends _Tool

	func _init(t: Tool) -> void:
		super(t)
		name = "rect"

	func start() -> void:
		super()
		c_tool.pivot = p

	func update() -> void:
		super()
		c_grid.pattern_top.cells.copy_from(c_tool.prev)
		var rect := Rect2i(c_tool.pivot, p - c_tool.pivot).abs().grow_individual(0, 0, 1, 1)

		if c_tool.cmode == CMode.INV:
			for x in rect.size.x:
				for y in rect.size.y:
					var v := Vector2i(x, y) + rect.position
					c_grid.pattern_top.cells.set_pixelv(v, get_c(v))
		else:
			c_grid.pattern_top.cells.fill_rect(rect, get_c(p))


class ToolMove:
	extends _Tool

	func _init(t: Tool) -> void:
		super(t)
		name = "move"

	func pre() -> void:
		c_grid.pattern_top.node.mouse_default_cursor_shape = Control.CURSOR_MOVE

	func start() -> void:
		super()
		c_tool.pivot = p

	func update() -> void:
		super()
		c_grid.pattern_top.cells.fill(Color.TRANSPARENT)
		c_grid.pattern_top.cells.blit_rect(
			c_tool.prev, Rect2i(Vector2i.ZERO, c_tool.prev.get_size()), p - c_tool.pivot
		)
