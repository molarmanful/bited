class_name FinderParser
extends RefCounted

enum Mode { X, Q, U, CAT, CAT_, PAGE, PAGE_, BLOCK, BLOCK_ }

const Op: Dictionary[String, String] = {
	Q = ":;",
	U = ":u",
	CAT = ":cat",
	CAT_ = ":cat;",
	PAGE = ":page",
	PAGE_ = ":page;",
	BLOCK = ":block",
	BLOCK_ = ":block;",
	AND = "&",
	OR = "|",
	NOT = "!",
	LPAREN = "(",
	RPAREN = ")",
}

const Sep: Dictionary[String, String] = {
	AND = " and ",
	OR = " or ",
	NOT = "not ",
}

var tks: PackedStringArray
var qs: PackedStringArray
var binds: Array
var i_tks := 0
var skip := 0
var mode := Mode.X
var sep := Sep.AND
var is_not := false
var args: PackedStringArray


static func from(q: String) -> FinderParser:
	var parser := FinderParser.new()
	parser.tks = FinderTokenizer.tokenize(q)
	parser.parse()
	return parser


func parse() -> void:
	for tk in tks:
		i_tks += 1
		if skip > 0:
			skip -= 1
			continue

		match tk.to_lower():
			Op.Q:
				next()
				mode = Mode.Q
			Op.U:
				next()
				mode = Mode.U
			Op.CAT:
				next()
				mode = Mode.CAT
			Op.CAT_:
				next()
				mode = Mode.CAT_
			Op.PAGE:
				next()
				mode = Mode.PAGE
			Op.PAGE_:
				next()
				mode = Mode.PAGE_
			Op.BLOCK:
				next()
				mode = Mode.BLOCK
			Op.BLOCK_:
				next()
				mode = Mode.BLOCK_
			Op.AND:
				sep = Sep.AND
				next()
			Op.OR:
				sep = Sep.OR
				next()
			Op.NOT:
				next()
				is_not = not is_not
			Op.LPAREN:
				next()
				var fp := FinderParser.new()
				fp.tks = tks.slice(i_tks)
				fp.parse()
				push_qs("(%s)" % fp.query())
				binds.append_array(fp.binds)
				skip = fp.i_tks
			Op.RPAREN:
				break
			_ when tk.begins_with('"'):
				args.append(JSON.parse_string(tk))
			_ when tk:
				args.append(tk)

	next()
	if qs and [Sep.AND, Sep.OR].has(qs[-1]):
		qs.resize(qs.size() - 1)


func next() -> void:
	match mode:
		Mode.Q:
			build_x(true)
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
			build_x()

	mode = Mode.X
	sep = Sep.AND
	args.clear()


func build_u() -> void:
	var xs: PackedStringArray
	for tk in args:
		if tk:
			if tk.contains("-"):
				var hs := tk.split("-", true, 1)
				if hs[0].is_valid_hex_number() and hs[1].is_valid_hex_number():
					xs.append("id between ? and ?")
					binds.append(hs[0].hex_to_int())
					binds.append(hs[1].hex_to_int())
			else:
				xs.append("printf('%X', id) like ? escape '\\'")
				xs.append("printf('%04X', id) like ? escape '\\'")
				xs.append("printf('%06X', id) like ? escape '\\'")
				binds.append(tk)
				binds.append(tk)
				binds.append(tk)
	if xs:
		push_qs("(%s)" % Sep.OR.join(xs))


func build_cat(r := false) -> void:
	var xs: PackedStringArray
	for tk in args:
		if tk:
			xs.append("category like ? escape '\\'")
			binds.append(("%s" if r else "%%%s%%") % tk)
	if xs:
		push_qs("(%s)" % Sep.OR.join(xs))


func build_page(r := false) -> void:
	var xs: PackedStringArray
	var ys: PackedStringArray
	for tk in args:
		if tk:
			xs.append("name like ? escape '\\'")
			ys.append(("%s" if r else "%%%s%%") % tk)
	if xs:
		StateVars.db_uc.query_with_bindings(
			"select id from pages where %s;" % " or ".join(xs), ys
		)
		xs.clear()
		for q in StateVars.db_uc.query_result:
			xs.append("select code from p_%s" % q.id)
		if xs:
			push_qs("id in (%s)" % " union ".join(xs))


func build_block(r := false) -> void:
	var xs: PackedStringArray
	var ys: PackedStringArray
	for tk in args:
		if tk:
			xs.append("name like ? escape '\\'")
			ys.append(("%s" if r else "%%%s%%") % tk)
	if xs:
		StateVars.db_uc.query_with_bindings(
			"select start, end from blocks where %s;" % " or ".join(xs), ys
		)
		xs.clear()
		for q in StateVars.db_uc.query_result:
			xs.append("id between ? and ?")
			binds.append(q.start)
			binds.append(q.end - 1)
		if xs:
			push_qs("(%s)" % Sep.OR.join(xs))


func build_x(r := false) -> void:
	if args:
		var xs: PackedStringArray
		for tk in args:
			xs.append("name like ? escape '\\'")
			binds.append(tk if r else "%%%s%%" % tk)
		if xs:
			push_qs("(%s)" % Sep.OR.join(xs))


func query() -> String:
	return "".join(qs) if qs else "0"


func push_qs(q: String) -> void:
	if is_not:
		qs.append(Sep.NOT)
	qs.append(q)
	qs.append(sep)
	is_not = false
