# bited BDF

**Glyph Bitmap Distribution Format** (BDF) is bited's font format of choice.

## Why BDF?

Upon reading the
[Wikipedia entry for BDF](https://en.wikipedia.org/wiki/Glyph_Bitmap_Distribution_Format),
you might get the impression that BDF is an obsolete font format. And while BDF
is pretty old -- after all, it was released in 1987 -- it's still perfectly
usable! Sure, it may not have the fancy Opentype features of more modern
formats, but BDF has plenty going for it.

- **Human-readable**: You can open up a BDF in your text editor of choice and
  directly edit it.
- **Computer-readable**: The BDF structure is very simple and diff-friendly,
  which is great when you want to build tools that can read or edit BDFs.
- **Compatibility**: BDFs are plug-and-play on systems that support them (e.g.
  Linux). Most bitmap fonts that you can find online use BDFs as either source
  or distribution.

## Spec Extensions

bited's extensions to the BDF format occur exclusively as custom properties
prefixed with `BITED_`. This makes bited BDFs fully compatible with the
[X Consortium's BDF 2.1 spec](https://www.x.org/docs/BDF/bdf.pdf). In other
words, you can use bited BDFs as-is anywhere you can use regular BDFs.

### `BITED_DWIDTH`

Default font-wide dwidth. Corresponds to `FONT > default dimensions > w:` in the
Settings Menu.

### `BITED_WIDTHS`

A 2-part string that encodes whether each glyph is in offset or dwidth mode. The
first part is the glyph count. The second part is a gzipped bit sequence, where
0 is offset mode and 1 is dwidth mode. Each bit is matched to its corresponding
glyph based on the BDF's glyph order.

### `BITED_TABLE_WIDTH`

Corresponds to `DISPLAY > table columns`.

### `BITED_TABLE_CELL_SCALE`

Corresponds to `DISPLAY > table cell scale`.

### `BITED_EDITOR_GRID_SIZE`

Corresponds to `DISPLAY > editor grid size`.

### `BITED_EDITOR_CELL_SIZE`

Corresponds to `DISPLAY > editor cell size`.
