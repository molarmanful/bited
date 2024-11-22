class_name Bitmap
extends RefCounted

var dim := 0
var cells: Image
var data_code := -1
var data_name := ""

var dwidth := -1
var dwidth_calc: int:
	get:
		return StateVars.font.dwidth if dwidth < 0 else dwidth

var center: Vector2i:
	get:
		return Vector2i(dwidth_calc, -StateVars.font.bb.y) / 2
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


func save(over := true) -> void:
	var gen := to_gen()
	StateVars.font.save_glyph(gen, over)
	StateVars.refresh.emit(gen)


func save_dwidth() -> void:
	StateVars.db_saves.query_with_bindings(
		"update font_%s set dwidth = ? where name = ?;" % StateVars.font.id, [dwidth, data_name]
	)
	StateVars.refresh.emit(to_gen())


func load() -> void:
	(
		StateVars
		. db_saves
		. query_with_bindings(
			(
				"""
				select name, code, dwidth, bb_x, bb_y, off_x, off_y, img
				from font_%s
				where name = ?
				;"""
				% StateVars.font.id
			),
			[data_name]
		)
	)
	var qs := StateVars.db_saves.query_result
	if qs.is_empty():
		data_code = -1
		data_name = ""
		dwidth = -1
		return

	var gen := qs[0]
	StateVars.refresh.emit(gen)
	from_gen(gen)
	update_cells(gen)


func to_gen() -> Dictionary:
	var bounds := cells.get_used_rect()
	var bl := Vector2i(bounds.position.x, bounds.end.y)
	var off := (bl - origin) * Vector2i(1, -1) if bounds.size else bounds.size
	var img: PackedByteArray
	if bounds:
		img = Util.alpha_to_bits(cells.get_region(bounds))

	return {
		name = data_name,
		code = data_code,
		dwidth = dwidth,
		bb_x = bounds.size.x,
		bb_y = bounds.size.y,
		off_x = off.x,
		off_y = off.y,
		img = img,
	}


func from_gen(gen: Dictionary) -> void:
	data_name = gen.name
	data_code = gen.code
	dwidth = gen.dwidth


func clear_cells() -> void:
	cells.fill(Color.TRANSPARENT)


func update_cells(gen := to_gen()) -> void:
	clear_cells()
	from_gen(gen)
	if not gen.img:
		return

	var img := Util.bits_to_alpha(gen.img, gen.bb_x, gen.bb_y)
	var off := Vector2i(gen.off_x, -gen.off_y) + origin - Vector2i(0, gen.bb_y)
	cells.blit_rect(img, Rect2i(Vector2i.ZERO, Vector2i(gen.bb_x, gen.bb_y)), off)
