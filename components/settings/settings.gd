extends PanelContainer

@export var window: Window
@export var node_tabs: TabBar
@export var btn_save: Button
@export var btn_save_close: Button
@export var btn_cancel: Button

var tree_root: TreeItem
@onready var entries := get_tree().get_nodes_in_group("entry").map(func(x: Node): return x.name)


func _ready() -> void:
	select(0)

	for entry in entries:
		for child in get_tree().get_nodes_in_group(entry):
			if child.has_method("validate"):
				child.f = func(ok: bool):
					if ok:
						btn_save.show()
						btn_save_close.show()
					else:
						btn_save.hide()
						btn_save_close.hide()

	window.about_to_popup.connect(load)
	window.close_requested.connect(window.hide)
	node_tabs.tab_changed.connect(select)
	btn_save.pressed.connect(save)
	btn_save_close.pressed.connect(
		func():
			save()
			window.hide()
	)
	btn_cancel.pressed.connect(window.hide)


func select(tab: int) -> void:
	for child in get_tree().get_nodes_in_group("entry"):
		if child.name == entries[tab]:
			child.show()
			continue
		child.hide()


func is_valid() -> bool:
	for entry in entries:
		for child in get_tree().get_nodes_in_group(entry):
			if child.has_method("validate") and child.validate():
				btn_save.hide()
				btn_save_close.hide()
				return false
	btn_save.show()
	btn_save_close.show()
	return true


func save() -> void:
	if not is_valid():
		return

	for entry in entries:
		for child in get_tree().get_nodes_in_group(entry):
			child.save()
	StateVars.font.save_font()
	StateVars.cfg.save("user://settings.ini")
	StateVars.settings.emit()


func load() -> void:
	for entry in entries:
		for child in get_tree().get_nodes_in_group(entry):
			child.load()

	is_valid()
