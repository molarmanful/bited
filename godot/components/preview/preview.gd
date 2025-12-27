class_name Preview
extends PanelContainer

@export var window: Window
@export var presets: OptionButton
@export var input: TextEdit
@export var node_split: SplitContainer
@export var btn_split: Button
@export var btn_hi: Button
@export var btn_dl: Button
@export var input_scale: SpinBox
@export var out: PreviewOut
@export var scroll_out: ScrollContainer
@export var file_dl: FileDialog

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
	node_split.vertical = StateVars.cfg.get_value(
		"display", "preview_split", false
	)

	presets.add_separator("PRESETS")
	for k in preset_tree.keys():
		presets.add_separator(k)
		for p in preset_tree[k]:
			presets.add_item(p)
	presets.select(0)

	StateVars.refresh.connect(
		func(_gen: Dictionary):
			if window.visible:
				preview(true)
	)
	StateVars.edit_refresh.connect(
		func():
			if window.visible:
				preview(true)
	)
	StyleVars.theme_changed.connect(
		func():
			if window.visible:
				preview()
	)
	window.close_requested.connect(
		func():
			window.hide()
			out.cache.clear()
	)
	presets.item_selected.connect(preset)
	input.text_changed.connect(
		func():
			presets.selected = 0
			preview(false)
	)
	btn_split.pressed.connect(
		func():
			node_split.vertical = not node_split.vertical
			StateVars.cfg.set_value(
				"display", "preview_split", node_split.vertical
			)
			StateVars.cfg.save("user://settings.ini")
	)
	btn_hi.toggled.connect(
		func(on: bool):
			out.hi = on
			preview()
	)
	btn_dl.pressed.connect(file_dl.popup)
	file_dl.file_selected.connect(
		func(path: String):
			if not path:
				return
			out.texture.get_image().save_png(path)
	)
	input_scale.value_changed.connect(out.scale)


func preset(i: int) -> void:
	var file := FileAccess.open(
		"res://assets/preview/%s.txt" % presets.get_item_text(i),
		FileAccess.READ
	)
	input.text = file.get_as_text()
	input.set_v_scroll(0)
	scroll_out.set_v_scroll(0)
	preview()


func preview(hard := false) -> void:
	out.color_fg = get_theme_color("fg")
	out.color_hi = get_theme_color("danger")
	out.lines = input.text.split("\n")
	out.refresh(hard)
	window.popup()
	input.grab_focus()
