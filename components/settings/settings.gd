extends PanelContainer

@export var window: Window
@export var node_tree: Tree
@export var btn_save: Button
@export var btn_cancel: Button


func _ready() -> void:
	window.force_native = true
	build_tree()

	window.about_to_popup.connect(restore)
	window.close_requested.connect(window.hide)
	btn_cancel.pressed.connect(window.hide)


func build_tree() -> void:
	var root := node_tree.create_item()

	for i in 100:
		var item := root.create_child()
		item.set_text(0, "testing testing %d" % i)


func save() -> void:
	for child in get_tree().get_nodes_in_group("font"):
		child.save()


func restore() -> void:
	for child in get_tree().get_nodes_in_group("font"):
		child.restore()
