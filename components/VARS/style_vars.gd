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
		return maxi(1, font_scale)
var font_size: int:
	get:
		return 16 * font_scale_cor
var thumb_px_size := 2:
	set(n):
		thumb_px_size = n
		set_thumb.emit()
var thumb_px_size_cor: int:
	get:
		return maxi(1, thumb_px_size)
var thumb_size_pre: int:
	get:
		return maxi(StateVars.font.bb.x, StateVars.font.bb.y) + 4
var thumb_size: int:
	get:
		return thumb_size_pre * thumb_px_size_cor
var thumb_size_cor: int:
	get:
		return maxi(32, thumb_size)


func _ready() -> void:
	thumb_px_size = StateVars.cfg.get_value("display", "table_cell_scale", 2)

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
