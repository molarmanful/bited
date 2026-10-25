extends PanelContainer

@export var node_body: Container
@export var table: Table
@export var editor: Editor


func _ready() -> void:
	StyleVars.refresh_theme()
