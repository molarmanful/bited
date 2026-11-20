class_name LayerParents
extends Window

@export var layers: Layers
@export var btn: Button
@export var tree: Tree

var grid: Grid:
	get:
		return layers.grid


func _ready() -> void:
	grid.refreshed.connect(refresh)

	visibility_changed.connect(func(): btn.set_pressed_no_signal(visible))
	close_requested.connect(hide)

	btn.toggled.connect(
		func(on: bool):
			if on:
				var pos := btn.get_screen_transform() * btn.size + Vector2(8, -size.y)
				popup(Rect2i(pos, size))
			else:
				close_requested.emit()
	)

	tree.item_activated.connect(edit)


func edit() -> void:
	var item := tree.get_selected()
	if not item:
		return
	var q: Dictionary = item.get_metadata(0)
	StateVars.edit.emit(q.name, q.code)


func refresh() -> void:
	tree.clear()
	tree.create_item()

	(
		StateVars
		. db_saves
		. query_with_named_bindings(
			(
				"""
				select name, code, dwidth, is_abs, bb_x, bb_y, off_x, off_y, img, null as blend
				from font_{0}
				where name in (select parent from layers_{0} where child = :name)
				order by code, name
				;"""
				. format([StateVars.font.id])
			),
			{name = layers.parent_name}
		)
	)
	var qs := StateVars.db_saves.query_result

	StateVars.db_uc.query_with_named_bindings(
		"""
		select json_group_object(id, name) as names
		from data
		where id in (select value from json_each(:codes))
		;""",
		{codes = JSON.stringify(qs.map(func(q): return q.code))}
	)
	var names: Dictionary = JSON.parse_string(StateVars.db_uc.query_result[0].names)

	var bm := Bitmap.new(StyleVars.thumb_size_pre)
	for q in qs:
		q.uc = names.get(str(q.code))
		var item := tree.create_item()
		item.set_metadata(0, q)
		if q.img:
			item.set_icon(0, ImageTexture.create_from_image(bm.place(q).to_image()))
			q.img = null
		layers.render_layer(item, q)
