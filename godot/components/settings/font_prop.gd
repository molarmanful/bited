class_name FontProp
extends HBoxContainer

const ScnFontProp := preload("font_prop.tscn")

@export var text_key: Label
@export var input_type: OptionButton
@export var input_str: LineEdit
@export var input_num: SpinBox
@export var btn_del: Button

var props: Dictionary
var type := 0:
	set(t):
		type = t
		if type:
			input_str.hide()
			input_num.show()
		else:
			input_num.hide()
			input_str.show()
var key: String
var val: Variant = ""


static func create(p: Dictionary) -> FontProp:
	var prop: FontProp = ScnFontProp.instantiate()
	prop.props = p
	return prop


func _ready() -> void:
	refresh()

	btn_del.pressed.connect(del)
	input_type.item_selected.connect(func(sel: int): type = sel)


func save() -> void:
	props[key] = input_num.value as int if type else input_str.text


func load() -> void:
	val = props[key]
	type = val is int
	refresh()


func del() -> void:
	props.erase(key)
	queue_free()


func refresh() -> void:
	text_key.text = key
	input_type.selected = type
	if type:
		input_num.value = val
	else:
		input_str.text = val
