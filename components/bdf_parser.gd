# gdlint: disable=max-returns
class_name BDFParser
extends RefCounted

enum Mode { X, PROPS, CHAR, CHAR_IGNORE, BM }

var font := BFont.new()

var n_line := 0
var mode := Mode.X
var started := false
var ended := false

var defs := {}
var glyphs := {}

var gen := gen_default
var gen_defs := {}
var gen_w := 0
var gen_h := 0
var gen_bm := PackedByteArray()

var r_ws := RegEx.create_from_string("\\s+")
var gen_default := {
	name = "",
	code = -1,
	dwidth = 0,
	off_x = 0,
	off_y = 0,
	img = null,
}


func from_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	var e := parse(
		func(): return file.get_line(),
		func(): return file.get_position() >= file.get_length(),
	)
	if e:
		err(e)


# TODO: return bool based on success
func parse(f: Callable, end: Callable) -> String:
	while not end.call():
		n_line += 1

		var line := kv(f.call())

		if line.k == "STARTFONT" and notdef("STARTFONT"):
			if not started:
				started = true

		elif started:
			var e := ""
			match mode:
				Mode.PROPS:
					e = parse_props(line)
				Mode.CHAR:
					e = parse_char(line)
				Mode.CHAR_IGNORE:
					e = parse_char_ignore(line)
				Mode.BM:
					e = parse_bm(line)
				Mode.X:
					e = parse_x(line)
			if e:
				return e

		if ended:
			return ""

	warn("file ended without ENDFONT")
	return ""


func parse_x(line: Dictionary) -> String:
	match line.k:
		"FONT":
			if notdef("FONT"):
				var xs: PackedStringArray = line.v.split("-")
				for i in range(xs.size()):
					xs[i] = xs[i].strip_edges()

				if line.v[0] != "-":
					return "XLFD must start with '-'"
				if xs.size() < 15:
					return "XLFD must have 14 entries"

				if not xs[1]:
					warn("XLFD foundry name is empty, defaulting to '%s'" % font.foundry)
				else:
					font.foundry = xs[1]

				if not xs[2]:
					warn("XLFD family name is empty, defaulting to '%s'" % font.family)
				else:
					font.family = xs[2]

				if not xs[3]:
					warn("XLFD weight name is empty, defaulting to '%s'" % font.weight)
				else:
					font.weight = xs[3]

				if not xs[4]:
					warn("XLFD slant is empty, defaulting to '%s'" % font.slant)
				else:
					font.slant = xs[4]

				if not xs[5]:
					warn("XLFD setwidth name is empty, defaulting to '%s'" % font.setwidth)
				else:
					font.setwidth = xs[5]

				if xs[6]:
					font.addstyle = xs[6]

				if not xs[7].is_valid_int() or int(xs[9]) < 0:
					warn("XLFD pixel size is not a valid int >=0, defaulting to 0")
				else:
					font.bb.y = int(xs[7])

				if not xs[9].is_valid_int() or int(xs[9]) < 1:
					warn(
						(
							"XLFD resolution x is not a valid int >0, defaulting to %d"
							% font.resolution.x
						)
					)
				else:
					font.resolution.x = int(xs[9])

				if not xs[10].is_valid_int() or int(xs[10]) < 1:
					warn(
						(
							"XLFD resolution y is not a valid int >0, defaulting to %d"
							% font.resolution.y
						)
					)
				else:
					font.resolution.y = int(xs[10])

				xs[11] = xs[11].to_upper()
				if not ["P", "M", "C"].has(xs[11]):
					warn("XLFD spacing is not one of (P, M, C), defaulting to %s" % font.spacing)
				else:
					font.spacing = xs[11]

				# font.ch_reg = xs[13]
				# font.ch_enc = xs[14]

		"SIZE", "FONTBOUNDINGBOX":
			pass

		"DWIDTH":
			var xs := arr_int(1, line.v)
			if xs.is_empty() or xs[0] < 0:
				warn("DWIDTH x is not a valid int >=0, defaulting to 0")
			else:
				font.bb.x = xs[0]

		"CONTENTVERSION", "METRICSSET", "SWIDTH", "SWIDTH1", "DWIDTH1", "VVECTOR":
			pass

		"STARTPROPERTIES":
			mode = Mode.PROPS

		"CHARS":
			pass

		"STARTCHAR":
			var x: String = line.v.strip_edges()
			if notdef("char " + x):
				mode = Mode.CHAR
				gen.name = x
			else:
				mode = Mode.CHAR_IGNORE

		"ENDFONT":
			# TODO: make sure all required entries exist
			ended = true
			return ""

		_:
			warn("unknown keyword %s in glyph '%s', skipping" % [line.k, gen.name])

	return ""


