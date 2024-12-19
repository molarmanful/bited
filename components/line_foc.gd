class_name LineFoc
extends LineEdit


func _ready() -> void:
	text_submitted.connect(func(_new: String): release_focus())
