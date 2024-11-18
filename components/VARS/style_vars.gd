extends Node
## Global state and signal bus for style-related data.

## Emits when theme changes.
signal theme_changed
## Emits when font styling (e.g. size) changes.
signal set_font
## Emits when thumbnail styling (e.g. size) changes.
signal set_thumb

const ThemeDark := preload("res://components/dark.tres")
const ThemeLight := preload("res://components/light.tres")

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


func _ready() -> void:
	refresh_theme()

	StateVars.settings.connect(refresh_theme)


func refresh_theme() -> void:
	var t: int = StateVars.cfg.get_value("display", "theme", 0)
	var theme: Theme
	match t:
		1:
			theme = ThemeLight
		2:
			theme = ThemeDark
		_:
			theme = ThemeDark if DisplayServer.is_dark_mode() else ThemeLight

	StateVars.root.set_theme(theme)
	theme_changed.emit()
