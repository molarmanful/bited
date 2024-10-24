extends Window


func _init() -> void:
	hide()
	force_native = true


func _ready() -> void:
	close_requested.connect(hide)
