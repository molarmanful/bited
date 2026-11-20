class_name BFont
extends BFontR
## BDF font abstraction for holding (meta)data.

const BLENDS: Array[Variant.Operator] = [OP_BIT_OR, OP_SUBTRACT, OP_BIT_XOR, OP_BIT_AND]

var id := "new_font"
var px_size: int:
	get:
		return bb.y
var pt_size: int:
	get:
		return px_size * 72 / resolution.y * 10
var dwidth: int:
	get:
		return bb.x
var asc: int:
	get:
		return px_size - desc
var center: Vector2i:
	get:
		return bb * Vector2i(1, -1) / 2


static func creep2() -> BFont:
	var res := BFont.new()
	res.bb = Vector2i(5, 11)
	res.desc = 2
	res.cap_h = 4
	res.x_h = 4
	return res


static func cozette() -> BFont:
	var res := BFont.new()
	res.bb = Vector2i(6, 13)
	res.desc = 3
	res.cap_h = 7
	res.x_h = 5
	return res


static func unifontex() -> BFont:
	var res := BFont.new()
	res.bb = Vector2i(8, 16)
	res.desc = 2
	res.cap_h = 9
	res.x_h = 7
	return res


func init_font(ignore := false) -> void:
	if not ignore:
		(
			StateVars
			. db_saves
			. query(
				(
					"""
					drop table if exists font_{0};
					drop table if exists layers_{0};
					"""
					. format([id])
				)
			)
		)
	(
		StateVars
		. db_saves
		. create_table(
			"font_" + id,
			{
				name = {data_type = "text", not_null = true, primary_key = true},
				code = {data_type = "int", not_null = true, default = -1},
				dwidth = {data_type = "int", not_null = true, default = 0},
				is_abs = {data_type = "int", not_null = true, default = 0},
				bb_x = {data_type = "int", not_null = true, default = 0},
				bb_y = {data_type = "int", not_null = true, default = 0},
				off_x = {data_type = "int", not_null = true, default = 0},
				off_y = {data_type = "int", not_null = true, default = 0},
				img = {data_type = "blob"},
			}
		)
	)

	if not (
		StateVars
		. db_saves
		. query(
			(
				"""
				begin;

				create table if not exists layers_{0} (
					parent text not null,
					ord int not null,
					child text not null,
					off_x int not null default 0,
					off_y int not null default 0,
					blend int not null default 0,
					xform int not null default 0,
					primary key (parent, ord)
				) without rowid
				;

				with up as (select name from font_{0} where code >= 0 and name not glob 'U+*')
				update layers_{0}
				set
					parent = iif(parent in up, 'U+' || parent, parent),
					child = iif(child in up, 'U+' || child, child)
				where parent in up or child in up
				;

				update font_{0} set name = 'U+' || name where code >= 0 and name not glob 'U+*';
				create index if not exists layers_{0}_child on layers_{0} (child);
				create index if not exists font_{0}_code on font_{0} (code, name);

				commit;
				"""
				. format([id])
			)
		)
	):
		StateVars.db_saves.query("rollback;")

	save_font(ignore)
	load_font()


func save_font(ignore = false) -> void:
	StateVars.db_saves.query_with_named_bindings(
		"insert or {0} into fonts (id, data) values (:id, :data);".format(
			["ignore" if ignore else "replace"]
		),
		{id = id, data = var_to_bytes(to_dict())}
	)


func load_font() -> void:
	StateVars.db_saves.query_with_named_bindings(
		"select data from fonts where id = :id;", {id = id}
	)
	var qs := StateVars.db_saves.query_result
	if not qs:
		return
	from_dict(bytes_to_var(qs[0].data))


func to_bdf() -> String:
	var fb := fbbx()
	var res := PackedStringArray(
		[
			"STARTFONT 2.1",
			"FONT %s" % xlfd(),
			"SIZE %d %d %d" % [pt_size / 10, resolution.x, resolution.y],
			"FONTBOUNDINGBOX %d %d %d %d" % [fb.bb_x, fb.bb_y, fb.off_x, fb.off_y],
		]
	)

	res.append_array(to_bdf_properties())
	res.push_back(to_bdf_chars(fb))

	res.push_back("ENDFONT")
	res.push_back("")
	return "\n".join(res)


