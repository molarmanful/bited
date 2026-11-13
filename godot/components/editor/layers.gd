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
var has_layers := false

var selected: PackedInt32Array:
	get:
		var res: PackedInt32Array
		var item := tree.get_next_selected(null)
		while item:
			res.push_back(item.get_metadata(0).ord)
			item = tree.get_next_selected(item)
		return res


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
	tree.multi_selected.connect(sync_cmode.unbind(3), CONNECT_DEFERRED)


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
	flatten()


func translate(v: Vector2i) -> void:
	(
		StateVars
		. db_saves
		. query_with_bindings(
			(
				"""
				update layers_{0}
				set off_x = off_x + ?1, off_y = off_y - ?2
				where parent = ?3 and ord in (select value from json_each(?4))
				;"""
				. format([StateVars.font.id])
			),
			[v.x, v.y, parent_name, JSON.stringify(selected)]
		)
	)
	flatten()


func flip_x() -> void:
	_xform([1, 0, 3, 2, 5, 4, 7, 6])


func flip_y() -> void:
	_xform([2, 3, 0, 1, 6, 7, 4, 5])


func rot_cw() -> void:
	_xform([5, 7, 4, 6, 1, 3, 0, 2])


func rot_ccw() -> void:
	_xform([6, 4, 7, 5, 2, 0, 3, 1])


func _xform(t: PackedInt32Array) -> void:
	(
		StateVars
		. db_saves
		. query_with_bindings(
			(
				"""
				update layers_{0}
				set xform = ?1 ->> xform
				where parent = ?2 and ord in (select value from json_each(?3))
				;"""
				. format([StateVars.font.id])
			),
			[JSON.stringify(t), parent_name, JSON.stringify(selected)]
		)
	)
	flatten()


func set_blend(b: int) -> void:
	(
		StateVars
		. db_saves
		. query_with_bindings(
			(
				"""
				update layers_{0}
				set blend = ?1
				where parent = ?2 and ord in (select value from json_each(?3))
				;"""
				. format([StateVars.font.id])
			),
			[b, parent_name, JSON.stringify(selected)]
		)
	)
	flatten()


func sync_cmode() -> void:
	var m := grid.toolman.cmode
	if has_layers:
		var bs := {}
		var item := tree.get_next_selected(null)
		while item:
			bs[item.get_metadata(0).blend] = true
			item = tree.get_next_selected(item)
		m = bs.keys()[0] + Tool.CMode.T if bs.size() == 1 else -1

	for b in grid.cmode_group.get_buttons():
		b.set_pressed_no_signal(Tool.CMode[b.name] == m)


func flatten() -> void:
	StateVars.font.flatten(parent_name)
	StateVars.font.flatten_parents([parent_name])
	grid.refresh()


func refresh() -> void:
	var keep := selected
	tree.clear()
	tree.create_item()

	(
		StateVars
		. db_saves
		. query_with_bindings(
			(
				"""
				select
					l.ord, c.name, c.code, c.dwidth, c.is_abs, c.bb_x, c.bb_y,
					c.off_x + l.off_x as off_x, c.off_y + l.off_y as off_y,
					c.img, l.blend
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
	has_layers = not qs.is_empty()
	grid.get_tree().call_group("hide_if_layer", "hide" if has_layers else "show")

	for q in qs:
		var item := tree.create_item(null, 0)
		item.set_cell_mode(0, TreeItem.CELL_MODE_STRING)
		item.set_metadata(0, q)
		item.set_icon(
			0,
			ImageTexture.create_from_image(Bitmap.new(StyleVars.thumb_size_pre).place(q).to_image())
		)
		item.set_icon_modulate(0, grid.get_theme_color("fg"))
		item.set_text(0, ("U+" if q.code >= 0 else "") + q.name)
		item.add_button(0, grid.cmode_group.get_buttons()[q.blend + Tool.CMode.T].icon)

		if q.ord in keep:
			item.select(0)

	sync_cmode()
