class_name Virt
extends Resource

signal refresh

var length := 65536:
	set(n):
		length = n
		refresh.emit()
var w_sizer := 0:
	set(n):
		w_sizer = n
		refresh.emit()
var h_view := 0:
	set(n):
		h_view = n
		refresh.emit()
var v_scroll := 0:
	set(n):
		v_scroll = n
		refresh.emit()

var w_item: int:
	get:
		return StyleVars.thumb_size
var h_item: int:
	get:
		return 9 + StyleVars.font_size + w_item
var size_item: Vector2i:
	get:
		return Vector2i(w_item, h_item)
var size_item_gap: Vector2i:
	get:
		return size_item + Vector2i.ONE

var cols: int:
	get:
		return w_sizer / size_item_gap.x - 1
var rows: int:
	get:
		return int(ceil(length / float(cols)))
var dims: Vector2i:
	get:
		return Vector2i(cols, rows)

var size_table: Vector2i:
	get:
		return dims * size_item_gap + Vector2i.ONE

var rows_view: int:
	get:
		return h_view / size_item_gap.y
var rows_off: int:
	get:
		return 1
var row_top: int:
	get:
		return v_scroll / size_item_gap.y
var row_bottom: int:
	get:
		return row_top + rows_view
var row0: int:
	get:
		return max(0, row_top - rows_off)
var row1: int:
	get:
		return min(rows, row_bottom + rows_off)

var len_ideal: int:
	get:
		return row1 * cols - i0
var i0: int:
	get:
		return row0 * cols
var i1: int:
	get:
		return min(length, row1 * cols)

var pad_top: int:
	get:
		return row0 * size_item_gap.y

var corner_bl: Vector2i:
	get:
		var center_grid := Vector2i(StyleVars.thumb_size_pre, StyleVars.thumb_size_pre) / 2
		return center_grid - StateVars.font_center
var origin: Vector2i:
	get:
		return corner_bl - Vector2i(0, StateVars.font.desc)

var thumbs := {}


func update_imgs(gs: Array[Glyph]) -> void:
	var names: Array[String] = []
	var qs: Array[String] = []
	for g in gs:
		names.push_back(g.data_name)
		qs.push_back("?")

	var q := (
		"""
		select name, code, off_x, off_y, img from font_%s
		where name in (%s)
		"""
		% [StateVars.font.id, ",".join(qs)]
	)
	var suc := StateVars.db_saves.query_with_bindings(q, names)
	if not suc:
		return

	for r in StateVars.db_saves.query_result:
		var s := StyleVars.thumb_size_pre
		var sz := Vector2(s, s)
		var img_wrap := Image.create_empty(s, s, false, Image.FORMAT_LA8)
		if r.img:
			var img := Image.create_empty(1, 1, false, Image.FORMAT_LA8)
			img.load_png_from_buffer(r.img)
			var off := Vector2i(r.off_x, -r.off_y) + origin - Vector2i(0, img.get_size().y)
			img_wrap.blit_rect(img, Rect2i(Vector2i.ZERO, sz), off)
		img_wrap.resize(StyleVars.thumb_size, StyleVars.thumb_size, Image.INTERPOLATE_NEAREST)
		thumbs[r.name] = ImageTexture.create_from_image(img_wrap)
