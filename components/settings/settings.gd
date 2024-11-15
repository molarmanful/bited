extends PanelContainer

@export var window: Window
@export var win_add_prop: WinAddProp
@export var node_tabs: TabBar
@export var node_props: Container
@export var btn_add_prop: Button
@export var btn_save: Button
@export var btn_save_close: Button
@export var btn_cancel: Button

var props := {}

var tree_root: TreeItem
@onready var entries := get_tree().get_nodes_in_group("entry").map(func(x: Node): return x.name)


func _ready() -> void:
	select(node_tabs.current_tab)

	for child in get_tree().get_nodes_in_group("settings"):
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
	btn_add_prop.pressed.connect(add_prop)
	btn_save.pressed.connect(save)
	btn_save_close.pressed.connect(
		func():
			save()
			window.hide()
	)
	btn_cancel.pressed.connect(window.hide)


func save() -> void:
	if not is_valid():
		return

	for child in get_tree().get_nodes_in_group("settings"):
		child.save()

	for prop in node_props.get_children():
		prop.save()

	StateVars.font.props.clear()
	StateVars.font.props.merge(props)
	StateVars.font.save_font()
	StateVars.cfg.save("user://settings.ini")
	StateVars.settings.emit()


func load() -> void:
	load_props()

	for child in get_tree().get_nodes_in_group("settings"):
		child.load()

	is_valid()


func select(tab: int) -> void:
	for child in get_tree().get_nodes_in_group("entry"):
		if child.name == entries[tab]:
			child.show()
			continue
		child.hide()


func is_valid() -> bool:
	for child in get_tree().get_nodes_in_group("settings"):
		if child.has_method("validate") and child.validate():
			btn_save.hide()
			btn_save_close.hide()
			return false
	btn_save.show()
	btn_save_close.show()
	return true


func load_props() -> void:
	props.clear()
	props.merge(StateVars.font.props)
	refresh_props()


func refresh_props() -> void:
	var len_props := node_props.get_child_count()

	while len_props < props.size():
		var prop := FontProp.create(props)
		node_props.add_child(prop)
		len_props += 1

	while len_props > props.size():
		var prop := node_props.get_child(-1)
		node_props.remove_child(prop)
		prop.queue_free()
		len_props -= 1

	var i := 0
	for k in props:
		var prop := node_props.get_child(i)
		prop.key = k
		prop.load()
		i += 1


func add_prop() -> void:
	var ok := await win_add_prop.add(props)
	if not ok:
		return

	props[win_add_prop.prop_val.text] = ""
	refresh_props()
