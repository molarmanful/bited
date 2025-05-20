class_name FinderTokenizer
extends RefCounted

enum Mode { X, STR, STR_ESC }

const Op: Dictionary[String, String] = {
	AND = "&",
	OR = "|",
	NOT = "!",
	LPAREN = "(",
	RPAREN = ")",
}

var tks: PackedStringArray
var tk := ""
var mode := Mode.X
var balance := 0


static func tokenize(q: String) -> PackedStringArray:
	var ftk := FinderTokenizer.new(q)
	return ftk.tks


func _init(q: String) -> void:
	for c in q:
		match mode:
			Mode.STR:
				tk += c
				match c:
					"\\":
						mode = Mode.STR_ESC
					'"':
						mode = Mode.X

			Mode.STR_ESC:
				if c not in ['"', "\\"]:
					tk += "\\"
				tk += c
				mode = Mode.STR

			_ when c == '"':
				mode = Mode.STR
				next()
				tk += c

			_ when c in [Op.AND, Op.OR, Op.NOT, Op.LPAREN, Op.RPAREN]:
				next()
				if c == Op.LPAREN:
					balance += 1
				if c == Op.RPAREN:
					balance -= 1
				tks.append(c)

			_ when not c.strip_edges():
				next()

			_:
				tk += c

	match mode:
		Mode.STR:
			tk += '"'
		Mode.STR_ESC:
			tk += "\\\\"
	next()

	var l: PackedStringArray
	l.resize(maxi(0, -balance))
	l.fill("(")
	var r: PackedStringArray
	r.resize(maxi(0, balance))
	r.fill(")")
	l.append_array(tks)
	l.append_array(r)
	tks = l


func next() -> void:
	if tk:
		tks.append(tk)
		tk = ""
