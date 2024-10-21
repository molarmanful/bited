class_name Glyph
extends PanelContainer

const ScnGlyph := preload("res://components/table/glyph.tscn")

@export var virt: Virt
@export var sel: Sel
@export var node_code: Label
@export var node_tex_cont: Container
@export var node_tex: TextureRect
@export var btn: Button

var table: Table
var ind := -1
var data_name := ""
var data_code := -1:
	set(c):
		data_code = c
		if c >= 0:
			data_name = "%04X" % data_code
		refresh()
var label: String:
	get:
		if data_code < 0 or is_noprint(data_code):
			return data_name
		return char(data_code)

var bitmap := Bitmap.new(StyleVars.thumb_size_pre)

var selected := false:
	set(x):
		if selected == x:
			return
		selected = x
		if selected:
			var sb := get_theme_stylebox("panel").duplicate()
			sb.bg_color = get_theme_color("sel")
			add_theme_stylebox_override("panel", sb)
		else:
			remove_theme_stylebox_override("panel")


static func create(t: Table) -> Glyph:
	var glyph = ScnGlyph.instantiate()
	glyph.table = t
	return glyph


func _ready() -> void:
	set_thumb()

	btn.pressed.connect(onpress)


func refresh() -> void:
	node_code.text = label
	set_thumb()


func refresh_tex(gen: Dictionary) -> void:
	bitmap.update_cells(gen)
	if data_name in table.thumbs:
		table.thumbs[data_name].update(bitmap.cells)
	else:
		table.thumbs[data_name] = ImageTexture.create_from_image(bitmap.cells)
	set_thumb()


func set_thumb() -> void:
	var s := StyleVars.thumb_size
	var sz := Vector2(s, s)
	node_tex_cont.custom_minimum_size = sz

	if data_name in table.thumbs:
		node_tex.texture = table.thumbs[data_name]
		node_tex.self_modulate.a = 1
		return
	node_tex.texture = Thumb.tex.texture
	node_tex.self_modulate.a = .69


func onpress():
	var shift := Input.is_physical_key_pressed(KEY_SHIFT)
	var ctrl := Input.is_physical_key_pressed(KEY_CTRL)

	if shift and ctrl:
		sel.select_range_inv(self)
		return

	if shift:
		sel.select_range(self)
		return

	if ctrl:
		sel.select_inv(self)
		return

	if selected and sel.is_alone():
		StateVars.edit.emit(self)
		return

	sel.select(self)


static func is_noprint(n: int) -> bool:
	const R: Array[int] = [0xD800 - 1, 0xDFFF]
	return R.bsearch(n) % 2