func to_bdf_properties() -> PackedStringArray:
	var res: Array[String] = [
		"FOUNDRY %s" % stringify(foundry),
		"FAMILY_NAME %s" % stringify(family),
		"WEIGHT_NAME %s" % stringify(weight),
		"SLANT %s" % stringify(slant),
		"SETWIDTH_NAME %s" % stringify(setwidth),
		"ADD_STYLE_NAME %s" % stringify(add_style),
		"PIXEL_SIZE %d" % px_size,
		"POINT_SIZE %d" % pt_size,
		"RESOLUTION_X %d" % resolution.x,
		"RESOLUTION_Y %d" % resolution.y,
		"SPACING %s" % stringify(spacing),
		"AVERAGE_WIDTH %d" % avg_w(),
		"CHARSET_REGISTRY %s" % stringify(ch_reg),
		"CHARSET_ENCODING %s" % stringify(ch_enc),
		"FONT_ASCENT %d" % asc,
		"FONT_DESCENT %d" % desc,
		"CAP_HEIGHT %d" % cap_h,
		"X_HEIGHT %d" % x_h,
		"COPYRIGHT %s" % stringify(copyright),
		"BITED_DWIDTH %d" % dwidth,
		"BITED_TABLE_WIDTH %d" % StyleVars.table_width,
		"BITED_TABLE_CELL_SCALE %d" % StyleVars.thumb_px_size,
		"BITED_EDITOR_GRID_SIZE %d" % StyleVars.grid_size,
		"BITED_EDITOR_CELL_SIZE %d" % StyleVars.grid_px_size,
	]

	for k in props:
		if is_other_prop(k):
			res.append("%s %s" % [k.to_upper(), JSON.stringify(props[k])])

	res.push_front("STARTPROPERTIES %d" % res.size())
	res.push_back("ENDPROPERTIES")
	return res


func to_glyphs_toml() -> String:
	(
		StateVars
		. db_saves
		. query(
			(
				"""
				select is_abs, count(is_abs) as n
				from font_{0}
				group by is_abs
				order by n desc
				limit 1
				;"""
				. format([id])
			)
		)
	)
	var qs := StateVars.db_saves.query_result
	var d_is_abs: int = qs[0].is_abs if qs else 1

	(
		StateVars
		. db_saves
		. query_with_named_bindings(
			(
				"""
				with
					g as (select *, json_quote(name) as key from font_{0}),
					ls as (
						select
							l.parent,
							'layers = [\n' || group_concat(
								format(
									'    { child = %s, off_x = %d, off_y = %d, blend = %d, xform = %d },\n',
									c.key, l.off_x, l.off_y, l.blend, l.xform
								),
								'' order by l.ord
							) || ']\n' as layers
						from layers_{0} as l
						join g as c on c.name = l.child
						group by l.parent
					)
				select
					coalesce(
						group_concat(
							format('[glyphs.%s]\n', g.key)
							|| iif(g.is_abs <> :is_abs, format('is_abs = %s\n', iif(g.is_abs, 'true', 'false')), '')
							|| coalesce(ls.layers, ''),
							'' order by g.code, g.name
						), ''
					) as toml
				from g
				left join ls on ls.parent = g.name
				where g.is_abs <> :is_abs or ls.layers is not null
				;"""
				. format([id])
			),
			{is_abs = d_is_abs}
		)
	)

	return (
		"[default]\nis_abs = %s\n%s"
		% ["true" if d_is_abs else "false", StateVars.db_saves.query_result[0].toml]
	)


func to_bdf_chars(fb: Dictionary) -> String:
	(
		StateVars
		. db_saves
		. query_with_named_bindings(
			(
				"""
				with recursive
					r(n) as (
						select 0
						union all
						select n + 1 from r where n + 1 < (select max(bb_y) from font_{0})
					),
					g as (
						select
							name, code, bb_x, bb_y, off_x, off_y, :dw * (is_abs = 0) + dwidth as dw,
							coalesce(
								group_concat(
									substr(hex(img), n * ((bb_x + 7) / 8 * 2) + 1, (bb_x + 7) / 8 * 2) || '\n',
									'' order by n
								), ''
							) as bm
						from font_{0}
						left join r on n < bb_y and img <> x''
						group by name
					)
				select
					'CHARS ' || count(*) || coalesce(
						'\n' || group_concat(
							format(
								'STARTCHAR %s\nENCODING %d\nSWIDTH %d 0\nDWIDTH %d 0\nBBX %d %d %d %d\nBITMAP\n%sENDCHAR',
								name, code, dw * 72000 / (:res_x * :max_w), dw,
								bb_x, bb_y, off_x, off_y, bm
							),
							'\n' order by code, name
						), ''
					) as chars
				from g
				;"""
				. format([id])
			),
			{dw = dwidth, res_x = resolution.x, max_w = fb.bb_x}
		)
	)
	return StateVars.db_saves.query_result[0].chars


