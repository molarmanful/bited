class_name Virt
extends Resource

signal refresh

var thumbs := {}

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
