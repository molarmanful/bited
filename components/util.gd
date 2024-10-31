extends Node


func between(x: int, n0: int, n1: int) -> bool:
	var a := min(n0, n1) as int
	var b := max(n0, n1) as int
	return a <= x and x <= b


func img_copy(im: Image) -> Image:
	return im.get_region(Rect2i(Vector2i.ZERO, im.get_size()))


func alpha_to_bits(img: Image) -> PackedByteArray:
	var res := PackedByteArray()
	var byte := 0
	var pos := 7
	var w8 := (img.get_width() + 7) & ~7
	for y in range(img.get_height()):
		for x in range(w8):
			var bit := 0
			if x < img.get_width():
				bit = img.get_pixel(x, y).a > 0
			byte |= bit << pos
			pos -= 1

			if pos < 0:
				res.push_back(byte)
				byte = 0
				pos = 7

	return res


func bits_to_hexes(data: PackedByteArray, w: int) -> PackedStringArray:
	var chunk := (w + 7) >> 3
	var res: PackedStringArray = []
	for i in range(0, data.size(), chunk):
		var row := ""
		for j in range(chunk):
			var byte := data[i + j]
			row += "%02X" % byte
		res.append(row)
	return res

# func bits_to_alpha(data: PackedByteArray, w: int, h: int) -> Image:
# 	pass
