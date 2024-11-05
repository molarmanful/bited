extends PanelContainer

@export var node_start: Container
@export var node_body: Container
@export var table: Table
@export var editor: Editor

var grid: Grid


func _ready() -> void:
	grid = editor.grid

	node_body.hide()
	node_start.show()


func act_new() -> void:
	pass


func act_db() -> void:
	pass


func act_bdf() -> void:
	pass
