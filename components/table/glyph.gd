class_name Glyph
extends PanelContainer

const ScnGlyph := preload("res://components/table/glyph.tscn")

@export var virt: Virt
@export var sel: Sel
@export var node_code: Label
@export var node_tex: TextureRect
@export var btn: Button

# TODO: use indices for table pos

var data_name := ""
var data_code := -1:
	set(c):
		data_code = c
		if c >= 0:
			data_name = "%04X" % data_code
		refresh()
var label: String:
	get:
		if data_code < 0:
			return data_name
		return char(data_code)

var selected := false:
	set(x):
		if selected == x:
			return
		selected = x
		if selected:
			sel.sel[data_name] = true
			var sb := get_theme_stylebox("panel").duplicate()
			sb.bg_color = get_theme_color("sel")
			add_theme_stylebox_override("panel", sb)
		else:
			sel.sel.erase(data_name)
			remove_theme_stylebox_override("panel")


static func create() -> Glyph:
	var glyph = ScnGlyph.instantiate()
	return glyph


func _ready() -> void:
	renamed.connect(refresh)
	sel.reselect.connect(refresh)
	set_thumb()
	Thumb.updated.connect(set_thumb)
	btn.pressed.connect(onpress)


func set_thumb() -> void:
	var s := StyleVars.thumb_size
	var sz := Vector2(s, s)
	node_tex.size = sz
	node_tex.texture = Thumb.tex.texture


func onpress():
	var shift := Input.is_physical_key_pressed(KEY_SHIFT)
	var ctrl := Input.is_physical_key_pressed(KEY_CTRL)

	if shift and ctrl and sel.inv_anchor:
		# TODO
		return

	if shift and sel.sel_anchor:
		# TODO
		return

	if ctrl:
		selected = !selected
		return

	if selected:
		# TODO
		return

	sel.clear()
	sel.sel_anchor = data_name
	selected = true


func refresh() -> void:
	node_code.text = label
	selected = data_name in sel.sel
