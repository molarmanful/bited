extends PanelContainer

@export var node_glyphs: Container
@export var scroller: ScrollContainer
@export var virt: Virt

var scrolling := false
var v_scroll := 0


func _ready() -> void:
	for c in 256:
		var glyph := Glyph.create(c)
		node_glyphs.add_child(glyph)

	scroller.scroll_ended.connect(func(): scrolling = false)
	scroller.scroll_started.connect(func(): scrolling = true)


func _process(_delta: float) -> void:
	if scrolling:
		onscroll()


func _gui_input(e: InputEvent):
	if e is InputEventMouseButton and e.is_pressed():
		match e.button_index:
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
				onscroll()


func onscroll():
	var cur := int(get_global_transform_with_canvas().get_origin().y)
	if v_scroll != cur:
		v_scroll = cur
