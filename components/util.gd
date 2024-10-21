extends Node


func between(x: int, n0: int, n1: int) -> bool:
	var a := min(n0, n1) as int
	var b := max(n0, n1) as int
	return a <= x and x <= b


func img_copy(im: Image) -> Image:
	return im.get_region(Rect2i(Vector2i.ZERO, im.get_size()))