func parse_props(line: Dictionary) -> String:
	if line.k == "ENDPROPERTIES":
		mode = Mode.X

	elif notdef("prop " + line.k):
		font.props[line.k] = line.v

		match line.k:
			"CAP_HEIGHT":
				var xs := arr_int(1, line.v)
				if xs.is_empty() or xs[0] < 0:
					warn("CAP_HEIGHT is not a valid int >=0, defaulting to 0")
				else:
					font.cap_h = xs[0]

			"X_HEIGHT":
				var xs := arr_int(1, line.v)
				if xs.is_empty() or xs[0] < 0:
					warn("X_HEIGHT is not a valid int >=0, defaulting to 0")
				else:
					font.x_h = xs[0]

	return ""


func parse_char(line: Dictionary) -> String:
	match line.k:
		"ENCODING":
			if notdef_gen("ENCODING"):
				var xs := arr_int(1, line.v)
				if xs.is_empty():
					warn("ENCODING is not a valid int, defaulting to -1")
				else:
					gen.code = xs[0]

		"BBX":
			if notdef_gen("BBX"):
				var xs := arr_int(4, line.v)

				if xs.size() < 4:
					warn("BBX has <4 valid entries, filling with 0")
					xs.resize(4)
				if xs[0] < 0:
					warn("bounding box x is <0, defaulting to 0")
					xs[0] = 0
				if xs[1] < 0:
					warn("bounding box y is <0, defaulting to 0")
					xs[1] = 0

				gen_w = xs[0]
				gen_h = xs[1]
				gen.off_x = xs[2]
				gen.off_y = xs[3]

		"DWIDTH":
			if notdef_gen("DWIDTH"):
				var xs := arr_int(1, line.v)
				if xs.is_empty() or xs[0] < 0:
					warn("DWIDTH x is not a valid int >=0, defaulting to %d" % gen.dwidth)
				else:
					gen.dwidth = xs[0]

		"SWIDTH", "SWIDTH1", "DWIDTH1", "VVECTOR":
			pass

		"BITMAP":
			mode = Mode.BM

		"ENDCHAR":
			endchar()

		_:
			warn("unknown keyword %s, skipping" % line.k)

	return ""


func parse_char_ignore(line: Dictionary) -> String:
	match line.k:
		"ENDCHAR":
			mode = Mode.X
	return ""


func parse_bm(line: Dictionary) -> String:
	match line.k:
		"ENDCHAR":
			endchar()
	return ""


func endchar() -> void:
	mode = Mode.X
	glyphs[gen.name] = gen
	clrchar()


func clrchar() -> void:
	gen = {}
	gen_defs.clear()
	gen_w = 0
	gen_h = 0
	gen_bm.clear()


func kv(l: String) -> Dictionary:
	var res := r_ws.sub(l.strip_edges(true, false), " ").split(" ", true, 1)
	res[0] = res[0].to_upper()
	return {k = res[0].to_upper(), v = res[1] if res.size() > 1 else ""}


func arr_int(n: int, v: String) -> Array[int]:
	var xs := r_ws.sub(v, " ").split(" ")
	var res: Array[int] = []
	for x in xs.slice(0, n):
		if x.is_valid_int():
			res.append(int(x))
	return res


func warn(msg: String) -> void:
	print("WARN @ %d: %s" % [n_line, msg])


func err(msg: String) -> void:
	print("ERR @ %d: %s" % [n_line, msg])


func notdef(k: String) -> bool:
	var ret := k in defs
	if ret:
		warn("%s already defined, skipping" % k)
	else:
		defs[k] = true
	return not ret


func notdef_gen(k: String) -> bool:
	var ret := k in gen_defs
	if ret:
		warn("%s already defined in glyph '%s', skipping" % [k, gen.name])
	else:
		gen_defs[k] = true
	return not ret
