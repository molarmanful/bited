class_name Tool
extends RefCounted

enum State { X, START, END }
enum CMode { DEFAULT, T, F, INV, CELL, MAX }

var grid: Grid
var prev: BitGlyph
var mask: BitGlyph
var op := OP_BIT_OR
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


class _Tool:
	var name := "tool"
	var c_grid: Grid
	var c_tool: Tool
	var p: Vector2i

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
		c_grid.pattern_top.dirty = true

	func start() -> void:
		var a := get_a()
		match c_tool.cmode:
			CMode.T:
				c_tool.op = OP_BIT_OR
			CMode.F:
				c_tool.op = OP_SUBTRACT
			CMode.INV:
				c_tool.op = OP_BIT_XOR
			_:
				c_tool.op = OP_BIT_OR if a else OP_SUBTRACT
		c_tool.prev = c_grid.pattern_top.cells.dup()
		c_tool.mask = BitGlyph.create(c_tool.prev.get_size())
		c_tool.pivot = p
		c_grid.grab_focus()

	func get_a() -> bool:
		return c_tool.cmode != CMode.CELL or not c_grid.pattern_top.cells.get_bit(p)

	func update() -> void:
		pass

	func end() -> void:
		if c_grid.is_sel:
			return
		c_grid.act_cells(c_tool.prev)
		c_grid.pattern_root.bitmap.save()

	func apply_mask() -> void:
		c_grid.pattern_top.cells.copy_from(c_tool.prev)
		c_grid.pattern_top.cells.op(c_tool.op, c_tool.mask)


class ToolPen:
	extends _Tool

	func _init(t: Tool) -> void:
		super(t)
		name = "pen"

	func get_a() -> bool:
		return not c_grid.pattern_top.cells.get_bit(p)

	func update() -> void:
		super()
		c_tool.mask.line(c_tool.pivot, p)
		apply_mask()
		c_tool.pivot = p


class ToolLine:
	extends _Tool

	func _init(t: Tool) -> void:
		super(t)
		name = "line"

	func update() -> void:
		super()
		c_tool.mask.fill(false)
		c_tool.mask.line(c_tool.pivot, p)
		apply_mask()


class ToolRect:
	extends _Tool

	func _init(t: Tool) -> void:
		super(t)
		name = "rect"

	func update() -> void:
		super()
		c_tool.mask.fill(false)
		c_tool.mask.rect(Rect2i(c_tool.pivot, p - c_tool.pivot).abs().grow_individual(0, 0, 1, 1))
		apply_mask()


class ToolMove:
	extends _Tool

	func _init(t: Tool) -> void:
		super(t)
		name = "move"

	func pre() -> void:
		c_grid.pattern_top.node.mouse_default_cursor_shape = Control.CURSOR_MOVE

	func update() -> void:
		super()
		c_grid.pattern_top.cells.copy_from(c_tool.prev)
		c_grid.pattern_top.cells.translate(p - c_tool.pivot)
