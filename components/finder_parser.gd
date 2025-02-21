class_name FinderParser
extends RefCounted

enum Mode {
	X,
	Q,
	U,
	CAT,
	CAT_,
	PAGE,
	PAGE_,
	BLOCK,
	BLOCK_,
}

var tks_in: PackedStringArray
var qs: PackedStringArray
var binds: Array

var mode := Mode.X
var tks: PackedStringArray


static func from(q: String) -> FinderParser:
	var parser := FinderParser.new()
	parser.tokenize(q)
	parser.parse()
	return parser


func tokenize(q: String) -> void:
	tks_in = q.split(" ")


func parse():
	for w in tks_in:
		match w.to_lower():
			":;":
				next()
				mode = Mode.Q
			":u":
				next()
				mode = Mode.U
			":cat":
				next()
				mode = Mode.CAT
			":cat;":
				next()
				mode = Mode.CAT_
			":page":
				next()
				mode = Mode.PAGE
			":page;":
				next()
				mode = Mode.PAGE_
			":block":
				next()
				mode = Mode.BLOCK
			":block;":
				next()
				mode = Mode.BLOCK_
			"&":
				next()
			_:
				if w:
					tks.append(w)
	next()


func next() -> void:
	match mode:
		Mode.Q:
			if tks:
				qs.append("name like ? escape '\\'")
				binds.append(" ".join(tks))
		Mode.U:
			build_u()
		Mode.CAT:
			build_cat()
		Mode.CAT_:
			build_cat(true)
		Mode.PAGE:
			build_page()
		Mode.PAGE_:
			build_page(true)
		Mode.BLOCK:
			build_block()
		Mode.BLOCK_:
			build_block(true)
		_:
			if tks:
				qs.append("name like ? escape '\\'")
				binds.append("%%%s%%" % " ".join(tks))
	mode = Mode.X
	tks.clear()


func build_u() -> void:
	var xs: PackedStringArray
	for tk in tks:
		if tk:
			if tk.contains("-"):
				var hs := tk.split("-", true, 1)
				xs.append("id between ? and ?")
				binds.append(hs[0].hex_to_int())
				binds.append(hs[1].hex_to_int())
			else:
				xs.append("printf('%X', id) like ? escape '\\'")
				xs.append("printf('%04X', id) like ? escape '\\'")
				binds.append(tk)
				binds.append(tk)
	if xs:
		qs.append("(%s)" % " or ".join(xs))


func build_cat(r := false) -> void:
	var xs: PackedStringArray
	for tk in tks:
		if tk:
			xs.append("category like ? escape '\\'")
			binds.append(("%s" if r else "%%%s%%") % tk)
	if xs:
		qs.append("(%s)" % " or ".join(xs))


func build_page(r := false) -> void:
	if tks:
		StateVars.db_uc.query_with_bindings(
			"select id from pages where name like ? escape '\\';",
			[("%s" if r else "%%%s%%") % " ".join(tks)]
		)
		var xs: PackedStringArray
		for q in StateVars.db_uc.query_result:
			xs.append("select code from p_%s" % q.id)
		if xs:
			qs.append("id in (%s)" % " union ".join(xs))


func build_block(r := false) -> void:
	if tks:
		StateVars.db_uc.query_with_bindings(
			"select start, end from blocks where name like ? escape '\\';",
			[("%s" if r else "%%%s%%") % " ".join(tks)]
		)
		var xs: PackedStringArray
		for q in StateVars.db_uc.query_result:
			xs.append("id between ? and ?")
			binds.append(q.start)
			binds.append(q.end)
		if xs:
			qs.append("(%s)" % " or ".join(xs))


func query() -> String:
	return " and ".join(qs) if qs else "0"
