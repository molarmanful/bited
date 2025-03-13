extends Node

@export var tex: TextureRect
@export var view: SubViewport
@export var node_line0: Line2D
@export var node_line1: Line2D


func _ready() -> void:
	update()
	StyleVars.set_thumb.connect(update)


func update():
	var s := StyleVars.thumb_size_cor
	var sz := Vector2i(s, s)
	view.size = sz
	node_line0.points = [Vector2i(0, 0), sz]
	node_line1.points = [Vector2i(s, 0), Vector2i(0, s)]
