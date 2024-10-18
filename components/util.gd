extends Node


func img_copy(im: Image) -> Image:
	return im.get_region(Rect2i(Vector2i.ZERO, im.get_size()))
