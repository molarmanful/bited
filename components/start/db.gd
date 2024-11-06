extends PanelContainer

@export var window: Window
@export var btn_start: Button
@export var btn_cancel: Button
@export var tree: Tree


func _ready() -> void:
	window.about_to_popup.connect(build_tree)
	window.close_requested.connect(window.hide)
	tree.item_selected.connect(btn_start.show)
	tree.item_activated.connect(start)
	btn_start.pressed.connect(start)
	btn_cancel.pressed.connect(window.hide)


func build_tree() -> void:
	btn_start.hide()
	tree.clear()
	tree.create_item()

	var qs := StateVars.db_saves.select_rows("fonts", "", ["id", "data"])
	for q in qs:
		var x := tree.create_item()
		var data: Dictionary = bytes_to_var(q.data)
		x.set_text(0, q.id)
		x.set_text(1, "%s %s %d\u00d7%d" % [data.family, data.weight, data.bb.x, data.bb.y])


func start() -> void:
	var sel := tree.get_selected()
	if not sel:
		return

	StateVars.font.id = tree.get_selected().get_text(0)
	StateVars.font.init_font(true)

	window.hide()
	StateVars.start_all()
