extends Tree

@export var table: Table

var glyphs: TreeItem
var unicode: TreeItem

var blocks := {}
var sbcs_cats := {}
var sbcs := {}


func _init() -> void:
	create_item()
	glyphs = create_item()
	glyphs.set_text(0, "Font Glyphs")
	unicode = create_item()
	unicode.set_text(0, "Unicode (Full)")
	blocks[unicode] = [0, 1114112]


func _ready() -> void:
	load_blocks()
	load_sbcs()

	item_selected.connect(selected)
	glyphs.select(0)


func load_blocks() -> void:
	(
		StateVars
		. db_uc
		. query(
			"""
			select name, start, end
			from blocks
			order by start, end desc
			;"""
		)
	)
	for q in StateVars.db_uc.query_result:
		var x := unicode.create_child()
		x.set_text(0, q.name)
		blocks[x] = [q.start, q.end]


func load_sbcs() -> void:
	(
		StateVars
		. db_uc
		. query(
			(
				"""
				select name, category, %s
				from sbcs
				order by category, id
				;"""
				% ",".join(range(256).map(func(n: int): return "c%d" % n))
			)
		)
	)
	for q in StateVars.db_uc.query_result:
		var x: TreeItem
		if q.category:
			if q.category not in sbcs_cats:
				var y := create_item()
				y.set_text(0, q.category)
				y.set_selectable(0, false)
				sbcs_cats[q.category] = y
			x = sbcs_cats[q.category].create_child()
		else:
			x = create_item()
		x.set_text(0, q.name)

		var res := PackedInt32Array()
		res.resize(256)
		for i in 256:
			var c = q["c%d" % i]
			res[i] = c if c != null else -1

		sbcs[x] = res


func selected() -> void:
	var sel := get_selected()

	if sel == glyphs:
		table.set_glyphs()
		update_ui(sel)

	elif sel in blocks:
		table.set_range(blocks[sel][0], blocks[sel][1])
		update_ui(sel, "U+%04X - U+%04X" % [blocks[sel][0], blocks[sel][1] - 1])

	elif sel in sbcs:
		table.set_sbcs(sbcs[sel])
		update_ui(sel)


func update_ui(sel: TreeItem, sub := "") -> void:
	table.node_header.text = sel.get_text(0)
	table.node_subheader.text = sub
