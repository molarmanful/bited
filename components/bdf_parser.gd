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
## Error message, if any.
var e := ""
## Warning messages, if any.
var warns := PackedStringArray()

## Line number for debugging purposes.
var n_line := 0
## Glyph index for index-dependent data (e.g. [member dws]).
var i_glyph := 0
## Current mode for the parser state machine.
var mode := Mode.PRE

## Already-defined keywords for detecting conflicting definitions.
var defs := {}
## Bit array for determining whether each glyph should default its width.
var dws := BitMap.new()
## In-memory storage of parsed glyphs.
var glyphs := {}

## Data built per glyph parsing iteration.
var gen := gen_default
## Already-defined keywords for detecting conflicting definitions within a glyph.
var gen_defs := {}
## Hex data built per glyph.
var gen_bm := PackedStringArray()

var table_width := -16
var thumb_px_size := 2
var grid_size := 32
var grid_px_size := 12

var gen_default := {
	name = "",
	code = -1,
	dwidth = 0,
	is_abs = false,
	bb_x = 0,
	bb_y = 0,
	off_x = 0,
	off_y = 0,
	img = null,
}


## Parses BDF file.
func from_file(path: String, poll := func(): pass) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	await mparse(
		file.get_line,
		func(): return file.get_position() >= file.get_length(),
		poll
	)


## Executes [method parse] on a separate thread.
## Periodically calls [param poll] for data retrieval.
func mparse(f: Callable, end: Callable, poll := func(): pass) -> void:
	var a := Time.get_unix_time_from_system()

	var id := WorkerThreadPool.add_task(func(): e = parse(f, end), true)
	while not WorkerThreadPool.is_task_completed(id):
		await poll.call()
	WorkerThreadPool.wait_for_task_completion(id)

	printt("parsed", Time.get_unix_time_from_system() - a)


## Parses lines from successive calls of [param f] until [param end] returns true.
func parse(f: Callable, end: Callable) -> String:
	while not end.call():
		n_line += 1
		var l: String = f.call()
		if not l:
			continue

		var line := kv(l)
		if line.w:
			warn(line.w)
			if mode != Mode.BM:
				continue

		if line.k == "COMMENT":
			continue

		match mode:
			Mode.PRE:
				if line.k == "STARTFONT" and notdef("STARTFONT"):
					mode = Mode.X
			Mode.X:
				e = parse_x(line)
			Mode.PROPS:
				e = parse_props(line)
			Mode.CHAR:
				e = parse_char(line)
			Mode.CHAR_IGNORE:
				e = parse_char_ignore(line)
			Mode.BM:
				e = parse_bm(line)

		if e:
			return e
		if mode == Mode.POST:
			return ""

	match mode:
		Mode.CHAR, Mode.BM:
			warn("reached file end while parsing glyph")
			endchar()

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
					warn(
						(
							"XLFD foundry name is empty, defaulting to '%s'"
							% font.foundry
						)
					)
				else:
					font.foundry = xs[1]

				if not xs[2]:
					warn(
						(
							"XLFD family name is empty, defaulting to '%s'"
							% font.family
						)
					)
				else:
					font.family = xs[2]

				if not xs[3]:
					warn(
						(
							"XLFD weight name is empty, defaulting to '%s'"
							% font.weight
						)
					)
				else:
					font.weight = xs[3]

				xs[4] = xs[4].to_upper()
				if not ["R", "I", "O", "RI", "RO"].has(xs[4]):
					warn(
						(
							"XLFD slant is not one of (R, I, O, RI, RO), defaulting to %s"
							% font.slant
						)
					)
				else:
					font.slant = xs[4]

				if not xs[5]:
					warn(
						(
							"XLFD setwidth name is empty, defaulting to '%s'"
							% font.setwidth
						)
					)
				else:
					font.setwidth = xs[5]

				if xs[6]:
					font.addstyle = xs[6]

				if not xs[7].is_valid_int() or int(xs[9]) < 0:
					warn(
						"XLFD pixel size is not a valid int >=0, defaulting to 0"
					)
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
					warn(
						(
							"XLFD spacing is not one of (P, M, C), defaulting to %s"
							% font.spacing
						)
					)
				else:
					font.spacing = xs[11]

				# font.ch_reg = xs[13]
				# font.ch_enc = xs[14]

		"SIZE", "FONTBOUNDINGBOX":
			pass

		"DWIDTH":
			if notdef("DWIDTH"):
				var xs := arr_int(1, line.v)
				if not xs or xs[0] < 0:
					warn("DWIDTH x is not a valid int >=0, defaulting to 0")
				else:
					font.bb.x = xs[0]

		"CONTENTVERSION", "METRICSSET", "SWIDTH", "SWIDTH1", "DWIDTH1", "VVECTOR":
			pass

		"STARTPROPERTIES":
			mode = Mode.PROPS

		"CHARS":
			if notdef("CHARS"):
				var xs := arr_int(1, line.v)
				if "prop BITED_WIDTHS" in defs and xs[0] > dws.get_size().x:
					warn(
						"CHARS > BITED_WIDTHS size, please manually verify BDF integrity"
					)

		"STARTCHAR":
			var x: String = line.v
			if notdef("char " + x):
				mode = Mode.CHAR
				gen.merge(gen_default, true)
				gen.name = x
			else:
				mode = Mode.CHAR_IGNORE

		"ENDFONT":
			mode = Mode.POST

		_:
			warn("unknown keyword %s, skipping" % line.k)

	return ""