func save_glyphs(gens: Array[Dictionary], over := true) -> void:
	StateVars.db_saves.query("begin;")
	for gen in gens:
		insert_glyph(gen, over)
	flatten_parents(gens.map(func(gen: Dictionary): return gen.name))
	StateVars.db_saves.query("commit;")
	StateVars.table_refresh.emit()


func insert_layers(ls: Array[Dictionary]) -> void:
	(
		StateVars
		. db_saves
		. query_with_named_bindings(
			(
				"""
				insert or replace into layers_{0} (parent, ord, child, off_x, off_y, blend, xform)
				select
					value ->> 'parent', value ->> 'ord', value ->> 'child',
					value ->> 'off_x', value ->> 'off_y', value ->> 'blend', value ->> 'xform'
				from json_each(:ls)
				;"""
				. format([id])
			),
			{ls = JSON.stringify(ls)}
		)
	)


func save_glyph(gen: Dictionary, over := true) -> void:
	if insert_glyph(gen, over):
		StateVars.refresh.emit(gen)
	flatten_parents([gen.name])


func insert_glyph(gen: Dictionary, over := true) -> bool:
	(
		StateVars
		. db_saves
		. query_with_named_bindings(
			(
				"""
				insert or {0}
				into font_{1}
				(name, code, dwidth, is_abs, bb_x, bb_y, off_x, off_y, img)
				values
				(:name, :code, :dwidth, :is_abs, :bb_x, :bb_y, :off_x, :off_y, :img)
				returning name
				;"""
				. format(["replace" if over else "ignore", StateVars.font.id])
			),
			gen
		)
	)
	return not not StateVars.db_saves.query_result


func flatten_parents(names: Array) -> void:
	(
		StateVars
		. db_saves
		. query_with_named_bindings(
			(
				"""
				with recursive
					up(name, depth) as (
						select parent, 1
						from layers_{0}
						where child in (select value from json_each(:names))
						union
						select l.parent, up.depth + 1
						from layers_{0} as l
						join up on l.child = up.name
					)
				select name
				from up
				group by name
				order by max(depth)
				;"""
				. format([id])
			),
			{names = JSON.stringify(names)}
		)
	)
	for q in StateVars.db_saves.query_result:
		flatten(q.name)


func flatten(name: String) -> void:
	(
		StateVars
		. db_saves
		. query_with_named_bindings(
			(
				"""
				select
					c.off_x, c.off_y, l.off_x as dx, l.off_y as dy, l.blend, l.xform,
					c.bb_x, c.bb_y, c.img
				from layers_{0} as l
				join font_{0} as c on c.name = l.child
				where l.parent = :name
				order by l.ord
				;"""
				. format([id])
			),
			{name = name}
		)
	)
	var d := compose({name = name}, StateVars.db_saves.query_result)
	(
		StateVars
		. db_saves
		. query_with_named_bindings(
			(
				"""
				update font_{0}
				set bb_x = :bb_x, bb_y = :bb_y, off_x = :off_x, off_y = :off_y, img = :img
				where name = :name
				returning name, code, dwidth, is_abs, bb_x, bb_y, off_x, off_y, img
				;"""
				. format([id])
			),
			d
		)
	)
	StateVars.refresh.emit(StateVars.db_saves.query_result[0])


static func xform_rect(r: Rect2i, x: int) -> Rect2i:
	if x & 4:
		r = Rect2i(-r.end.y, -r.end.x, r.size.y, r.size.x)
	if x & 1:
		r.position.x = -r.end.x
	if x & 2:
		r.position.y = -r.end.y
	return r


