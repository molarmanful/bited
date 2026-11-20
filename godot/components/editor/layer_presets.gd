class_name LayerPresets
extends Window

@export var layers: Layers
@export var btn: Button
@export var tree: Tree

var grid: Grid:
	get:
		return layers.grid
var parent_code: int:
	get:
		return layers.grid.pattern.bitmap.data_code


func _ready() -> void:
	grid.refreshed.connect(refresh)

	visibility_changed.connect(func(): btn.set_pressed_no_signal(visible))
	close_requested.connect(hide)

	btn.toggled.connect(
		func(on: bool):
			if on:
				popup()
			else:
				close_requested.emit()
	)
	tree.item_activated.connect(choose)


func refresh() -> void:
	tree.clear()
	tree.create_item()

	(
		StateVars
		. db_uc
		. query_with_named_bindings(
			"""
			select json_group_array(
				json_object(
					'variant', variant, 'code', child, 'xform', xform, 'blend', blend,
					'uc', (select name from data where id = child)
				) order by variant desc, ord
			) as rows
			from comps
			where parent = :parent
			;""",
			{parent = parent_code}
		)
	)

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
				select
					f.name not in (select name from up) as ok,
					j.value ->> 'variant' as variant, j.value ->> 'code' as code,
					j.value ->> 'xform' as xform, j.value ->> 'blend' as blend, j.value ->> 'uc' as uc,
					coalesce(f.name, format('U+%04X', j.value ->> 'code')) as name,
					f.dwidth, f.is_abs, f.bb_x, f.bb_y, f.off_x, f.off_y, f.img
				from json_each(:rows) as j
				left join font_{0} as f on f.code = j.value ->> 'code'
				order by j.key
				;"""
				. format([StateVars.font.id])
			),
			StateVars.db_uc.query_result[0].merged({parent = layers.parent_name})
		)
	)
	var qs := StateVars.db_saves.query_result
	if not qs:
		return

	var item: TreeItem = null
	var dis := Color(tree.get_theme_color("danger"), 0.7)
	var w := grid.pattern.bitmap.dwidth_calc
	for q in qs:
		var s := BFont.shift(q.xform, w)
		q.dx = s.x
		q.dy = s.y
		if not item or item.get_metadata(0) != q.variant:
			item = tree.create_item(null, 0)
			item.set_metadata(0, q.variant)
			item.set_text(0, "#%d" % (q.variant + 1))

		var sub := tree.create_item(item, 0)
		sub.set_metadata(0, q)
		layers.render_layer(sub, q)
		sub.set_selectable(0, false)

		if not q.ok:
			item.set_text(0, "#%d ×" % (q.variant + 1))
			item.set_selectable(0, false)
			item.set_custom_color(0, dis)
			sub.set_custom_color(0, dis)


func choose() -> void:
	var sel := tree.get_selected()
	if not sel:
		return
	var ls := sel.get_children().map(func(c): return c.get_metadata(0))
	ls.reverse()

	(
		StateVars
		. db_saves
		. query_with_named_bindings(
			(
				"""
				delete from layers_{0} where parent = :parent;

				insert into layers_{0} (parent, ord, child, off_x, off_y, xform, blend)
				select
					:parent, key, value ->> 'name',
					value ->> 'dx', value ->> 'dy', value ->> 'xform', value ->> 'blend'
				from json_each(:ls)
				;"""
				. format([StateVars.font.id])
			),
			{parent = layers.parent_name, ls = JSON.stringify(ls)}
		)
	)

	layers.flatten()
	layers.select_top()
