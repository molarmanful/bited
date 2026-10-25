class_name Preview
extends PanelContainer

@export var window: Window
@export var presets: OptionButton
@export var input: TextEdit
@export var btn_font: Button
@export var input_scale: SpinBox
@export var btn_dl: Button
@export var file_dl: FileDialog

var font: FontFileGen

var preset_tree: Dictionary[String, Array] = {
	"BASIC":
	[
		"hamburgefontsiv",
		"boxing wizards",
		"grumpy wizards",
		"weird a-z",
		"kerning",
		"grids",
		"briem",
		"stephenson blake",
		"kern king",
		"kern a-z",
		"min kern pairs",
		"nick",
		"numbers",
	],
	"LATIN":
	[
		"latin",
		"latin word vomit",
		"apostrophes",
		"diacritics a-z",
		"diacritics lang",
		"diacritics pseudo",
		"diacritics extras",
		"news headlines",
	],
	"GREEK":
	[
		"greek pangrams",
		"greek smg",
	],
	"CYRILLIC":
	[
		"cyrillic",
		"cyr hamburgefontsiv",
		"cyr a-z",
		"cyr kerning",
		"cyr grids",
		"serbian",
		"bulgarian",
		"ukrainian",
	],
	"PROGRAMMING":
	[
		"programming",
		"apl",
	],
	"UNICODE":
	[
		"kuhn demo",
	],
}


func _ready() -> void:
	window.hide()

	presets.add_separator("PRESETS")
	for k in preset_tree.keys():
		presets.add_separator(k)
		for p in preset_tree[k]:
			presets.add_item(p)
	presets.select(0)

	StateVars.refresh.connect(
		func(gen: Dictionary):
			if window.visible and font.queried.erase(gen.code):
				font.load_str(char(gen.code))
				apply_font()
	)
	StateVars.edit_refresh.connect(
		func():
			if window.visible:
				rebuild()
	)
	StateVars.settings.connect(
		func():
			if window.visible:
				rebuild()
	)
	window.close_requested.connect(
		func():
			window.hide()
			font = null
	)
	presets.item_selected.connect(preset)
	input.text_changed.connect(func(): presets.selected = 0)
	input.lines_edited_from.connect(load_lines)
	btn_font.toggled.connect(apply_font.unbind(1))
	input_scale.value_changed.connect(apply_font.unbind(1))
	btn_dl.pressed.connect(file_dl.popup)
	file_dl.file_selected.connect(download)


func preset(i: int) -> void:
	var file := FileAccess.open(
		"res://assets/preview/%s.txt" % presets.get_item_text(i), FileAccess.READ
	)
	input.text = file.get_as_text()
	input.set_v_scroll(0)


func preview() -> void:
	if not font:
		rebuild()
	window.popup()
	input.grab_focus()


func rebuild() -> void:
	font = FontFileGen.new()
	font.load_str(input.text + input.placeholder_text)
	apply_font()


func load_lines(from: int, to: int) -> void:
	if not font:
		return
	var s := ""
	for i in range(mini(from, to), mini(maxi(from, to) + 1, input.get_line_count())):
		s += input.get_line(i)
	if font.load_str(s):
		apply_font()


func apply_font() -> void:
	input.remove_theme_font_override("font")
	input.remove_theme_font_size_override("font_size")
	var np = not btn_font.button_pressed
	input_scale.visible = np
	btn_dl.visible = np
	if np:
		input.add_theme_font_size_override("font_size", font.fixed_size * int(input_scale.value))
		input.add_theme_font_override("font", font)


func download(path: String) -> void:
	if not path or not font:
		return
	var fs := font.fixed_size
	var v := SubViewport.new()
	v.transparent_bg = true
	v.render_target_update_mode = SubViewport.UPDATE_ONCE
	var sz := font.get_multiline_string_size(input.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	v.size = Vector2i(sz.ceil()).maxi(1)
	var c := Control.new()
	c.draw.connect(
		func():
			c.draw_multiline_string(
				font, Vector2(0, font.get_ascent(fs)), input.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs
			)
	)
	v.add_child(c)
	add_child(v)
	await RenderingServer.frame_post_draw
	v.get_texture().get_image().save_png(path)
	v.queue_free()
