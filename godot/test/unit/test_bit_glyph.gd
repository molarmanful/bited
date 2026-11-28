extends GdUnitTestSuite


func test_create_from_bytes_clears_padding() -> void:
	var g := BitGlyph.create_from_bytes(Vector2i(10, 2), PackedByteArray([0xFF, 0xFF, 0xFF, 0xFF]))
	assert_array(g.to_bytes()).is_equal(PackedByteArray([0xFF, 0xC0, 0xFF, 0xC0]))


func test_used_rect(
	bytes: Array[int],
	expected: Rect2i,
	_test_parameters := [
		[[0, 0, 0, 0, 0, 0, 0, 0], Rect2i()],
		[[0, 0, 0x20, 0, 0, 0x40, 0, 0], Rect2i(2, 1, 8, 2)],
		[[0, 0, 0x10, 0, 0, 0, 0, 0], Rect2i(3, 1, 1, 1)],
	]
) -> void:
	var g := BitGlyph.create_from_bytes(Vector2i(10, 4), PackedByteArray(bytes))
	assert_that(g.used_rect()).is_equal(expected)


func test_get_bit(
	bytes: Array[int],
	p: Vector2i,
	expected: bool,
	_test_parameters := [
		[[0, 0, 0, 0x40], Vector2i(9, 1), true],
		[[0, 0, 0, 0x80], Vector2i(9, 1), false],
		[[0xFF, 0xC0, 0xFF, 0xC0], Vector2i(0, 2), false],
	]
) -> void:
	var g := BitGlyph.create_from_bytes(Vector2i(10, 2), PackedByteArray(bytes))
	assert_bool(g.get_bit(p)).is_equal(expected)


func test_set_bit(
	bytes: Array[int],
	p: Vector2i,
	v: bool,
	expected: Array,
	_test_parameters := [
		[[0xFF, 0xC0, 0xFF, 0x80], Vector2i(9, 1), true, [0xFF, 0xC0, 0xFF, 0xC0]],
		[[0xFF, 0xC0, 0xFF, 0xC0], Vector2i(9, 1), false, [0xFF, 0xC0, 0xFF, 0x80]],
		[[0, 0, 0, 0], Vector2i(10, 0), true, [0, 0, 0, 0]],
		[[0, 0, 0, 0], Vector2i(0, 2), true, [0, 0, 0, 0]],
	]
) -> void:
	var g := BitGlyph.create_from_bytes(Vector2i(10, 2), PackedByteArray(bytes))
	g.set_bit(p, v)
	assert_array(g.to_bytes()).is_equal(PackedByteArray(expected))


func test_op(
	op: Variant.Operator,
	expected: int,
	_test_parameters := [
		[OP_BIT_OR, 0xE0],
		[OP_BIT_AND, 0x80],
		[OP_BIT_XOR, 0x60],
		[OP_SUBTRACT, 0x40],
	]
) -> void:
	var g := BitGlyph.create_from_bytes(Vector2i(8, 1), PackedByteArray([0xC0]))
	g.op(op, BitGlyph.create_from_bytes(Vector2i(8, 1), PackedByteArray([0xA0])))
	assert_array(g.to_bytes()).is_equal(PackedByteArray([expected]))


func test_blit(
	p: Vector2i,
	expected: Array[int],
	_test_parameters := [
		[Vector2i(7, 1), [0xFF, 0xC0, 0xFE, 0x00]],
		[Vector2i(-1, -1), [0xDF, 0xC0, 0xFF, 0xC0]],
	]
) -> void:
	var g := BitGlyph.create_from_bytes(Vector2i(10, 2), PackedByteArray([0xFF, 0xC0, 0xFF, 0xC0]))
	var src := BitGlyph.create_from_bytes(Vector2i(4, 2), PackedByteArray([0xF0, 0x90]))
	g.blit(OP_BIT_XOR, src, p)
	assert_array(g.to_bytes()).is_equal(PackedByteArray(expected))


func test_crop(
	r: Rect2i,
	expected: Array[int],
	_test_parameters := [
		[Rect2i(3, 1, 10, 1), [0xD1, 0xC0]],
		[Rect2i(-3, -1, 8, 2), [0x00, 0x16]],
		[Rect2i(12, 1, 8, 2), [0xC0, 0x00]],
		[Rect2i(-24, 0, 8, 1), [0x00]],
	]
) -> void:
	var g := BitGlyph.create_from_bytes(Vector2i(16, 2), PackedByteArray([0xB3, 0xC5, 0x5A, 0x3C]))
	g.crop(r)
	assert_array(g.to_bytes()).is_equal(PackedByteArray(expected))


func test_translate(
	v: Vector2i,
	expected: Array[int],
	_test_parameters := [
		[Vector2i(3, -1), [0x1F, 0xC0, 0x00, 0x00]],
		[Vector2i(-3, 1), [0x00, 0x00, 0xFE, 0x00]],
	]
) -> void:
	var g := BitGlyph.create_from_bytes(Vector2i(10, 2), PackedByteArray([0xFF, 0xC0, 0xFF, 0xC0]))
	g.translate(v)
	assert_array(g.to_bytes()).is_equal(PackedByteArray(expected))


func test_region(
	r: Rect2i,
	expected: Array[int],
	_test_parameters := [
		[Rect2i(3, 1, 10, 1), [0xD1, 0xC0]],
		[Rect2i(-3, -1, 8, 2), [0x00, 0x16]],
	]
) -> void:
	var g := BitGlyph.create_from_bytes(Vector2i(16, 2), PackedByteArray([0xB3, 0xC5, 0x5A, 0x3C]))
	assert_array(g.region(r).to_bytes()).is_equal(PackedByteArray(expected))


