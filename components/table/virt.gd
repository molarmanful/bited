class_name Virt
extends Resource

var length := RX.state(2048)
var r_length := length.to_readonly()

var w_sizer := RX.state(0)
var r_w_sizer := w_sizer.to_readonly()

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
