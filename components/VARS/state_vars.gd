extends Node

var font := {
	foundry = "bited",
	family = "new font",
	weight = "Medium",
	slant = "R",
	setwidth = "Normal",
	add_style = "",
	px_size = 16,
	pt_size = 150,
	resolution = Vector2i(75, 75),
	spacing = "P",
	avg_w = 80,
	ch_reg = "ISO10646",
	ch_enc = "1",
	dwidth = Vector2i(8, 0),
	cap_h = 9,
	x_h = 7,
	asc = 14,
	desc = 2,
	props = {}
}

var font_size_calc: Vector2i:
	get:
		return Vector2i(font.dwidth.x, font.px_size)

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
				font.resolution.x,
				font.resolution.y,
				font.spacing,
				font.avg_w,
				font.ch_reg,
				font.ch_enc,
			]
		)

@onready var db_uc := SQLite.new()


func _ready():
	db_uc.path = "res://assets/uc.db"
	db_uc.read_only = true
	db_uc.open_db()
