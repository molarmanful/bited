extends PanelContainer

@export var table: Table
@export var editor: Editor

var grid: Grid


func _ready() -> void:
	grid = editor.grid
