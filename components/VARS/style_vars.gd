extends Node

var font_scale := ReactiveProperty.new(1)
var r_font_scale := font_scale.to_readonly()
var font_size := ReactiveProperty.Computed1(r_font_scale, func(n: int): return 16 * max(1, n))
