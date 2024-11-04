extends Tree

@export var table: Table

var glyphs: TreeItem
var unicode: TreeItem

var blocks := {}


func _init() -> void:
	create_item()
	glyphs = create_item()
	glyphs.set_text(0, "Font Glyphs")
	unicode = create_item()
	unicode.set_text(0, "Unicode (Full)")
	blocks[unicode] = [0, 1114112]


func _ready() -> void:
	load_blocks()

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


func selected() -> void:
	var sel := get_selected()
	table.node_header.text = sel.get_text(0)
	table.node_subheader.text = ""
	if sel == glyphs:
		table.set_glyphs()
	elif sel in blocks:
		table.set_range(blocks[sel][0], blocks[sel][1])
		table.node_subheader.text = "U+%04X - U+%04X" % [blocks[sel][0], blocks[sel][1] - 1]
