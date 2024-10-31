extends PanelContainer

@export var window: Window
@export var node_tabs: TabBar
@export var btn_save: Button
@export var btn_cancel: Button

var entries := ["general", "font"]
var tree_root: TreeItem


func _ready() -> void:
	window.about_to_popup.connect(load)
	window.close_requested.connect(window.hide)
	node_tabs.tab_changed.connect(select)
	btn_save.pressed.connect(save)
	btn_cancel.pressed.connect(window.hide)


func select(tab: int) -> void:
	for child in get_tree().get_nodes_in_group("entry"):
		if child.name == entries[tab]:
			child.show()
			continue
		child.hide()


# TODO: validation
func save() -> void:
	for entry in entries:
		for child in get_tree().get_nodes_in_group(entry):
			child.save()
	StateVars.settings.emit()
	window.hide()


func load() -> void:
	for entry in entries:
		for child in get_tree().get_nodes_in_group(entry):
			child.load()
