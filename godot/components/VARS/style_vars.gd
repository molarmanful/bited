extends Node
## Global state and signal bus for style-related data.

## Emits when theme changes.
signal theme_changed
## Emits when thumbnail styling (e.g. size) changes.
signal set_thumb
## Emits when grid styling (e.g. size) changes.
signal set_grid

const THEMES := ["dark", "light"]

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
		return (
			4
			+ maxi(
				maxi(StateVars.font.bb.x, StateVars.font.bb.y),
				maxi(fb.dwidth, maxi(fb.bb_x, fb.bb_y))
			)
		)
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
	var x := clampi(StateVars.cfg.get_value("display", "scale", 1), 1, 3)
	get_tree().root.content_scale_factor = x

	for win in get_tree().get_nodes_in_group("win_scale"):
		win.content_scale_factor = x

	var t: String = StateVars.cfg.get_value("display", "theme", "system")
	var theme := t if THEMES.has(t) else "dark" if DisplayServer.is_dark_mode() else "light"

	StateVars.root.set_theme(load("res://components/themes/%s.tres" % theme))
	theme_changed.emit()
