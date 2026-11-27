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
		. db
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
					c.variant, c.child as code, c.xform, c.blend, d.name as uc,
					coalesce(f.name, format('U+%04X', c.child)) as name,
					f.dwidth, f.is_abs, f.img, coalesce(f.bb_x, 0) as bb_x, coalesce(f.bb_y, 0) as bb_y,
					coalesce(f.off_x, 0) as off_x, coalesce(f.off_y, 0) as off_y
				from uc.comps as c
				left join uc.data as d on d.id = c.child
				left join font_{0} as f on f.code = c.child
				where c.parent = :code
				order by c.variant desc, c.ord
				;"""
				. format([StateVars.font.id])
			),
			{parent = layers.parent_name, code = parent_code}
		)
	)
	var qs := StateVars.db.query_result
	if not qs:
		return

	var item: TreeItem = null
	var dis := Color(tree.get_theme_color("danger"), 0.7)
	for q in qs:
		var s := BFont.shift(q.xform, q) if q.img else Vector2i.ZERO
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
		. db
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
