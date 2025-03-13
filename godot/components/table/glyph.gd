class_name Glyph
extends PanelContainer

const ScnGlyph := preload("glyph.tscn")

@export var node_code: Label
@export var node_tex: TextureRect
@export var btn_l: Button
@export var btn_r: Button

var table: Table
var ind := -1
var data_name := ""
var data_code := -1:
	set(c):
		data_code = c
		if c >= 0:
			data_name = "%04X" % data_code
		refresh()

var bitmap := Bitmap.new(StyleVars.thumb_size_pre)

var selected := false:
	set(x):
		if selected == x:
			return
		selected = x
		set_variation()
var nop := false:
	set(x):
		if nop == x:
			return
		nop = x
		set_variation()
var edit := false:
	set(x):
		if edit == x:
			return
		edit = x
		set_variation()


static func create(t: Table) -> Glyph:
	var glyph := ScnGlyph.instantiate()
	glyph.table = t
	return glyph


func _ready() -> void:
	set_thumb()

	StyleVars.theme_changed.connect(set_thumb)


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			lclick()
		elif e.button_index == MOUSE_BUTTON_RIGHT and not e.pressed:
			rclick()


func refresh() -> void:
	set_label()
	set_thumb()


func refresh_tex(gen: Dictionary) -> void:
	if bitmap.dim != StyleVars.thumb_size_pre:
		bitmap = Bitmap.new(StyleVars.thumb_size_pre)
	bitmap.update_cells(gen)
	if data_name in table.thumbs:
		table.thumbs[data_name].update(bitmap.cells)
	else:
		table.thumbs[data_name] = ImageTexture.create_from_image(bitmap.cells)
	set_thumb()


func set_thumb() -> void:
	Thumb.update()
	node_tex.custom_minimum_size = Thumb.view.size
	node_tex.self_modulate = get_theme_color("fg")
	if data_name in table.thumbs:
		node_tex.texture = table.thumbs[data_name]
		node_tex.self_modulate.a = 1
		return
	node_tex.texture = Thumb.tex.texture
	node_tex.self_modulate.a = .69


func lclick() -> void:
	var shift := Input.is_physical_key_pressed(KEY_SHIFT)
	var ctrl := Input.is_physical_key_pressed(KEY_CTRL)

	table.node_focus.grab_focus()

	if shift and ctrl:
		table.sel.select_range_inv(self)
		return

	if shift:
		table.sel.select_range(self)
		return

	if ctrl:
		table.sel.select_inv(self)
		return

	if not nop and selected and table.sel.is_alone():
		StateVars.edit.emit(self.data_name, self.data_code)
		return

	table.sel.select(self)


func rclick() -> void:
	pass


func set_variation() -> void:
	if nop and selected:
		theme_type_variation = "GlyphNopSel"
	if edit and selected:
		theme_type_variation = "GlyphEditSel"
	elif selected:
		theme_type_variation = "GlyphSel"
	elif edit:
		theme_type_variation = "GlyphEdit"
	elif nop:
		theme_type_variation = "GlyphNop"
	else:
		theme_type_variation = ""


func set_label() -> void:
	if data_code < 0 or is_noprint(data_code):
		node_code.text = data_name
		node_code.theme_type_variation = "GlyphTxt"
		return
	node_code.text = char(data_code)
	node_code.theme_type_variation = "GlyphUC"


static func is_noprint(n: int) -> bool:
	const R: Array[int] = [0xD800, 0xDFFF + 1]
	return R.bsearch(n, false) % 2
