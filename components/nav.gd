extends PanelContainer

@export var preview: Preview
@export var font_name: Label
@export var settings: Window
@export var btn_home: Button
@export var btn_save: Button
@export var btn_preview: Button
@export var dialog_file: FileDialog
@export var btn_settings: Button


func _ready() -> void:
	refresh()

	btn_home.pressed.connect(StateVars.all_start)
	btn_save.pressed.connect(save)
	btn_preview.pressed.connect(preview.preview)
	btn_settings.pressed.connect(settings.popup)
	StateVars.settings.connect(refresh)


func refresh() -> void:
	font_name.text = StateVars.font.family


func save() -> void:
	var path := StateVars.path()
	if not path:
		dialog_file.popup()
		path = dialog_file.current_file
		if not path:
			return
		StateVars.set_path(path)

	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(StateVars.font.to_bdf())
