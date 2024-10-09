extends Node

var font := {
	foundry = "bited",
	family = "NEW FONT",
	weight = "Medium",
	slant = "R",
	setwidth = "Normal",
	add_style = "",
	px_size = 16,
	pt_size = 150,
	res_x = 75,
	res_y = 75,
	spacing = "P",
	avg_w = 80,
	ch_reg = "ISO10646",
	ch_enc = "1",
	dw_x = 8,
	dw_y = 0,
	cap_h = 9,
	x_h = 7,
	asc = 14,
	desc = 2,
	props = {}
}

var font_size_calc: Vector2i:
	get:
		return Vector2i(font.avg_w, font.px_size or font.asc + font.desc)

var font_xlfd: String:
	get:
		return (
			"-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s"
			% [
				font.foundry,
				font.family,
				font.weight,
				font.slant,
				font.setwidth,
				font.add_style,
				font.px_size,
				font.pt_size,
				font.res_x,
				font.res_y,
				font.spacing,
				font.avg_w,
				font.ch_reg,
				font.ch_enc,
			]
		)
