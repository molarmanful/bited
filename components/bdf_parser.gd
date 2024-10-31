# gdlint: disable=max-returns
class_name BDFParser
extends RefCounted

enum Mode { X, PROPS, CHAR, BM }

var font: Font

var n_line := 0
var mode := Mode.X
var started := false
var defs := {}

var r_ws := RegEx.create_from_string("\\s+")


func _init(f: Font) -> void:
	font = f


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

		if line.k == "STARTFONT":
			if not started:
				started = true
			else:
				warn("extra STARTFONT entry, ignoring")

		elif started:
			match mode:
				Mode.PROPS:
					pass
				Mode.CHAR:
					pass
				Mode.BM:
					pass
				_:
					var e := parse_x(line)
					if e:
						return e

	warn("file ended without ENDFONT")
	return ""


func parse_x(line: Dictionary) -> String:
	match line.k:
		"FONT":
			if notdef("FONT"):
				var xs: Array[String] = line.v.split("-")

				if line.v[0] != "-":
					return "XLFD must start with '-'"
				if xs.size() < 15:
					return "XLFD must have 14 entries"
				if xs.size() > 15:
					warn("XLFD has >14 entries")

				font.foundry = xs[1]
				font.family = xs[2]
				font.weight = xs[3]
				font.slant = xs[4]
				font.setwidth = xs[5]
				font.addstyle = xs[6]
				font.resolution.x = xs[9]
				font.resolution.y = xs[10]
				font.spacing = xs[11]
				font.ch_reg = xs[13]
				font.ch_enc = xs[14]

		"SIZE":
			pass

		"FONTBOUNDINGBOX":
			var xs := arr_int(4, line.v)

			if xs.size() < 4:
				warn("FONTBOUNDINGBOX has <4 valid entries, filling with 0")
				xs.resize(4)
			if xs[0] < 0:
				warn("bounding box x must be >0, defaulting to 0")
				xs[0] = 0
			if xs[1] < 0:
				warn("bounding box y must be >0, defaulting to 0")
				xs[1] = 0

			font.bb.x = xs[0]
			font.bb.y = xs[1]
			font.bb_off.x = xs[2]
			font.bb_off.y = xs[3]

		"METRICSSET":
			var xs := arr_int(1, line.v)
			if xs.is_empty():
				warn("unable to parse METRICSSET, defaulting to 0")
				font.metricsset = 0
			else:
				font.metricsset = xs[0]

		"SWIDTH":
			pass

		"DWIDTH":
			var xs := arr_int(1, line.v)
			if xs.is_empty():
				warn("unable to parse DWIDTH, skipping")
			else:
				font.dwidth = xs[0]

		"SWIDTH1":
			pass

		"DWIDTH1":
			var xs := arr_int(1, line.v)
			if xs.is_empty():
				warn("unable to parse DWIDTH1, skipping")
			else:
				font.dwidth1 = xs[0]

		# TODO: consider using this to calculate dwidths
		"VVECTOR":
			pass

		"STARTPROPERTIES":
			mode = Mode.PROPS

		"STARTCHAR":
			mode = Mode.CHAR
			# TODO: incorporate line.v

		"ENDFONT":
			# TODO: make sure all required entries exist
			return ""

		_:
			if mode == Mode.PROPS:
				pass
			else:
				warn("unknown keyword %s" % line.k)

	return ""


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
		warn("%s already defined, ignoring" % k)
	return not ret
