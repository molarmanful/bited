extends UtilR


## Checks if [param x] is between [param n0] and [param n1] (inclusive).
func between(x: int, n0: int, n1: int) -> bool:
	var a := mini(n0, n1)
	var b := maxi(n0, n1)
	return a <= x and x <= b


## Copies an [Image].
func img_copy(img: Image) -> Image:
	return img.get_region(Rect2i(Vector2i.ZERO, img.get_size()))


## Converts a byte array to an array of hex values.
## Each "row" is padded up to the nearest byte.
func bits_to_hexes(bits: PackedByteArray, w: int, h: int) -> PackedStringArray:
	var chunk := (w + 7) >> 3
	var res := PackedStringArray()
	res.resize(h)

	var i_row := 0
	for i in range(0, bits.size(), chunk):
		var row := ""
		for j in range(chunk):
			var byte := bits[i + j]
			row += "%02X" % byte
		res[i_row] = row
		i_row += 1

	return res
