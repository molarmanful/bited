class_name Pattern
extends RefCounted

var dim_grid: int:
	get:
		return StyleVars.grid_size_cor

var node: TextureRect
var tex: ImageTexture
var dirty := false
var bitmap: Bitmap
var cells: BitGlyph:
	get:
		return bitmap.cells
	set(c):
		bitmap.cells = c


func _init(r: TextureRect) -> void:
	node = r
	bitmap = Bitmap.new(dim_grid)
	tex = ImageTexture.create_from_image(cells.to_image())


func clear() -> void:
	cells = BitGlyph.create(Vector2i(dim_grid, dim_grid))
	tex.set_image(cells.to_image())


func update_tex() -> void:
	if not dirty:
		return
	dirty = false
	tex.update(cells.to_image())


func update_node() -> void:
	node.texture = tex
