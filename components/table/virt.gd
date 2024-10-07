class_name Virt
extends Resource

var length := RX.state(2048)
var r_length := length.to_readonly()
var w_sizer := RX.state(0)
var r_w_sizer := w_sizer.to_readonly()
var h_view := RX.state(0)
var r_h_view := h_view.to_readonly()
var v_scroll := RX.state(0)
var r_v_scroll := v_scroll.to_readonly()

var w_item := RX.derived2(
	StyleVars.thumb_scale_cor, StyleVars.thumb_px_scale_cor, func(n: int, m: int): return 8 * n * m
)
var h_item = RX.derived2(StyleVars.font_size, w_item, func(fsz: int, w: int): return 9 + fsz + w)
var size_item = RX.derived2(w_item, h_item, func(w: int, h: int): return Vector2i(w, h))
var size_item_gap := RX.derived1(size_item, func(sz: Vector2i): return sz + Vector2i(1, 1))

var cols := RX.derived2(r_w_sizer, size_item_gap, func(w: int, gsz: Vector2i): return w / gsz.x - 1)
var rows := RX.derived2(r_length, cols, func(l: int, cs: int): return int(ceil(l / float(cs))))
var dims := RX.derived2(cols, rows, func(cs: int, rs: int): return Vector2i(cs, rs))

var size_table := RX.derived2(
	dims, size_item_gap, func(ds: Vector2i, gsz: Vector2i): return ds * gsz + Vector2i(1, 1)
)

var rows_view := RX.derived2(r_h_view, size_item_gap, func(h: int, gsz: Vector2i): return h / gsz.y)
var rows_off := RX.derived1(rows_view, func(d: int): return 0)
var row_top := RX.derived2(r_v_scroll, size_item_gap, func(v: int, gsz: Vector2i): return v / gsz.y)
var row_bottom := RX.derived2(row_top, rows_view, func(t: int, d: int): return t + d)
var row0 := RX.derived2(row_top, rows_off, func(t: int, o: int): return max(0, t - o))
var row1 := RX.derived3(
	rows, row_bottom, rows_off, func(rs: int, b: int, o: int): return min(rs, b + o)
)

var i0 := RX.derived2(row0, cols, func(r0: int, cs: int): return r0 * cs)
var i1 := RX.derived3(r_length, row1, cols, func(l: int, r1: int, cs: int): return min(l, r1 * cs))

var pad_top := RX.derived2(row0, size_item_gap, func(r0: int, gsz: Vector2i): return r0 * gsz.y)
