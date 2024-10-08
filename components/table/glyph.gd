class_name Glyph
extends PanelContainer

const ScnGlyph := preload("res://components/table/glyph.tscn")

@export var virt: Virt
@export var node_code: RichTextLabel
@export var node_tex: TextureRect

var data_name := ""
var data_code := -1:
	set(c):
		data_code = c
		if c >= 0:
			data_name = "%04X" % data_code
		up_ui()
var label: String:
	get:
		if data_code < 0:
			return data_name
		return char(data_code)


static func create() -> Glyph:
	var glyph = ScnGlyph.instantiate()
	return glyph


func _ready() -> void:
	renamed.connect(up_ui)
	set_thumb()
	Thumb.updated.connect(set_thumb)


func set_thumb() -> void:
	var s := StyleVars.thumb_size
	var sz := Vector2(s, s)
	node_tex.size = sz
	node_tex.texture = Thumb.tex.texture


func up_ui() -> void:
	node_code.text = label
