extends Node

var w_sizer := ReactiveProperty.new(0)
var r_w_sizer := w_sizer.to_readonly()

var w_item := ReactiveProperty.new(32)
var r_w_item := w_item.to_readonly()
var w_item_gap := ReactiveProperty.Computed1(r_w_item, func(w: int): return w + 1)

var w_table := ReactiveProperty.Computed2(
	r_w_sizer, w_item_gap, func(w: int, gw: int): return int(w / gw - 1) * gw + 1
)


func _ready() -> void:
	w_sizer.subscribe(func(w: int): print("sizer ", w))
