class_name Grid
extends PanelContainer

@export var node_cells: TextureRect
@export var node_view_lines: SubViewport
@export var node_lines: Node2D

var dim_grid := 32:
	set(n):
		dim_grid = n
		update_size()
var w_cell := 16:
	set(n):
		w_cell = n
		update_size()
var w_grid: int:
	get:
		return dim_grid * w_cell
var size_grid: Vector2i:
	get:
		return Vector2i(w_grid, w_grid)

var cells := Image.create_empty(dim_grid, dim_grid, false, Image.FORMAT_LA8)
var tex_cells := ImageTexture.create_from_image(cells)

var gtool := Tool.new(self)
var tool_cur := "pen"

var to_update_cells := false
var pressed := false


func _ready() -> void:
	node_cells.texture = tex_cells
	to_update_cells = true
	update_size()

	gui_input.connect(oninput)


func _process(_delta: float) -> void:
	gtool[tool_cur].call()
	update_cells()


func update_size() -> void:
	# TODO: find better place for this?
	node_cells.self_modulate = get_theme_color("fg")
	node_cells.custom_minimum_size = size_grid
	node_view_lines.size = size_grid
	update_lines()


func update_lines() -> void:
	node_lines.w_cell = w_cell
	node_lines.w_grid = w_grid
	node_lines.color = get_theme_color("bord")
	node_lines.queue_redraw()


func update_cells() -> void:
	if not to_update_cells:
		return
	to_update_cells = false

	tex_cells.update(cells)


func oninput(e: InputEvent) -> void:
	if not (e is InputEventMouseButton or e is InputEventScreenTouch):
		return

	pressed = e.pressed
	if pressed:
		gtool[tool_cur].call(Tool.START)
	else:
		gtool[tool_cur].call(Tool.END)
