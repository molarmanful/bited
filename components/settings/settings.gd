extends PanelContainer

@export var window: Window
@export var node_tree: Tree


func _ready() -> void:
	window.force_native = true
	build_tree()

	window.close_requested.connect(window.hide)


func build_tree() -> void:
	var root := node_tree.create_item()

	for i in 100:
		var item := root.create_child()
		item.set_text(0, "testing testing %d" % i)
