extends PanelContainer

@export var font_name: Label
@export var settings: Window
@export var btn_save: Button
@export var dialog_file: FileDialog
@export var btn_settings: Button


func _ready() -> void:
	refresh()

	btn_save.pressed.connect(save)
	btn_settings.pressed.connect(settings.popup)
	StateVars.settings.connect(refresh)


func refresh() -> void:
	font_name.text = StateVars.font.family


func save() -> void:
	StateVars.db_locals.query_with_bindings(
		"select path from paths where id = ?", [StateVars.font.id]
	)
	var qs := StateVars.db_locals.query_result
	var path: String
	if qs.is_empty():
		dialog_file.popup()
		path = dialog_file.current_file
		if not path:
			return
		StateVars.db_locals.insert_row("paths", {id = StateVars.font.id, path = path})
	else:
		path = qs[0].path
	# TODO: write to file
	print(path)
