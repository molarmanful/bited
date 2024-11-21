class_name PreviewOut
extends Node2D

@export var view: SubViewport
@export var node_tex: TextureRect

var text := ""
var cache := {}
var hi := true
var rscale := 1
var color_fg := Color.WHITE
var color_hi := Color.RED


func _draw() -> void:
	var pos := Vector2i(0, StateVars.font.asc)
	var mx := Vector2i.ZERO
	for line in text.split("\n"):
		for c in line:
			var uc := c.unicode_at(0)
			if uc not in cache:
				if hi:
					var w: int = maxi(1, StateVars.font.dwidth)
					draw_rect(
						Rect2i(
							pos - Vector2i(0, StateVars.font.asc), Vector2i(w, StateVars.font.bb.y)
						),
						color_hi
					)
					pos.x += w
				continue

			var q: Dictionary = cache[uc]
			var dwidth: int = StateVars.font.dwidth if q.dwidth < 0 else q.dwidth
			if q.tex:
				draw_texture(
					q.tex,
					pos + Vector2i(q.off_x, -q.bb_y - q.off_y),
				)
			pos.x += dwidth

		mx.x = maxi(mx.x, pos.x + StateVars.font.bb.x)
		pos.x = 0
		pos.y += StateVars.font.bb.y
		mx.y = pos.y

	node_tex.material.set_shader_parameter("mod", color_fg)
	view.size = mx * rscale
	view.size_2d_override = mx


func refresh(hard := false) -> void:
	if hard:
		cache.clear()

	var ucs := {}
	for c in text:
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
				select code, dwidth, bb_x, bb_y, off_x, off_y, img
				from font_%s
				where code in (%s)
				"""
				% [StateVars.font.id, ",".join(s)]
			),
			ucs.keys()
		)
	)

	for q in StateVars.db_saves.query_result:
		q.tex = (
			ImageTexture.create_from_image(Util.bits_to_alpha(q.img, q.bb_x, q.bb_y))
			if q.img
			else null
		)
		cache[q.code] = q

	queue_redraw()