static func shift(x: int, g: Dictionary) -> Vector2i:
	var c := Vector2i(g.off_x * 2 + g.bb_x, g.off_y * 2 + g.bb_y)
	var d := c - xform_rect(Rect2i(c, Vector2i.ZERO), x).position
	return Vector2i(d.x >> 1, d.y >> 1)


static func compose(p: Dictionary, qs: Array) -> Dictionary:
	var r := Rect2i()
	var ts: Array[Array] = []
	for q in qs:
		var g := BitGlyph.create_from_bytes(
			Vector2i(q.bb_x, q.bb_y), q.img if q.img else PackedByteArray()
		)
		g.xform(q.xform)

		var qr := xform_rect(Rect2i(q.off_x, q.off_y, q.bb_x, q.bb_y), q.xform)
		qr.position += Vector2i(q.dx, q.dy)
		ts.push_back([BLENDS[q.blend], g, qr])
		if qr.has_area():
			r = r.merge(qr) if r.has_area() else qr

	var bg := BitGlyph.create(r.size)
	for t in ts:
		var qr: Rect2i = t[2]
		bg.blit(t[0], t[1], Vector2i(qr.position.x - r.position.x, r.end.y - qr.end.y))

	var u := bg.used_rect()
	return (
		p
		. merged(
			{
				bb_x = u.size.x,
				bb_y = u.size.y,
				off_x = r.position.x + u.position.x if u.has_area() else 0,
				off_y = r.end.y - u.end.y if u.has_area() else 0,
				img = bg.region(u).to_bytes(),
			},
			true
		)
	)


func to_dict() -> Dictionary:
	return {
		foundry = foundry,
		family = family,
		weight = weight,
		slant = slant,
		setwidth = setwidth,
		add_style = add_style,
		resolution = resolution,
		spacing = spacing,
		ch_reg = ch_reg,
		ch_enc = ch_enc,
		bb = bb,
		desc = desc,
		cap_h = cap_h,
		x_h = x_h,
		copyright = copyright,
		props = props,
		table_width = StyleVars.table_width,
		thumb_px_size = StyleVars.thumb_px_size_cor,
		grid_size = StyleVars.grid_size_cor,
		grid_px_size = StyleVars.grid_px_size_cor,
	}


func from_dict(d: Dictionary) -> void:
	foundry = d.foundry
	family = d.family
	weight = d.weight
	slant = d.slant
	setwidth = d.setwidth
	add_style = d.add_style
	resolution = d.resolution
	spacing = d.spacing
	ch_reg = d.ch_reg
	ch_enc = d.ch_enc
	bb = d.bb
	desc = d.desc
	cap_h = d.cap_h
	x_h = d.x_h
	copyright = d.copyright
	var p: Dictionary[String, Variant] = {}
	p.assign(d.props)
	props = p
	StyleVars.table_width = d.table_width
	StyleVars.thumb_px_size = d.thumb_px_size
	StyleVars.grid_size = d.grid_size
	StyleVars.grid_px_size = d.grid_px_size


func xlfd() -> String:
	return (
		"-%s-%s-%s-%s-%s-%s-%d-%d-%d-%d-%s-%d-%s-%s"
		% [
			foundry,
			family,
			weight,
			slant,
			setwidth,
			add_style,
			px_size,
			pt_size,
			resolution.x,
			resolution.y,
			spacing,
			avg_w(),
			ch_reg,
			ch_enc,
		]
	)


func avg_w() -> int:
	var qs := StateVars.db_saves.select_rows(
		"font_" + id,
		"",
		["cast(avg({0} * (is_abs = 0) + dwidth) * 10 as int) as avg".format([dwidth])]
	)
	if not qs:
		return 0
	return qs[0].avg if qs[0].avg else 0


func fbbx() -> Dictionary:
	var qs := StateVars.db_saves.select_rows(
		"font_" + id,
		"",
		[
			"coalesce(max(bb_x), 0) as bb_x",
			"coalesce(max(bb_y), 0) as bb_y",
			"coalesce(min(off_x), 0) as off_x",
			"coalesce(min(off_y), 0) as off_y",
			"coalesce(max({0} * (is_abs = 0) + dwidth), 0) as dwidth".format([dwidth])
		]
	)
	return qs[0]


func stringify(s: String) -> String:
	return '"%s"' % s.replace('"', '""')
