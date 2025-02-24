class_name PgDB
extends PanelContainer

@export var pg_x: Container
@export var pg_del_warn: PgDelWarn
@export var pg_rename: PgRename

@export var tree: Tree
@export var placeholder: Control

@export var btn_start: Button
@export var btn_cancel: Button
@export var btn_del: Button
@export var btn_rename: Button


func _ready() -> void:
	hide()

	tree.item_selected.connect(onselect)
	tree.item_activated.connect(start)
	btn_start.pressed.connect(start)
	btn_cancel.pressed.connect(
		func():
			hide()
			pg_x.show()
	)
	btn_del.pressed.connect(del)
	btn_rename.pressed.connect(rename)


func begin() -> void:
	build_tree()


func build_tree() -> void:
	btn_start.hide()
	btn_del.hide()
	btn_rename.hide()

	var qs := StateVars.db_saves.select_rows("fonts", "", ["id", "data"])
	if not qs:
		tree.hide()
		placeholder.show()
	else:
		placeholder.hide()
		tree.show()

		tree.clear()
		tree.create_item()
		for q in qs:
			var x := tree.create_item()
			var data: Dictionary = bytes_to_var(q.data)
			x.set_text(0, q.id)
			x.set_text(
				1,
				(
					"%s %s %d\u00d7%d"
					% [data.family, data.weight, data.bb.x, data.bb.y]
				)
			)

	show()
	tree.grab_focus()


func onselect() -> void:
	btn_start.show()
	btn_del.show()
	btn_rename.show()


func start() -> void:
	var sel := tree.get_selected()
	if not sel:
		return
	var id := sel.get_text(0)

	StateVars.font.id = id
	StateVars.font.init_font(true)

	hide()
	StateVars.start_all()


func del() -> void:
	var sel := tree.get_selected()
	if not sel:
		return
	var id := sel.get_text(0)

	hide()
	var ok := await pg_del_warn.warn(id)
	if ok:
		StateVars.delete_font(id)
	build_tree()


func rename() -> void:
	var sel := tree.get_selected()
	if not sel:
		return
	var id := sel.get_text(0)

	hide()
	pg_rename.begin(id)
