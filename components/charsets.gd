extends Tree

var unicode: TreeItem

var blocks := {}


func _init() -> void:
	create_item()
	unicode = create_item()
	unicode.set_text(0, "UNICODE")


func _ready() -> void:
	load_blocks()

	item_selected.connect(selected)


func load_blocks() -> void:
	StateVars.db_uc.query("select name, start, end from blocks order by start, end desc")
	for q in StateVars.db_uc.query_result:
		var x := unicode.create_child()
		x.set_text(0, q.name)
		blocks[q.name] = [q.start, q.end]


func selected() -> void:
	var txt := get_selected().get_text(0)
	if txt in blocks:
		StateVars.table_range.emit(blocks[txt][0], blocks[txt][1])
