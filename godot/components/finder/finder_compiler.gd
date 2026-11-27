class_name FinderCompiler
extends RefCounted

enum Mode { X, Q, U, CAT, CAT_Q, PAGE, PAGE_Q, BLOCK, BLOCK_Q, GLYPH, NAME, NAME_Q }


class Op:
	const Q = ":;"
	const U = ":u"
	const CAT = ":cat"
	const CAT_Q = ":cat;"
	const PAGE = ":page"
	const PAGE_Q = ":page;"
	const BLOCK = ":block"
	const BLOCK_Q = ":block;"
	const GLYPH = ":glyph"
	const NAME = ":name"
	const NAME_Q = ":name;"
	const AND = "&"
	const OR = "|"
	const NOT = "!"
	const LPAREN = "("
	const RPAREN = ")"


class Sep:
	const AND = " and "
	const OR = " or "
	const NOT = "not "


var tks: PackedStringArray
var qs: PackedStringArray
var binds: Array
var i_tks := 0
var skip := 0
var mode := Mode.X
var sep := Sep.AND
var is_not := false
var args: PackedStringArray


static func exec(q: String):
	var fc := FinderCompiler.new()
	fc.tks = FinderTokenizer.tokenize(q)
	fc.parse()

	(
		StateVars
		. db
		. query_with_bindings(
			(
				"""
				delete from temp.full;

				insert into temp.full
				select row_number() over (order by id, g) - 1, g, id
				from (
					select id, name, category, printf('U+%04X', id) as g from uc.data
					union all
					select code, name, null, name from font_{1} where code < 0
				)
				where {0}
				;

				select changes() as count
				;"""
				. format([fc.query(), StateVars.font.id])
			),
			fc.binds
		)
	)


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
			Op.CAT_Q:
				next()
				mode = Mode.CAT_Q
			Op.PAGE:
				next()
				mode = Mode.PAGE
			Op.PAGE_Q:
				next()
				mode = Mode.PAGE_Q
			Op.BLOCK:
				next()
				mode = Mode.BLOCK
			Op.BLOCK_Q:
				next()
				mode = Mode.BLOCK_Q
			Op.GLYPH:
				next()
				mode = Mode.GLYPH
			Op.NAME:
				next()
				mode = Mode.NAME
			Op.NAME_Q:
				next()
				mode = Mode.NAME_Q
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
				var fp := FinderCompiler.new()
				fp.tks = tks.slice(i_tks)
				fp.parse()
				push_qs("({0})".format([fp.query()]))
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
		Mode.CAT_Q:
			build_cat(true)
		Mode.PAGE:
			build_page()
		Mode.PAGE_Q:
			build_page(true)
		Mode.BLOCK:
			build_block()
		Mode.BLOCK_Q:
			build_block(true)
		Mode.GLYPH:
			build_glyph()
		Mode.NAME:
			build_name()
		Mode.NAME_Q:
			build_name(true)
		_:
			build_x()

	mode = Mode.X
	sep = Sep.AND
	args.clear()


func build_u() -> void:
	var xs: PackedStringArray
	for tk in args:
		var hs := Array(tk.to_upper().split("-", true, 1)).map(
			func(h: String): return h.trim_prefix("U+")
		)
		if hs.all(func(h: String): return h.is_valid_hex_number()):
			xs.append("id between ? and ?")
			binds.append(hs[0].hex_to_int())
			binds.append(hs[-1].hex_to_int())
	if xs:
		push_qs("({0})".format([Sep.OR.join(xs)]))


func build_cat(r := false) -> void:
	var xs: PackedStringArray
	for tk in args:
		if tk:
			xs.append("category like ? escape '\\'")
			binds.append(("%s" if r else "%%%s%%") % tk)
	if xs:
		push_qs("({0})".format([Sep.OR.join(xs)]))


func build_page(r := false) -> void:
	var xs: PackedStringArray
	var ys: PackedStringArray
	for tk in args:
		if tk:
			xs.append("name like ? escape '\\'")
			ys.append(("%s" if r else "%%%s%%") % tk)
	if xs:
		StateVars.db.query_with_bindings(
			"select id from uc.pages where {0};".format([" or ".join(xs)]), ys
		)
		xs.clear()
		for q in StateVars.db.query_result:
			xs.append("select code from uc.p_{0}".format([q.id]))
		if xs:
			push_qs("id in ({0})".format([" union ".join(xs)]))


func build_block(r := false) -> void:
	var xs: PackedStringArray
	for tk in args:
		if tk:
			xs.append("b.name like ? escape '\\'")
			binds.append(("%s" if r else "%%%s%%") % tk)
	if xs:
		push_qs(
			(
				"""
				id in (
					select d.id
					from uc.blocks as b
					join uc.data as d on d.id between b.start and b.end - 1
					where {0}
				)
				"""
				. format([Sep.OR.join(xs)])
			)
		)


func build_glyph() -> void:
	push_qs("id in (select code from font_{0})".format([StateVars.font.id]))
	mode = Mode.X
	next()


func build_name(r := false) -> void:
	var xs: PackedStringArray
	for tk in args:
		if tk:
			xs.append("g like ? escape '\\'")
			binds.append(("%s" if r else "%%%s%%") % tk)
	if xs:
		push_qs("({0})".format([Sep.OR.join(xs)]))


func build_x(r := false) -> void:
	if args:
		var xs: PackedStringArray
		for tk in args:
			xs.append("name like ? escape '\\'")
			binds.append(tk if r else "%%%s%%" % tk)
		if xs:
			push_qs("({0})".format([Sep.OR.join(xs)]))


func query() -> String:
	return "".join(qs) if qs else "0"


func push_qs(q: String) -> void:
	if is_not:
		qs.append(Sep.NOT)
	qs.append(q)
	qs.append(sep)
	is_not = false
