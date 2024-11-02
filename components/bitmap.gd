class_name Bitmap
extends Node

var dim := 0
var cells: Image
var data_code := -1
var data_name := ""
var dwidth := StateVars.font.dwidth

var center: Vector2i:
	get:
		return Vector2i(dwidth, -StateVars.font.bb.y) / 2
var corner_bl: Vector2i:
	get:
		var center_img := Vector2i(dim, dim) / 2
		return center_img - center
var origin: Vector2i:
	get:
		return corner_bl - Vector2i(0, StateVars.font.desc)


func _init(
	d: int, cs := Image.create_empty(d, d, false, Image.FORMAT_LA8), dc := -1, dn := &""
) -> void:
	dim = d
	cells = cs
	data_code = dc
	data_name = dn


func save(over := true) -> bool:
	var bounds := cells.get_used_rect()
	var bl := Vector2i(bounds.position.x, bounds.end.y)
	var off := (bl - origin) * Vector2i(1, -1) if bounds.size else bounds.size
	var img: PackedByteArray
	if bounds:
		img = Util.alpha_to_bits(cells.get_region(bounds))

	var gen := {
		name = data_name,
		code = data_code,
		dwidth = dwidth,
		bb_x = bounds.size.x,
		bb_y = bounds.size.y,
		off_x = off.x,
		off_y = off.y,
		img = img,
	}
	StateVars.refresh.emit(gen)

	return StateVars.font.save_glyph(gen, over)


func load() -> void:
	var q: Array[Dictionary] = StateVars.db_saves.select_rows(
		"font_" + StateVars.font.id,
		"name = %s" % JSON.stringify(data_name),
		["name", "code", "dwidth", "bb_x", "bb_y", "off_x", "off_y", "img"]
	)
	if q.is_empty():
		data_code = -1
		data_name = ""
		return

	var gen := q[0]
	StateVars.refresh.emit(gen)
	from_gen(gen)
	update_cells(gen)


func from_gen(gen: Dictionary) -> void:
	data_name = gen.name
	data_code = gen.code
	dwidth = gen.dwidth


func clear_cells() -> void:
	cells.fill(Color.TRANSPARENT)


func update_cells(gen: Dictionary) -> void:
	clear_cells()
	from_gen(gen)
	if not gen.img:
		return

	var img := Util.bits_to_alpha(gen.img, gen.bb_x, gen.bb_y)
	var off := Vector2i(gen.off_x, -gen.off_y) + origin - Vector2i(0, gen.bb_y)
	cells.blit_rect(img, Rect2i(Vector2i.ZERO, Vector2i(gen.bb_x, gen.bb_y)), off)
