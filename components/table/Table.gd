extends PanelContainer

@export var node_glyphs: Container


func _ready() -> void:
	for c in 256:
		var glyph := Glyph.create(c)
		node_glyphs.add_child(glyph)
