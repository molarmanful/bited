import re
import sys
import textwrap
from pathlib import Path

from gdtoolkit.parser import parser
from syntaqlite import FormatError, Syntaqlite

TAG = '"""-- sql\n'
SQ = Syntaqlite()

err = False


def fmt(s: str) -> str:
    global err
    b = s.removeprefix(TAG).removesuffix('"""')
    tabs = b[: len(b) - len(b.lstrip("\t"))]
    b0 = re.sub(r"\{(\d+)\}", r"__HOLE_\1__", textwrap.dedent(b))

    try:
        b1 = SQ.format_sql(b0, keyword_case="lower")
    except FormatError as e:
        print(f"{path}:{s.line}: {e}", file=sys.stderr)
        err = True
        return s

    b1 = re.sub(r"__HOLE_(\d+)__", r"{\1}", b1)
    b1 = re.sub(r"(?m)^(?:  )+", lambda m: "\t" * (len(m[0]) // 2), b1)
    return f'{TAG}{textwrap.indent(b1, tabs)}{tabs}"""'


for path in map(Path, sys.argv[1:]):
    src = out = path.read_text()
    strs = [s.children[0] for s in parser.parse(src).find_data("string")]
    for t in sorted(strs, key=lambda t: t.start_pos, reverse=True):
        if t.startswith(TAG):
            a, b = t.start_pos, t.end_pos
            out = out[:a] + fmt(t) + out[b:]
    if out != src:
        path.write_text(out)

sys.exit(err)
