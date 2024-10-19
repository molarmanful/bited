extends PanelContainer

@export var table: Table
@export var editor: Editor

var grid: Grid


func _ready() -> void:
	grid = editor.grid

	StateVars.edit.connect(start_edit)


func start_edit(g: Glyph) -> void:
	grid.bitmap.data_code = g.data_code
	grid.bitmap.data_name = g.data_name
	grid.bitmap.clear_cells()
	grid.bitmap.save(false, false)
	grid.refresh()
