class_name Bitmap
extends Node

var grid: Grid
var data_code := -1
var data_name := ""
var dwidth: Vector2i = StateVars.font.dwidth
var dwidth1: Vector2i = StateVars.font.dwidth1
var vvector: Vector2i = StateVars.font.vvector


func _init(g: Grid, dc := -1, dn := &"") -> void:
	grid = g
	data_code = dc
	data_name = dn


func save() -> bool:
	var bounds := grid.cells.get_used_rect()
	var bl := Vector2i(bounds.position.x, bounds.end.y)
	var off := (bl - grid.origin) * Vector2i(1, -1) if bounds.size else bounds.size
	var img: PackedByteArray
	if bounds:
		img = grid.cells.get_region(bounds).save_png_to_buffer()

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

	return (
		StateVars
		. db_saves
		. query_with_bindings(
			(
				"""
				insert or replace into font_%s
				(name, code, dwidth_x, dwidth_y, dwidth1_x, dwidth1_y, vvector_x, vvector_y, off_x, off_y, img)
				values
				(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
				"""
				% StateVars.font.id
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
	data_name = gen.name
	data_code = gen.code
	dwidth = Vector2i(gen.dwidth_x, gen.dwidth_y)
	dwidth1 = Vector2i(gen.dwidth1_x, gen.dwidth1_y)
	vvector = Vector2i(gen.vvector_x, gen.vvector_y)

	if gen.img:
		var img := Image.create_empty(1, 1, false, Image.FORMAT_LA8)
		img.load_png_from_buffer(gen.img)
		var sz := img.get_size()
		var off := Vector2i(gen.off_x, -gen.off_y) + grid.origin - Vector2i(0, sz.y)
		grid.cells.blit_rect(img, Rect2i(Vector2i.ZERO, sz), off)