func test_line(
	a: Vector2i,
	b: Vector2i,
	expected: Array[int],
	_test_parameters := [
		[Vector2i(9, 3), Vector2i(1, 0), [0x60, 0x00, 0x18, 0x00, 0x07, 0x00, 0x00, 0xC0]],
		[Vector2i(0, -1), Vector2i(1, 1), [0x80, 0x00, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00]],
	]
) -> void:
	var g := BitGlyph.create(Vector2i(10, 4))
	g.line(a, b)
	assert_array(g.to_bytes()).is_equal(PackedByteArray(expected))


func test_rect(
	r: Rect2i,
	expected: Array[int],
	_test_parameters := [
		[Rect2i(6, 1, 3, 2), [0x80, 0x00, 0x83, 0x80, 0x83, 0x80, 0x80, 0x00]],
		[Rect2i(-2, -1, 14, 6), [0xFF, 0xC0, 0xFF, 0xC0, 0xFF, 0xC0, 0xFF, 0xC0]],
		[Rect2i(10, 0, 2, 4), [0x80, 0x00, 0x80, 0x00, 0x80, 0x00, 0x80, 0x00]],
	]
) -> void:
	var g := BitGlyph.create_from_bytes(
		Vector2i(10, 4), PackedByteArray([0x80, 0, 0x80, 0, 0x80, 0, 0x80, 0])
	)
	g.rect(r)
	assert_array(g.to_bytes()).is_equal(PackedByteArray(expected))


func test_fill(
	v: bool,
	expected: Array[int],
	_test_parameters := [
		[true, [0xFF, 0xC0, 0xFF, 0xC0]],
		[false, [0x00, 0x00, 0x00, 0x00]],
	]
) -> void:
	var g := BitGlyph.create_from_bytes(Vector2i(10, 2), PackedByteArray([0x80, 0x00, 0x00, 0x40]))
	g.fill(v)
	assert_array(g.to_bytes()).is_equal(PackedByteArray(expected))


func test_flip_x(
	size: Vector2i,
	bytes: Array[int],
	expected: Array[int],
	_test_parameters := [
		[Vector2i(10, 2), [0xC0, 0x40, 0x12, 0x80], [0x80, 0xC0, 0x52, 0x00]],
		[Vector2i(16, 1), [0xC0, 0x01], [0x80, 0x03]],
		[Vector2i(0, 2), [], []],
	]
) -> void:
	var g := BitGlyph.create_from_bytes(size, PackedByteArray(bytes))
	g.flip_x()
	assert_array(g.to_bytes()).is_equal(PackedByteArray(expected))


func test_flip_y(
	size: Vector2i,
	bytes: Array[int],
	expected: Array[int],
	_test_parameters := [
		[
			Vector2i(10, 3),
			[0xC0, 0x40, 0x12, 0x80, 0x01, 0x00],
			[0x01, 0x00, 0x12, 0x80, 0xC0, 0x40]
		],
		[Vector2i(0, 2), [], []],
	]
) -> void:
	var g := BitGlyph.create_from_bytes(size, PackedByteArray(bytes))
	g.flip_y()
	assert_array(g.to_bytes()).is_equal(PackedByteArray(expected))


func test_transpose(
	size: Vector2i,
	bytes: Array[int],
	expected: Array[int],
	_test_parameters := [
		[
			Vector2i(9, 3),
			[0x85, 0x80, 0x40, 0x00, 0x23, 0x00],
			[0x80, 0x40, 0x20, 0x00, 0x00, 0x80, 0x20, 0xA0, 0x80],
		],
		[
			Vector2i(3, 9),
			[0x80, 0x40, 0x20, 0x00, 0x00, 0x80, 0x20, 0xA0, 0x80],
			[0x85, 0x80, 0x40, 0x00, 0x23, 0x00],
		],
	]
) -> void:
	var g := BitGlyph.create_from_bytes(size, PackedByteArray(bytes))
	g.transpose()
	assert_array(g.to_bytes()).is_equal(PackedByteArray(expected))


func test_xform(
	m: int,
	expected: Array[int],
	_test_parameters := [
		[5, [0x40, 0x40, 0x80]],
		[6, [0x40, 0x80, 0x80]],
	]
) -> void:
	var g := BitGlyph.create_from_bytes(Vector2i(3, 2), PackedByteArray([0xC0, 0x20]))
	g.xform(m)
	assert_array(g.to_bytes()).is_equal(PackedByteArray(expected))


func test_rotate_cw() -> void:
	var g := BitGlyph.create_from_bytes(Vector2i(3, 2), PackedByteArray([0xC0, 0x20]))
	g.rotate_cw()
	assert_array(g.to_bytes()).is_equal(PackedByteArray([0x40, 0x40, 0x80]))


func test_rotate_ccw() -> void:
	var g := BitGlyph.create_from_bytes(Vector2i(3, 2), PackedByteArray([0xC0, 0x20]))
	g.rotate_ccw()
	assert_array(g.to_bytes()).is_equal(PackedByteArray([0x40, 0x80, 0x80]))


func test_to_image() -> void:
	var g := BitGlyph.create_from_bytes(Vector2i(9, 2), PackedByteArray([0x80, 0x80, 0x01, 0x00]))
	var expected := PackedByteArray()
	for v in [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0]:
		expected.append_array([0xFF, 0xFF * v])
	assert_dict(g.to_image().data).is_equal(
		{"width": 9, "height": 2, "format": "LumAlpha8", "mipmaps": false, "data": expected}
	)


func test_to_image_empty(
	size: Vector2i,
	_test_parameters := [
		[Vector2i(0, 2)],
		[Vector2i(2, 0)],
	]
) -> void:
	assert_object(BitGlyph.create(size).to_image()).is_null()
