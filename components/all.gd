extends PanelContainer

@export var node_view: Container
@export var node_table: Node
@export var node_editor: Node


func _ready() -> void:
	node_view.remove_child(node_editor)
