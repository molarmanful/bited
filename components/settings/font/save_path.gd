extends LineEdit

@export var btn: Button
@export var dialog_file: FileDialog


func _ready() -> void:
	btn.pressed.connect(browse)


func save() -> void:
	StateVars.set_path(text)


func load() -> void:
	text = StateVars.path()


func browse() -> void:
	dialog_file.popup()
	var path := dialog_file.current_file
	if not path:
		return
	text = path
