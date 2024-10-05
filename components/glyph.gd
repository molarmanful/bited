class_name Glyph
extends PanelContainer

const ScnGlyph := preload("res://components/glyph.tscn")

@export var node_code: RichTextLabel

var data := {code = -1, name = ""}


static func create(c := -1, n := "") -> Glyph:
	var glyph = ScnGlyph.instantiate()
	glyph.data.code = c
	glyph.data.name = n
	return glyph


func _ready() -> void:
	node_code.text = char(data.code)
