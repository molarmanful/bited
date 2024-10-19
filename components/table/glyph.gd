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
			sel.sel[data_name] = true
			var sb := get_theme_stylebox("panel").duplicate()
			sb.bg_color = get_theme_color("sel")
			add_theme_stylebox_override("panel", sb)
		else:
			sel.sel.erase(data_name)
			remove_theme_stylebox_override("panel")


static func create(t: Table) -> Glyph:
	var glyph = ScnGlyph.instantiate()
	glyph.table = t
	return glyph


func _ready() -> void:
	set_thumb()

	renamed.connect(refresh)
	sel.reselect.connect(refresh)
	Thumb.updated.connect(set_thumb)
	btn.pressed.connect(onpress)
	StateVars.refresh.connect(refresh_tex)


func _input(e: InputEvent) -> void:
	if not selected:
		return

	if e.is_action_pressed("ui_text_delete") or e.is_action_pressed("ui_text_backspace"):
		delete()


func refresh() -> void:
	node_code.text = label
	selected = data_name in sel.sel
	set_thumb()


func refresh_tex(gen: Dictionary) -> void:
	if data_name != gen.name:
		return

	bitmap.update_cells(gen)
	table.set_thumb_tex(data_name, bitmap.cells)
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

	if shift and ctrl and sel.anchor_sel >= 0:
		# TODO
		return

	if shift and sel.anchor_sel >= 0:
		# TODO
		return

	if ctrl:
		sel.anchor_inv = ind
		selected = !selected
		return

	if selected and sel.sel.size() <= 1:
		StateVars.edit.emit(self)
		return

	sel.clear()
	sel.anchor_sel = ind
	selected = true


# TODO: move to Sel
func delete() -> void:
	StateVars.db_saves.delete_rows(
		"font_" + StateVars.font.id, "name = " + JSON.stringify(data_name)
	)
	table.thumbs.erase(data_name)
	virt.refresh.emit()


static func is_noprint(n: int) -> bool:
	const R: Array[int] = [0xD800 - 1, 0xDFFF]
	return R.bsearch(n) % 2