## Handles parsing during [constant Mode.PROPS].
func parse_props(line: Dictionary) -> String:
	if line.k == "ENDPROPERTIES":
		mode = Mode.X

	elif notdef("prop " + line.k):
		var v = parse_type(line.v)
		if v == null:
			warn("unable to parse property %s, skipping" % line.k)
		else:
			match line.k:
				"FONT_DESCENT":
					if v is not int or v < 0:
						warn("FONT_DESCENT is not a valid int >= 0, ignoring")
					else:
						font.desc = v

				"CAP_HEIGHT":
					if v is not int or v < 0:
						warn("CAP_HEIGHT is not a valid int >=0, ignoring")
					else:
						font.cap_h = v

				"X_HEIGHT":
					if v is not int or v < 0:
						warn("X_HEIGHT is not a valid int >=0, ignoring")
					else:
						font.x_h = v

				"COPYRIGHT":
					font.copyright = v

				"BITED_DWIDTH":
					if v is not int or v < 0:
						warn("BITED_DWIDTH is not a valid int >=0, ignoring")
					else:
						font.bb.x = v

				"BITED_WIDTHS":
					if v is not String:
						warn("BITED_WIDTHS is not a valid string, ignoring")
					else:
						var data: PackedStringArray = v.split(" ")
						if data.size() < 2 or not data[0].is_valid_int():
							warn(
								"BITED_WIDTHS does not follow a valid format, ignoring"
							)
						else:
							var l := int(data[0])
							var bits := (
								Marshalls
								. base64_to_raw(data[1])
								. decompress_dynamic(
									-1, FileAccess.COMPRESSION_GZIP
								)
							)
							if not bits and v:
								warn(
									"BITED_WIDTHS does not contain valid base64 string, ignoring"
								)
							else:
								dws.data = {size = Vector2i(l, 1), data = bits}

				"BITED_TABLE_WIDTH":
					if v is not int:
						warn("BITED_TABLE_WIDTH is not a valid int, ignoring")
					else:
						table_width = v

				"BITED_TABLE_CELL_SCALE":
					if v is not int or v < 0:
						warn(
							"BITED_TABLE_CELL_SCALE is not a valid int >=0, ignoring"
						)
					else:
						thumb_px_size = v

				"BITED_EDITOR_GRID_SIZE":
					if v is not int or v < 0:
						warn(
							"BITED_EDITOR_GRID_SIZE is not a valid int >=0, ignoring"
						)
					else:
						grid_size = v

			if BFont.is_other_prop(line.k):
				font.props[line.k] = v

	return ""


# Parses a value into a string or number.
func parse_type(v: String) -> Variant:
	if v and v[0] == '"':
		return v.trim_prefix('"').trim_suffix('"').replace('""', '"')
	var res := arr_int(1, v)
	if not res:
		return null
	return res[0]


