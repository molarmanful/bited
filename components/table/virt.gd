class_name Virt
extends Resource

var w_sizer := RX.state(0)
var r_w_sizer := w_sizer.to_readonly()

var w_item := RX.state(32)
var r_w_item := w_item.to_readonly()
var w_item_gap := ReactiveProperty.Computed1(r_w_item, func(w: int): return w + 1)

var cols := RX.derived2(r_w_sizer, w_item_gap, func(w: int, gw: int): return w / gw - 1)

var w_table := RX.derived2(cols, w_item_gap, func(cs: int, gw: int): return cs * gw + 1)
