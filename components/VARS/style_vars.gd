extends Node
## Global state and signal bus for style-related data.

## Emits when theme changes.
signal theme_changed
## Emits when thumbnail styling (e.g. size) changes.
signal set_thumb
## Emits when grid styling (e.g. size) changes.
signal set_grid

const ThemeDark := preload("res://components/dark.tres")
const ThemeLight := preload("res://components/light.tres")

var table_width := -16:
	set(n):
		table_width = n
		StyleVars.set_thumb.emit()
var thumb_px_size := 2:
	set(n):
		thumb_px_size = n
		StyleVars.set_thumb.emit()
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

var grid_size := 32:
	set(n):
		grid_size = n
		set_grid.emit()
var grid_px_size := 12:
	set(n):
		grid_px_size = n
		set_grid.emit()
var grid_size_min: int:
	get:
		var fb := StateVars.font.fbbx()
		return maxi(maxi(fb.bb_x, fb.bb_y), maxi(StateVars.font.bb.x, StateVars.font.bb.y)) + 4
var grid_size_cor: int:
	get:
		return maxi(grid_size_min, grid_size)
var grid_px_size_cor: int:
	get:
		return maxi(4, grid_px_size)


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
