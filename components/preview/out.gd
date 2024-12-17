class_name PreviewOut
extends TextureRect

var lines := PackedStringArray()
var cache := {}
var hi := true
var rscale := 1
var color_fg := Color.WHITE
var color_hi := Color.RED
var img := Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)


func _ready() -> void:
	texture = ImageTexture.create_from_image(img)


func refresh(hard := false) -> void:
	if hard:
		cache.clear()

	var ucs := {}
	for line in lines:
		for c in line:
			var uc := c.unicode_at(0)
			if uc not in cache:
				ucs[uc] = true

	var s := PackedStringArray()
	s.resize(ucs.size())
	s.fill("?")

	(
		StateVars
		. db_saves
		. query_with_bindings(
			(
				"""
				select code, dwidth, is_abs, bb_x, bb_y, off_x, off_y, img
				from font_%s
				where code in (%s)
				"""
				% [StateVars.font.id, ",".join(s)]
			),
			ucs.keys()
		)
	)

	for q in StateVars.db_saves.query_result:
		q.dw = StateVars.font.dwidth * int(not q.is_abs) + q.dwidth
		q.tex = null
		if q.img:
			q.tex = Util.bits_to_alpha(q.img, q.bb_x, q.bb_y)
			q.tex.convert(Image.FORMAT_RGBA8)
			q.rect = Rect2i(Vector2i.ZERO, Vector2i(q.bb_x, q.bb_y))
		cache[q.code] = q

	render()


func render() -> void:
	img.fill(Color.TRANSPARENT)

	var blank := Image.create_empty(
		maxi(1, StateVars.font.dwidth), StateVars.font.bb.y, false, Image.FORMAT_RGBA8
	)
	blank.fill(color_hi)
	var sz_blank := blank.get_size()
	var rect_blank := blank.get_used_rect()

	var pos := Vector2i(0, StateVars.font.asc)
	var mx := Vector2i.ZERO
	for line in lines:
		for c in line:
			var uc := c.unicode_at(0)
			if uc not in cache:
				if hi:
					pos.x += sz_blank.x
				continue

			pos.x += cache[uc].dw

		mx.x = maxi(mx.x, pos.x + StateVars.font.bb.x)
		pos.x = 0
		pos.y += StateVars.font.bb.y
		mx.y = pos.y

	if not mx:
		return
	img.resize(mx.x, mx.y, Image.INTERPOLATE_NEAREST)

	pos = Vector2i(0, StateVars.font.asc)
	for line in lines:
		for c in line:
			var uc := c.unicode_at(0)
			if uc not in cache:
				if hi:
					img.blit_rect(blank, rect_blank, pos - Vector2i(0, StateVars.font.asc))
					pos.x += sz_blank.x
				continue

			var q: Dictionary = cache[uc]
			if q.tex:
				img.blend_rect(q.tex, q.rect, pos + Vector2i(q.off_x, -q.bb_y - q.off_y))
			pos.x += q.dw

		pos.x = 0
		pos.y += StateVars.font.bb.y

	material.set_shader_parameter("mod", color_fg)
	texture.set_image(img)
	scale()


func scale(n := rscale) -> void:
	rscale = n
	custom_minimum_size = img.get_size() * n