## Handles parsing during [constant Mode.CHAR].
func parse_char(line: Dictionary) -> String:
	match line.k:
		"ENCODING":
			if notdef_gen("ENCODING"):
				var xs := arr_int(1, line.v)
				if not xs:
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
				gen.is_abs = true
				if i_glyph < dws.get_size().x:
					gen.is_abs = dws.get_bit(i_glyph, 0)

				var xs := arr_int(1, line.v)
				if not xs or xs[0] < 0:
					warn(
						"DWIDTH x is not a valid int >=0, defaulting to font-wide DWIDTH"
					)
				else:
					gen.dwidth = xs[0] - font.dwidth * int(not gen.is_abs)

		"SWIDTH", "SWIDTH1", "DWIDTH1", "VVECTOR":
			pass

		"BITMAP":
			mode = Mode.BM

		"ENDCHAR":
			warn("glyph %s is missing a BITMAP entry" % gen.name)
			endchar()

		_:
			warn(
				(
					"unknown keyword %s in glyph '%s', skipping"
					% [line.k, gen.name]
				)
			)

	return ""


## Handles parsing during [constant Mode.CHAR_IGNORE].
func parse_char_ignore(line: Dictionary) -> String:
	match line.k:
		"ENDCHAR":
			mode = Mode.X
			clrchar()
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
				warn(
					"'%s' is not valid hex, replacing with empty line" % line.k
				)
				gen_bm.append("")
	return ""


## Saves currently-parsing glyph.
func endchar() -> void:
	mode = Mode.X
	gen.img = Util.hexes_to_bits(gen_bm, gen.bb_x, gen.bb_y)
	glyphs[gen.name] = gen
	i_glyph += 1
	clrchar()


## Resets data for next glyph parsing iteration.
func clrchar() -> void:
	gen = {}
	gen_defs.clear()
	gen_bm.clear()


## Tokenizes/pre-parses a line into a key-value pair denoted by keys
## [code]k[/code] and [code]v[/code].
## For single-token lines, [code]v[/code] is empty.
func kv(l: String) -> Dictionary:
	var k := ""
	var v := ""
	var w := ""
	var sv := false
	var kf := false
	for c in l:
		match c:
			" ", "\t", "\r", "\n" when not sv:
				sv = true
			_ when sv:
				v += c
			_:
				c = c.to_upper()
				if mode == Mode.BM:
					if (c < "A" or c > "Z") and (c < "0" or c > "9"):
						w = (
							"invalid char '%s' in BITMAP, replacing with '0'"
							% c
						)
						k += "0"
					else:
						k += c
				elif (
					(c < "A" or c > "Z")
					and not (kf and c >= "0" and c <= "9")
					and c != "_"
				):
					w = "invalid char '%s' in keyword, skipping line" % c
					break
				else:
					k += c
					kf = true

	return {k = k, v = v.strip_edges(false, true), w = w}


## Tokenizes/pre-parses a string into a series of up to [param n] valid
## integers.
func arr_int(n: int, v: String) -> PackedInt64Array:
	var a := 0
	var sg := 1
	var start := false
	var ig := false
	var res := PackedInt64Array()
	for c in v:
		if res.size() >= n:
			start = false
			break

		match c:
			" ", "\t", "\r", "\n":
				if start:
					res.append(sg * a)
					a = 0
					sg = 1
					start = false
					ig = false
			_ when ig:
				continue
			_:
				match c:
					"-" when not start:
						sg = -1
					_ when "0" <= c and c <= "9":
						a *= 10
						a += int(c)
						if a < 0:
							warn("int overflow, setting int to 0")
							a = 0
							ig = true
					_:
						warn("invalid '%s' in int, setting int to 0" % c)
						a = 0
						ig = true
						continue
				start = true

	if start:
		res.append(sg * a)
	return res


## Handles warnings.
func warn(msg: String) -> void:
	var s := "WARN @ line %d: %s" % [n_line, msg]
	print(s)
	warns.push_back(s)


## Handles errors.
func err(msg: String) -> String:
	var s := "ERR @ line %d: %s" % [n_line, msg]
	print(s)
	return s


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
