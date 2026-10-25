class_name Layers
extends Window

@export var editor: Editor
@export var btn: Button
@export var tree: DragTree

@export var btn_pick: Button

var grid: Grid:
	get:
		return editor.grid
var table: Table:
	get:
		return editor.table

var parent_name: String:
	get:
		return grid.pattern.bitmap.data_name


func _ready() -> void:
	grid.refreshed.connect(refresh)

	visibility_changed.connect(func(): btn.set_pressed_no_signal(visible))
	close_requested.connect(
		func():
			btn_pick.button_pressed = false
			hide()
	)

	btn.toggled.connect(
		func(on: bool):
			if on:
				var pos := btn.get_screen_transform() * Vector2(0, btn.size.y)
				pos.y += 4 + get_theme_constant("title_height")
				popup(Rect2i(pos, size))
			else:
				close_requested.emit()
	)

	btn_pick.toggled.connect(func(on: bool): table.pick_layer = on)


func pick(gname: String) -> void:
	(
		StateVars
		. db_saves
		. query_with_bindings(
			(
				"""
				with recursive
					up(name) as (
						select ?1
						union
						select l.parent
						from layers_{0} as l
						join up on l.child = up.name
					)
				insert into layers_{0} (parent, child, ord)
				select ?1, ?2, (select coalesce(max(ord), -1) + 1 from layers_{0} where parent = ?1)
				where ?2 not in (select name from up)
				;"""
				. format([StateVars.font.id])
			),
			[parent_name, gname]
		)
	)

	StateVars.font.flatten(parent_name)
	StateVars.font.flatten_parents([parent_name])
	grid.refresh()


func refresh() -> void:
	tree.clear()
	tree.create_item()

	(
		StateVars
		. db_saves
		. query_with_bindings(
			(
				"""
				select
					c.name, c.code, c.dwidth, c.is_abs, c.bb_x, c.bb_y,
					c.off_x + l.off_x as off_x, c.off_y + l.off_y as off_y,
					c.img
				from layers_{0} as l
				join font_{0} as c on l.child = c.name
				where l.parent = ?
				order by l.ord
				;"""
				. format([StateVars.font.id])
			),
			[parent_name]
		)
	)

	var qs := StateVars.db_saves.query_result
	grid.get_tree().call_group("hide_if_layer", "show" if qs.is_empty() else "hide")
	for q in qs:
		add_item(q)


func add_item(gen: Dictionary) -> void:
	var item := tree.create_item(null, 0)
	item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
	# item.set_icon(0, grid.pattern.tex)
	item.set_text(0, ("U+" if gen.code >= 0 else "") + gen.name)
	item.add_button(0, grid.cmode_group.get_buttons()[Tool.CMode.INV].icon)
