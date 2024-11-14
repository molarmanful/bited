class_name Preview
extends PanelContainer

@export var window: Window
@export var presets: OptionButton
@export var input: TextEdit
@export var btn_hi: Button
@export var out: PreviewOut
@export var scroll_out: ScrollContainer

var preset_tree := {
	"BASIC":
	[
		"hamburgefontsiv",
		"grumpy wizards",
		"boxing wizards",
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
	input.text_changed.connect(preview.bind(false))
	btn_hi.toggled.connect(
		func(on: bool):
			out.hi = on
			preview()
	)


func preset(i: int) -> void:
	var file := FileAccess.open(
		"res://assets/preview/%s.txt" % presets.get_item_text(i), FileAccess.READ
	)
	input.text = file.get_as_text()
	input.set_v_scroll(0)
	scroll_out.set_v_scroll(0)
	preview()


func preview(hard := false) -> void:
	out.color_fg = get_theme_color("fg")
	out.color_hi = get_theme_color("danger")
	out.text = input.text
	out.refresh(hard)
	window.popup()
	input.grab_focus()
