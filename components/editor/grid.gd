extends PanelContainer

@export var node_cells: TextureRect
@export var node_tiles: Node2D

var size_grid := 32:
	set(n):
		size_grid = n
		update_size()
var size_cell := 12:
	set(n):
		size_cell = n
		update_size()
var cells := Image.create_empty(size_grid, size_grid, false, Image.FORMAT_LA8)
var tex_cells := ImageTexture.create_from_image(cells)

var to_update_cells := false


func _ready() -> void:
	node_cells.texture = tex_cells
	cells.set_pixel(0, 0, Color.WHITE)
	cells.set_pixel(2, 2, Color.WHITE)
	to_update_cells = true
	update_size()


func _process(_delta: float) -> void:
	update_cells()


func update_size() -> void:
	var sz := size_grid * size_cell
	node_cells.custom_minimum_size = Vector2(sz, sz)


func update_cells() -> void:
	if not to_update_cells:
		return
	to_update_cells = false

	tex_cells.update(cells)
