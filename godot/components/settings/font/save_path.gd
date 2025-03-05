extends LineEdit

@export var btn: Button
@export var dialog_file: FileDialog


func _ready() -> void:
	btn.pressed.connect(dialog_file.popup)
	dialog_file.file_selected.connect(set_text)


func save() -> void:
	StateVars.set_path(text)


func load() -> void:
	text = StateVars.path()
