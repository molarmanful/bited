# gdlint: disable=max-returns
class_name BDFParser
extends RefCounted
## Custom BDF parser that builds to [BFont].
##
## This parser targets BDF version 2.2 with 2.1 compatibility. However, the
## implementation is more lenient than the spec and skips parsing unneeded
## fields. Aside from the XLFD (which errors without at least 14 properly
## hyphenated entries), this parser uses warnings to point out potential areas
## of concern for the user.

enum Mode {
	PRE,  ## Initial state prior to STARTFONT.
	X,  ## Base state between STARTFONT and ENDFONT.
	PROPS,  ## State between STARTPROPERTIES and ENDPROPERTIES.
	CHAR,  ## State between STARTCHAR and ENDCHAR.
	CHAR_IGNORE,  ## Error state that ignores conflicting or improperly parsed glyphs.
	BM,  ## State between BITMAP and ENDCHAR.
	POST,  ## Ending state after ENDFONT.
}

## [BFont] to build to.
var font := BFont.new()

## Line number for debugging purposes.
var n_line := 0
## Current mode for the parser state machine.
var mode := Mode.PRE

## Already-defined keywords for detecting conflicting definitions.
var defs := {}
## In-memory storage of parsed glyphs.
var glyphs := {}

## Data built per glyph parsing iteration.
var gen := gen_default
## Already-defined keywords for detecting conflicting definitions within a glyph.
var gen_defs := {}
## Hex data built per glyph.
var gen_bm := PackedStringArray()

var r_ws := RegEx.create_from_string("\\s+")
var gen_default := {
	name = "",
	code = -1,
	dwidth = 0,
	bb_x = 0,
	bb_y = 0,
	off_x = 0,
	off_y = 0,
	img = null,
}


## Parses BDF file.
func from_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	var e := parse(
		func(): return file.get_line(),
		func(): return file.get_position() >= file.get_length(),
	)
	if e:
		err(e)


## Parses lines from successive calls of [param f] until [param end] returns true.
func parse(f: Callable, end: Callable) -> String:
	while not end.call():
		n_line += 1
		var l: String = f.call()
		if l.is_empty():
			continue
		var line := kv(l)
		var e := ""

		match mode:
			Mode.PRE:
				if line.k == "STARTFONT" and notdef("STARTFONT"):
					mode = Mode.X
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
		if mode == Mode.POST:
			return ""

	warn("reached file end without finding ENDFONT")
	return ""


## Handles parsing during [constant Mode.X].
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
			mode = Mode.POST

		_:
			warn("unknown keyword %s in glyph '%s', skipping" % [line.k, gen.name])

	return ""


## Handles parsing during [constant Mode.PROPS].
func parse_props(line: Dictionary) -> String:
	if line.k == "ENDPROPERTIES":
		mode = Mode.X

	elif notdef("prop " + line.k):
		font.props[line.k] = line.v

		match line.k:
			"FONT_DESCENT":
				var xs := arr_int(1, line.v)
				if xs.is_empty():
					warn("FONT_DESCENT is not a valid int, defaulting to 0")
				else:
					font.desc = xs[0]

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


## Handles parsing during [constant Mode.CHAR].
func parse_char(line: Dictionary) -> String:
	match line.k:
		"ENCODING":
			if notdef_gen("ENCODING"):
				var xs := arr_int(1, line.v)
				if xs.is_empty():
					warn("ENCODING is not a valid int, defaulting to -1")
				else:
					gen.code = xs[0]
					if gen.code >= 0:
						gen.name = "%04X" % gen.code

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

				gen.bb_x = xs[0]
				gen.bb_y = xs[1]
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
			warn("glyph %s is missing a BITMAP entry" % gen.name)
			endchar()

		_:
			warn("unknown keyword %s, skipping" % line.k)

	return ""


## Handles parsing during [constant Mode.CHAR_IGNORE].
func parse_char_ignore(line: Dictionary) -> String:
	match line.k:
		"ENDCHAR":
			mode = Mode.X
	return ""


## Handles parsing during [constant Mode.BM].
func parse_bm(line: Dictionary) -> String:
	match line.k:
		"ENDCHAR":
			endchar()
		_:
			if line.k.is_valid_hex_number():
				gen_bm.append(line.k)
			else:
				warn("'%s' is not valid hex, replacing with empty line" % line.k)
				gen_bm.append("")
	return ""


## Saves currently-parsing glyph.
func endchar() -> void:
	mode = Mode.X
	gen.img = Util.hexes_to_bits(gen_bm, gen.bb_x, gen.bb_y)
	glyphs[gen.name] = gen
	clrchar()


## Resets data for next glyph parsing iteration.
func clrchar() -> void:
	gen = {}
	gen_defs.clear()
	gen_bm.clear()


## Tokenizes a line into a key-value pair denoted by keys [code]k[/code] and
## [code]v[/code].
## For single-token lines, [code]v[/code] is empty.
func kv(l: String) -> Dictionary:
	var res := r_ws.sub(l.strip_edges(true, false), " ").split(" ", true, 1)
	res[0] = res[0].to_upper()
	return {k = res[0].to_upper(), v = res[1] if res.size() > 1 else ""}


## Tokenizes a string into a series of up to [param n] valid integers.
func arr_int(n: int, v: String) -> PackedInt64Array:
	var xs := r_ws.sub(v, " ").split(" ")
	var res := PackedInt64Array()
	for x in xs.slice(0, n):
		if x.is_valid_int():
			res.append(int(x))
	return res


## Handles warnings.
func warn(msg: String) -> void:
	print("WARN @ %d: %s" % [n_line, msg])


## Handles errors.
func err(msg: String) -> void:
	print("ERR @ %d: %s" % [n_line, msg])


## Returns whether a keyword [param k] is already defined.
## Warns or adds to [member BDFParser.defs] as side-effects.
func notdef(k: String) -> bool:
	var ret := k in defs
	if ret:
		warn("%s already defined, skipping" % k)
	else:
		defs[k] = true
	return not ret


## Returns whether a keyword [param k] is already defined in the current glyph.
## Warns or adds to [member BDFParser.gen_defs] as side-effects.
func notdef_gen(k: String) -> bool:
	var ret := k in gen_defs
	if ret:
		warn("%s already defined in glyph '%s', skipping" % [k, gen.name])
	else:
		gen_defs[k] = true
	return not ret