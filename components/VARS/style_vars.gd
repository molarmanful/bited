extends Node

var font_scale := RX.state(1)
var r_font_scale := font_scale.to_readonly()
var font_scale_cor := RX.derived1(r_font_scale, func(n: int): return maxi(1, n))
var font_size := RX.derived1(font_scale_cor, func(n: int): return 16 * n)

var thumb_scale := RX.state(3)
var r_thumb_scale := thumb_scale.to_readonly()
var thumb_scale_cor := RX.derived1(r_thumb_scale, func(n: int): return maxi(1, n))

var thumb_px_scale := RX.state(2)
var r_thumb_px_scale := thumb_px_scale.to_readonly()
var thumb_px_scale_cor := RX.derived1(r_thumb_px_scale, func(n: int): return maxi(1, n))
