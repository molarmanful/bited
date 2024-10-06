extends PanelContainer

@export var node_glyphs: Container


func _ready() -> void:
	for c in 2048:
		var glyph := Glyph.create(c)
		node_glyphs.add_child(glyph)

	# item_rect_changed.connect(func(): print("scroll?"))
