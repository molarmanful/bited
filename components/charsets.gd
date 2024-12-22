extends Tree

@export var table: Table

var glyphs: TreeItem
var unicode: TreeItem

var blocks := {}
var page_cats := {}
var pages := {}


func _init() -> void:
	create_item()
	glyphs = create_item()
	glyphs.set_text(0, "Font Glyphs")
	unicode = create_item()
	unicode.set_text(0, "Unicode (Full)")
	blocks[unicode] = [0, 1114112]


func _ready() -> void:
	load_blocks()
	load_pages()

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


func load_pages() -> void:
	(
		StateVars
		. db_uc
		. query(
			"""
			select id, name, category
			from pages
			order by category nulls last, id
			;"""
		)
	)
	for q in StateVars.db_uc.query_result:
		var x: TreeItem
		if q.category:
			if q.category not in page_cats:
				var y := create_item()
				y.set_text(0, q.category)
				page_cats[q.category] = y
			x = page_cats[q.category].create_child()
		else:
			x = create_item()
		x.set_text(0, q.name)
		pages[x] = q.id


func selected() -> void:
	var sel := get_selected()

	if sel == glyphs:
		table.set_glyphs()
		update_ui(sel)

	elif sel in blocks:
		table.set_range(blocks[sel][0], blocks[sel][1])
		update_ui(sel, "U+%04X - U+%04X" % [blocks[sel][0], blocks[sel][1] - 1])

	elif sel in pages:
		table.set_page(pages[sel])
		update_ui(sel)


func update_ui(sel: TreeItem, sub := "") -> void:
	table.node_header.text = sel.get_text(0)
	table.node_subheader.text = sub
