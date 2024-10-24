class_name Grid
extends PanelContainer

@export var node_wrapper: Container
@export var node_cells: TextureRect
@export var node_view_lines: SubViewport
@export var node_lines: Node2D
@export var node_info: Label
@export var node_placeholder: Label

@export_group("Button Groups")
@export var tools_group: ButtonGroup
@export var cmode_group: ButtonGroup

@export_group("Buttons")
@export var btn_undo: Button
@export var btn_redo: Button
@export var btn_flip_x: Button
@export var btn_flip_y: Button
@export var btn_rot_ccw: Button
@export var btn_rot_cw: Button

var dim_grid := 32:
	set(n):
		dim_grid = n
		update_grid()
var w_cell := 12:
	set(n):
		w_cell = n
		update_grid()
var w_grid: int:
	get:
		return dim_grid * w_cell
var size_grid: Vector2i:
	get:
		return Vector2i(w_grid, w_grid)

var to_update_cells := false
var pressed := false

var cells := Image.create_empty(dim_grid, dim_grid, false, Image.FORMAT_LA8)
var tex_cells := ImageTexture.create_from_image(cells)

var toolman := Tool.new(self)
var tool_sel := "pen":
	set(t):
		tool_sel = t
		toolman.tools[tool_sel].pre()
var bitmap := Bitmap.new(dim_grid, cells)
var undoman := UndoRedo.new()


func _ready() -> void:
	refresh()

	theme_changed.connect(update_grid)
	gui_input.connect(oninput)
	StateVars.edit.connect(start_edit)
	StateVars.edit_refresh.connect(refresh)

	tools_group.pressed.connect(func(btn: BaseButton): tool_sel = btn.name)
	cmode_group.pressed.connect(func(btn: BaseButton): toolman.cmode = Tool.CMode[btn.name])

	btn_undo.pressed.connect(undoman.undo)
	btn_redo.pressed.connect(undoman.redo)
	btn_flip_x.pressed.connect(flip_x)
	btn_flip_y.pressed.connect(flip_y)
	btn_rot_ccw.pressed.connect(rot_ccw)
	btn_rot_cw.pressed.connect(rot_cw)


func _process(_delta: float) -> void:
	toolman.tools[tool_sel].handle()
	update_cells()


func oninput(e: InputEvent) -> void:
	if e is not InputEventMouseButton:
		return
	if (
		e is InputEventMouseButton
		and e.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_UP]
	):
		return

	pressed = e.pressed
	toolman.tools[tool_sel].handle(Tool.State.START if pressed else Tool.State.END)


func start_edit(g: Glyph) -> void:
	undoman.clear_history()
	bitmap.data_code = g.data_code
	bitmap.data_name = g.data_name
	bitmap.clear_cells()
	bitmap.save(false)
	refresh()


func refresh() -> void:
	bitmap.restore()

	if not bitmap.data_name:
		node_wrapper.hide()
		node_placeholder.show()
		return
	node_placeholder.hide()
	node_wrapper.show()

	node_cells.texture = tex_cells
	to_update_cells = true
	update_grid()
	set_info()


func update_grid() -> void:
	node_cells.custom_minimum_size = size_grid
	node_cells.self_modulate = get_theme_color("fg")
	node_view_lines.size = size_grid
	node_lines.queue_redraw()


func set_info() -> void:
	var q := StateVars.db_uc.select_rows("data", "id = %d" % bitmap.data_code, ["name", "category"])

	if bitmap.data_code < 0:
		node_info.text = "%s  (custom)" % bitmap.data_name
		return
	if q.is_empty():
		node_info.text = "U+%s  #%d  (undefined)" % [bitmap.data_name, bitmap.data_code]
		return
	node_info.text = (
		"U+%s  #%d  %s  %s" % [bitmap.data_name, bitmap.data_code, q[0].category, q[0].name]
	)


func update_cells() -> void:
	if not to_update_cells:
		return
	to_update_cells = false

	tex_cells.update(cells)


func act_cells(prev: Image) -> void:
	var cs := Util.img_copy(cells)

	undoman.create_action(name)

	undoman.add_undo_method(func(): cells.copy_from(prev) ; to_update_cells = true)
	undoman.add_undo_reference(prev)
	undoman.add_undo_method(bitmap.save)

	undoman.add_do_method(func(): cells.copy_from(cs) ; to_update_cells = true)
	undoman.add_do_reference(cs)
	undoman.add_do_method(bitmap.save)

	undoman.commit_action(false)


func op(f: Callable) -> void:
	var prev = Util.img_copy(cells)
	f.call()
	to_update_cells = true
	act_cells(prev)
	bitmap.save()


func flip_x() -> void:
	op(bitmap.cells.flip_x)


func flip_y() -> void:
	op(bitmap.cells.flip_y)


func rot_ccw() -> void:
	op(bitmap.cells.rotate_90.bind(COUNTERCLOCKWISE))


func rot_cw() -> void:
	op(bitmap.cells.rotate_90.bind(CLOCKWISE))
