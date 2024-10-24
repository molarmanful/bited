extends Node

signal set_theme(theme: Theme)
signal apply_theme
signal set_font
signal set_thumb

var font_scale := 1:
	set(n):
		font_scale = n
		set_font.emit()
var font_scale_cor: int:
	get:
		return max(1, font_scale)
var font_size: int:
	get:
		return 16 * font_scale_cor

var thumb_scale := 3:
	set(n):
		thumb_scale = n
		set_thumb.emit()
var thumb_scale_cor: int:
	get:
		return maxi(1, thumb_scale)
var thumb_px_scale := 2:
	set(n):
		thumb_px_scale = n
		set_thumb.emit()
var thumb_px_scale_cor: int:
	get:
		return maxi(1, thumb_px_scale)
var thumb_size_pre: int:
	get:
		return 8 * thumb_scale_cor
var thumb_size: int:
	get:
		return thumb_size_pre * thumb_px_scale_cor
