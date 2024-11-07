extends PanelContainer

@export var window: Window
@export var btn_start: Button
@export var btn_cancel: Button
@export var dialog_file: FileDialog
@export var bdf_err: NodeBDFErr
@export var bdf_warn: NodeBDFWarn
@export var over_warn: NodeOverWarn
@export var input_path: LineEdit
@export var input_id: IDVal
@export var input_w: SpinBox

var bdfp: BDFParser


func _ready() -> void:
	btn_start.hide()
	dialog_file.add_filter("*.bdf", "BDF Font")
	dialog_file.add_filter("*", "All Files")

	window.about_to_popup.connect(dialog_file.popup)
	window.close_requested.connect(window.hide)
	btn_start.pressed.connect(start)
	btn_cancel.pressed.connect(window.hide)
	dialog_file.file_selected.connect(file_sel)
	dialog_file.canceled.connect(window.hide.call_deferred)
	input_id.text_changed.connect(act_valid)


func file_sel(path: String) -> void:
	bdfp = BDFParser.new()
	var err := bdfp.from_file(path)
	if err:
		window.hide.call_deferred()
		bdf_err.err.call_deferred(err)
		return

	if not bdfp.warns.is_empty():
		window.hide.call_deferred()
		bdf_warn.warn.call_deferred("\n".join(bdfp.warns))
		var ok: bool = await bdf_warn.out
		if not ok:
			return

	window.show()
	input_path.text = path
	input_path.caret_column = input_path.text.length()
	input_id.text = ""
	input_w.value = bdfp.font.dwidth
	act_valid()


# TODO: err msg
func act_valid(_new := input_id.text) -> void:
	if input_id.validate() or not dialog_file.current_file:
		btn_start.hide()
		return
	btn_start.show()


func start() -> void:
	if input_id.validate() or not dialog_file.current_file:
		return

	window.hide()
	var ok := await over_warn.warn(input_id.text)
	if not ok:
		window.show()
		return

	StateVars.font = bdfp.font
	StateVars.font.id = input_id.text
	StateVars.font.init_font()
	var gens: Array[Dictionary]
	gens.assign(bdfp.glyphs.values())
	StateVars.font.save_glyphs(gens)

	StateVars.start_all()
