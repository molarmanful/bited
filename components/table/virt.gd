class_name Virt
extends Resource

signal refresh

var length := 0:
	set(n):
		length = maxi(0, n)
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
		v_scroll = mini(n, rows * size_item_gap.y - h_view)
		refresh.emit()

var w_item: int:
	get:
		return StyleVars.thumb_size_cor
var h_item: int:
	get:
		return 25 + w_item
var size_item: Vector2i:
	get:
		return Vector2i(w_item, h_item)
var size_item_gap: Vector2i:
	get:
		return size_item + Vector2i.ONE

var cols: int:
	get:
		return maxi(1, w_sizer / size_item_gap.x - 1)
var rows: int:
	get:
		return ceil(length / float(cols))
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
		return maxi(0, row_top - rows_off)
var row1: int:
	get:
		return mini(rows, row_bottom + rows_off)

var len_ideal: int:
	get:
		return row1 * cols - i0
var i0: int:
	get:
		return row0 * cols
var i1: int:
	get:
		return mini(length, row1 * cols)

var pad_top: int:
	get:
		return row0 * size_item_gap.y
