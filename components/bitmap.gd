class_name Bitmap
extends Node

var dim := 0
var cells: Image
var data_code := -1
var data_name := ""
var dwidth: Vector2i = StateVars.font.dwidth
var dwidth1: Vector2i = StateVars.font.dwidth1
var vvector: Vector2i = StateVars.font.vvector

var corner_bl: Vector2i:
	get:
		var center := Vector2i(dim, dim) / 2
		return center - StateVars.font.center
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
		img = cells.get_region(bounds).save_png_to_buffer()

	var gen := {
		name = data_name,
		code = data_code,
		dwidth_x = dwidth.x,
		dwidth_y = dwidth.y,
		dwidth1_x = dwidth1.x,
		dwidth1_y = dwidth1.y,
		vvector_x = vvector.x,
		vvector_y = vvector.y,
		off_x = off.x,
		off_y = off.y,
		img = img,
	}
	StateVars.refresh.emit(gen)

	return (
		StateVars
		. db_saves
		. query_with_bindings(
			(
				"""
				insert or %s
				into font_%s
				(name, code, dwidth_x, dwidth_y, dwidth1_x, dwidth1_y, vvector_x, vvector_y, off_x, off_y, img)
				values
				(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
				;"""
				% ["replace" if over else "ignore", StateVars.font.id]
			),
			gen.values()
		)
	)


func restore() -> void:
	var q := StateVars.db_saves.select_rows(
		"font_" + StateVars.font.id,
		"name = %s" % JSON.stringify(data_name),
		[
			"name",
			"code",
			"dwidth_x",
			"dwidth_y",
			"dwidth1_x",
			"dwidth1_y",
			"vvector_x",
			"vvector_y",
			"off_x",
			"off_y",
			"img"
		]
	)
	if not q.size():
		return

	var gen: Dictionary = q[0]
	from_gen(gen)
	update_cells(gen)


func from_gen(gen: Dictionary) -> void:
	data_name = gen.name
	data_code = gen.code
	dwidth = Vector2i(gen.dwidth_x, gen.dwidth_y)
	dwidth1 = Vector2i(gen.dwidth1_x, gen.dwidth1_y)
	vvector = Vector2i(gen.vvector_x, gen.vvector_y)


func clear_cells() -> void:
	cells.fill(Color.TRANSPARENT)


func update_cells(gen: Dictionary) -> void:
	clear_cells()
	if not gen.img:
		return

	var img := Image.create_empty(1, 1, false, Image.FORMAT_LA8)
	img.load_png_from_buffer(gen.img)
	var sz := img.get_size()
	var off := Vector2i(gen.off_x, -gen.off_y) + origin - Vector2i(0, sz.y)
	cells.blit_rect(img, Rect2i(Vector2i.ZERO, sz), off)
