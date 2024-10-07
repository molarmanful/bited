class_name Glyph
extends PanelContainer

const ScnGlyph := preload("res://components/table/glyph.tscn")

@export var virt: Virt
@export var node_code: RichTextLabel
@export var node_thumb: Control

var data_code := -1:
	set(c):
		data_code = c
		up_ui()

var label: String:
	get:
		if data_code < 0:
			return name
		return char(data_code)


static func create() -> Glyph:
	var glyph = ScnGlyph.instantiate()
	return glyph


func _ready() -> void:
	thumb()

	renamed.connect(up_ui)
	StyleVars.set_thumb.connect(thumb)


func thumb():
	node_thumb.custom_minimum_size = Vector2(StyleVars.thumb_size, StyleVars.thumb_size)


func up_ui() -> void:
	node_code.text = label
