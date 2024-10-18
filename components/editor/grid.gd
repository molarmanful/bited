class_name Grid
extends PanelContainer

@export var node_cells: TextureRect
@export var node_view_lines: SubViewport
@export var node_lines: Node2D
@export var tools_group: ButtonGroup
@export var cmode_group: ButtonGroup

var dim_grid := 32:
	set(n):
		dim_grid = n
		update_grid()
var w_cell := 16:
	set(n):
		w_cell = n
		update_grid()
var w_grid: int:
	get:
		return dim_grid * w_cell
var size_grid: Vector2i:
	get:
		return Vector2i(w_grid, w_grid)

var corner_bl: Vector2i:
	get:
		var center_grid := Vector2i(dim_grid, dim_grid) / 2
		var center_glyph := StateVars.font_size_calc * Vector2i(1, -1) / 2
		return center_grid - center_glyph

var origin: Vector2i:
	get:
		return corner_bl - Vector2i(0, StateVars.font.desc)

var cells := Image.create_empty(dim_grid, dim_grid, false, Image.FORMAT_LA8)
var tex_cells := ImageTexture.create_from_image(cells)

var toolman := Tool.new(self)
var tool_sel := "pen"

var to_update_cells := false
var pressed := false

var bitmap := Bitmap.new(self, -1, "test")


func _ready() -> void:
	bitmap.restore()
	node_cells.texture = tex_cells
	to_update_cells = true
	update_grid()

	theme_changed.connect(update_grid)
	gui_input.connect(oninput)
	tools_group.pressed.connect(func(btn: BaseButton): tool_sel = btn.name)
	cmode_group.pressed.connect(func(btn: BaseButton): toolman.cmode = Tool.CMode[btn.name])


func _process(_delta: float) -> void:
	toolman.tools[tool_sel].handle()
	update_cells()


func update_grid() -> void:
	node_cells.custom_minimum_size = size_grid
	node_cells.self_modulate = get_theme_color("fg")
	node_view_lines.size = size_grid
	node_lines.queue_redraw()


func update_cells() -> void:
	if not to_update_cells:
		return
	to_update_cells = false

	tex_cells.update(cells)


func oninput(e: InputEvent) -> void:
	if not (e is InputEventMouseButton or e is InputEventScreenTouch):
		return
	if (
		e is InputEventMouseButton
		and e.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_UP]
	):
		return

	pressed = e.pressed
	toolman.tools[tool_sel].handle(Tool.State.START if pressed else Tool.State.END)
