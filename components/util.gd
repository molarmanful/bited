extends Node


func between(x: int, n0: int, n1: int) -> bool:
	var a := min(n0, n1) as int
	var b := max(n0, n1) as int
	return a <= x and x <= b


func img_copy(im: Image) -> Image:
	return im.get_region(Rect2i(Vector2i.ZERO, im.get_size()))


func alpha_to_bits(img: Image) -> PackedByteArray:
	var res := PackedByteArray()
	var h := img.get_height()
	var w := img.get_width()
	var w8 := (w + 7) & ~7
	res.resize(w8 / 8 * h)

	var byte := 0
	var pos := 7
	var i_res := 0
	for y in range(h):
		for x in range(w8):
			var bit := 0
			if x < w:
				bit = img.get_pixel(x, y).a > 0
			byte |= bit << pos
			pos -= 1

			if pos < 0:
				res[i_res] = byte
				i_res += 1
				byte = 0
				pos = 7

	return res


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


func hexes_to_bits(hexes: PackedStringArray, w: int, h: int) -> PackedByteArray:
	var chunk := (w + 7) >> 3
	var res := PackedByteArray()
	res.resize(h * chunk)

	var i_res := 0
	for row in hexes:
		for i in range(0, row.length(), 2):
			res[i_res] = row.substr(i, 2).hex_to_int()
			i_res += 1

	return res


func bits_to_alpha(bits: PackedByteArray, w: int, h: int) -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_LA8)

	var pos := 7
	var i_bits := 0
	for y in h:
		pos = 7
		for x in w:
			img.set_pixel(x, y, Color(1, 1, 1, (bits[i_bits] >> pos) & 1))
			pos -= 1

			if pos < 0:
				pos = 7
				i_bits += 1

		i_bits += int(w % 8 > 0)

	return img
