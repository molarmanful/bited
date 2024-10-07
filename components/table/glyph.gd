class_name Glyph
extends PanelContainer

const ScnGlyph := preload("res://components/table/glyph.tscn")

@export var virt: Virt
@export var node_code: RichTextLabel
@export var node_thumb: Control

var data := {code = -1, name = ""}


static func create(c := -1, n := "") -> Glyph:
	var glyph = ScnGlyph.instantiate()
	glyph.data.code = c
	glyph.data.name = n
	return glyph


func _ready() -> void:
	node_code.text = char(data.code)
	(
		virt
		. w_item
		. subscribe(func(w: int): node_thumb.custom_minimum_size = Vector2(w, w))
		. dispose_with(self)
	)
