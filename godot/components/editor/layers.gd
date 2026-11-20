class_name Layers
extends Window

@export var editor: Editor
@export var btn: Button
@export var tree: Tree

@export var btn_move: Button
@export var btn_pick: Button
@export var btn_bake: Button
@export var btn_del: Button

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
	tree.set_drag_forwarding(
		func(_at: Vector2) -> Variant:
			var s := selected
			if not s:
				return null
			var l := Label.new()
			l.text = "%d layers" % s.size()
			tree.set_drag_preview(l)
			tree.drop_mode_flags = Tree.DROP_MODE_INBETWEEN
			return s,
		func(_at: Vector2, data: Variant) -> bool: return data is PackedInt32Array,
		move
	)

	StateVars.edit.connect(select_top.unbind(2), CONNECT_DEFERRED)
	grid.refreshed.connect(refresh)

	visibility_changed.connect(
		func():
			btn.set_pressed_no_signal(visible)
			if not visible:
				btn_pick.button_pressed = false
	)
	close_requested.connect(hide)

	btn.toggled.connect(
		func(on: bool):
			if on:
				var pos := (
					btn.get_screen_transform() * Vector2(btn.size.x, 0)
					+ Vector2(8, get_theme_constant("title_height"))
				)
				popup(Rect2i(pos, size))
			else:
				close_requested.emit()
	)

	btn_pick.toggled.connect(
		func(on: bool):
			table.pick_layer = on
			if on:
				btn.button_pressed = true
	)
	btn_bake.pressed.connect(bake)
	btn_del.pressed.connect(del)
	tree.multi_selected.connect(sync_sel.unbind(3), CONNECT_DEFERRED)


func pick(gname: String) -> void:
	(
		StateVars
		. db_saves
		. query_with_named_bindings(
			(
				"""
				with recursive
					up(name) as (
						select :parent
						union
						select l.parent
						from layers_{0} as l
						join up on l.child = up.name
					)
				insert into layers_{0} (parent, child, ord)
				select
					:parent, :child,
					(select coalesce(max(ord), -1) + 1 from layers_{0} where parent = :parent)
				where :child not in (select name from up)
				returning ord
				;"""
				. format([StateVars.font.id])
			),
			{parent = parent_name, child = gname}
		)
	)
	if StateVars.db_saves.query_result:
		flatten()
		select_top()


func select_top() -> void:
	tree.deselect_all()
	if has_layers:
		tree.get_root().get_child(0).select(0)
	sync_sel()


func del() -> void:
	(
		StateVars
		. db_saves
		. query_with_named_bindings(
			(
				"""
				delete from layers_{0}
				where parent = :parent and ord in (select value from json_each(:ords))
				returning ord
				;"""
				. format([StateVars.font.id])
			),
			{parent = parent_name, ords = JSON.stringify(selected)}
		)
	)
	if StateVars.db_saves.query_result:
		flatten()


func move(at: Vector2, ords: PackedInt32Array) -> void:
	var dst := tree.get_item_at_position(at)
	var drop := tree.get_drop_section_at_position(at)
	var rows := PackedInt32Array()
	for item in tree.get_root().get_children():
		var o: int = item.get_metadata(0).ord
		if item == dst and drop < 0:
			rows += ords
		if o not in ords:
			rows.push_back(o)
		if item == dst and drop > 0:
			rows += ords
	if not dst:
		rows += ords
	rows.reverse()

	(
		StateVars
		. db_saves
		. query_with_named_bindings(
			(
				"""
				update layers_{0}
				set ord = -1 - j.key
				from json_each(:rows) as j
				where layers_{0}.parent = :parent and layers_{0}.ord = j.value;
				update layers_{0}
				set ord = -1 - ord
				where parent = :parent and ord < 0;
				"""
				. format([StateVars.font.id])
			),
			{parent = parent_name, rows = JSON.stringify(rows)}
		)
	)

	for item in tree.get_root().get_children():
		item.get_metadata(0).ord = rows.find(item.get_metadata(0).ord)
	flatten()


