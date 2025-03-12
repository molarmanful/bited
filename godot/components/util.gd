extends UtilR


## Checks if [param x] is between [param n0] and [param n1] (inclusive).
func between(x: int, n0: int, n1: int) -> bool:
	var a := mini(n0, n1)
	var b := maxi(n0, n1)
	return a <= x and x <= b


## Copies an [Image].
func img_copy(img: Image) -> Image:
	return img.get_region(Rect2i(Vector2i.ZERO, img.get_size()))
