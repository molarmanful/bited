class_name Preview
extends PanelContainer

@export var window: Window


func _ready() -> void:
	window.hide()

	window.close_requested.connect(window.hide)


func preview() -> void:
	window.show()
