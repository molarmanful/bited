extends Window

@export var node_tree: Tree


func _init() -> void:
	hide()
	force_native = true


func _ready() -> void:
	build_tree()

	close_requested.connect(hide)


func build_tree() -> void:
	var root := node_tree.create_item()

	for i in 100:
		var item := root.create_child()
		item.set_text(0, "testing testing %d" % i)
