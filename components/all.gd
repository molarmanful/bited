extends PanelContainer

@export var node_view: Container
@export var table: Table
@export var editor: Editor

var grid: Grid


func _ready() -> void:
	grid = editor.grid
	node_view.remove_child(editor)

	StateVars.table.connect(show_table)
	StateVars.edit.connect(show_editor)


func show_table() -> void:
	node_view.remove_child(editor)
	editor.process_mode = PROCESS_MODE_DISABLED
	table.process_mode = PROCESS_MODE_INHERIT
	node_view.add_child(table)


func show_editor(g: Glyph) -> void:
	grid.bitmap = Bitmap.new(grid, g.data_code, g.data_name)
	grid.bitmap.save(false)
	node_view.remove_child(table)
	table.process_mode = PROCESS_MODE_DISABLED
	editor.process_mode = PROCESS_MODE_INHERIT
	node_view.add_child(editor)
