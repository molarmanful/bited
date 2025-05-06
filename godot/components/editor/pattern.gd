class_name Pattern
extends RefCounted

var dim_grid: int:
	get:
		return StyleVars.grid_size_cor

var node: TextureRect
var cells: Image
var tex: ImageTexture
var bitmap: Bitmap


func _init(r: TextureRect) -> void:
	node = r
	cells = Util.blank_img(dim_grid)
	tex = ImageTexture.create_from_image(cells)
	bitmap = Bitmap.new(dim_grid, cells)


func clear() -> void:
	bitmap.dim = dim_grid
	cells.copy_from(Util.blank_img(dim_grid))
	tex.set_image(cells)


func update_tex() -> void:
	tex.update(cells)


func update_node() -> void:
	node.texture = tex