func translate(v: Vector2i) -> void:
	(
		StateVars
		. db_saves
		. query_with_named_bindings(
			(
				"""
				update layers_{0}
				set off_x = off_x + :x, off_y = off_y - :y
				where parent = :parent and ord in (select value from json_each(:ords))
				;"""
				. format([StateVars.font.id])
			),
			{x = v.x, y = v.y, parent = parent_name, ords = JSON.stringify(selected)}
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


func bake() -> void:
	StateVars.db_saves.query_with_named_bindings(
		"delete from layers_{0} where parent = :parent;".format([StateVars.font.id]),
		{parent = parent_name}
	)
	grid.refresh()


func clear_xform() -> void:
	(
		StateVars
		. db_saves
		. query_with_named_bindings(
			(
				"""
				update layers_{0}
				set xform = 0, off_x = 0, off_y = 0
				where parent = :parent and ord in (select value from json_each(:ords))
				;"""
				. format([StateVars.font.id])
			),
			{parent = parent_name, ords = JSON.stringify(selected)}
		)
	)
	flatten()


func _xform(t: PackedInt32Array) -> void:
	var w := grid.pattern.bitmap.dwidth_calc
	var ls := []
	var item := tree.get_next_selected(null)
	while item:
		var q: Dictionary = item.get_metadata(0)
		var r := Rect2i(q.off_x, q.off_y, q.bb_x, q.bb_y)
		var at := BFont.xform_rect(r, q.xform, w)
		at.position += Vector2i(q.dx, q.dy)
		var d := (
			BFont.xform_rect(at, t[0], w).position - BFont.xform_rect(r, t[q.xform], w).position
		)
		ls.push_back({ord = q.ord, xform = t[q.xform], dx = d.x, dy = d.y})
		item = tree.get_next_selected(item)

	(
		StateVars
		. db_saves
		. query_with_named_bindings(
			(
				"""
				update layers_{0}
				set xform = j.value ->> 'xform', off_x = j.value ->> 'dx', off_y = j.value ->> 'dy'
				from json_each(:ls) as j
				where layers_{0}.parent = :parent and layers_{0}.ord = j.value ->> 'ord'
				;"""
				. format([StateVars.font.id])
			),
			{ls = JSON.stringify(ls), parent = parent_name}
		)
	)
	flatten()


func set_blend(b: int) -> void:
	(
		StateVars
		. db_saves
		. query_with_named_bindings(
			(
				"""
				update layers_{0}
				set blend = :blend
				where parent = :parent and ord in (select value from json_each(:ords))
				;"""
				. format([StateVars.font.id])
			),
			{blend = b, parent = parent_name, ords = JSON.stringify(selected)}
		)
	)
	flatten()


func sync_sel(v := Vector2i.ZERO) -> void:
	var bs := {}
	var qs := []
	var item := tree.get_next_selected(null)
	while item:
		var q: Dictionary = item.get_metadata(0)
		bs[q.blend] = true
		qs.push_back(q.merged({dx = q.dx + v.x, dy = q.dy - v.y, blend = 0}, true))
		item = tree.get_next_selected(item)

	var m := grid.toolman.cmode
	if has_layers:
		m = bs.keys()[0] + Tool.CMode.T if bs.size() == 1 else -1
	for b in grid.cmode_group.get_buttons():
		b.set_pressed_no_signal(Tool.CMode[b.name] == m)

	grid.node_sel.visible = not not qs
	if not qs:
		return

	var img := (
		Bitmap.new(grid.dim_grid).place(BFont.compose(grid.pattern.bitmap.meta(), qs)).to_image()
	)
	var tex: ImageTexture = grid.node_sel.texture
	if Vector2i(tex.get_size()) == img.get_size():
		tex.update(img)
	else:
		tex.set_image(img)


func preview(v: Vector2i) -> void:
	var qs := []
	for item in tree.get_root().get_children():
		var q: Dictionary = item.get_metadata(0)
		if item.is_selected(0):
			q = q.merged({dx = q.dx + v.x, dy = q.dy - v.y}, true)
		qs.push_front(q)
	grid.pattern.bitmap.update_cells(BFont.compose(grid.pattern.bitmap.meta(), qs))
	sync_sel(v)


func flatten(hard := false) -> void:
	StateVars.font.flatten(parent_name)
	StateVars.font.flatten_parents([parent_name])
	grid.refresh(hard)


func refresh() -> void:
	var keep := selected
	tree.clear()
	tree.create_item()

	(
		StateVars
		. db_saves
		. query_with_named_bindings(
			(
				"""
				select
					l.ord, c.name, c.code, c.dwidth, c.is_abs, c.bb_x, c.bb_y,
					c.off_x, c.off_y, l.off_x as dx, l.off_y as dy, c.img, l.blend, l.xform
				from layers_{0} as l
				join font_{0} as c on l.child = c.name
				where l.parent = :parent
				order by l.ord
				;"""
				. format([StateVars.font.id])
			),
			{parent = parent_name}
		)
	)

	var qs := StateVars.db_saves.query_result
	has_layers = not not qs
	grid.get_tree().call_group("hide_if_layer", "hide" if has_layers else "show")
	if has_layers:
		btn_move.button_pressed = true

	StateVars.db_uc.query_with_named_bindings(
		"""
		select json_group_object(id, name) as names
		from data
		where id in (select value from json_each(:codes))
		;""",
		{codes = JSON.stringify(qs.map(func(q): return q.code))}
	)
	var names: Dictionary = JSON.parse_string(StateVars.db_uc.query_result[0].names)

	for q in qs:
		q.uc = names.get(str(q.code))
		var item := tree.create_item(null, 0)
		item.set_metadata(0, q)
		render_layer(item, q)
		if q.ord in keep:
			item.select(0)

	sync_sel()


func render_layer(item: TreeItem, gen: Dictionary) -> void:
	if gen.img:
		item.set_icon(
			0,
			ImageTexture.create_from_image(
				(
					Bitmap
					. new(StyleVars.thumb_size_pre)
					. place(
						BFont.compose(grid.pattern.bitmap.meta(), [gen.merged({blend = 0}, true)])
					)
					. to_image()
				)
			)
		)

	item.set_icon_modulate(0, grid.get_theme_color("fg"))
	item.set_text(0, "%s%s" % [gen.name, " %s" % gen.uc if gen.uc else ""])
	item.add_button(0, grid.cmode_group.get_buttons()[gen.blend + Tool.CMode.T].icon)
