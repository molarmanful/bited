# Layer System

As you design your font, you'll often find glyphs that could be composed from
other glyphs. For example, you may want to combine an accent with a base letter.
The layer system lets you build these compositions and keep the design
consistent across the font.

Each layer has an associated glyph, a [blend mode](#blend-modes), and
[transforms](#transforms). Glyphs cannot have layers that cyclically reference
each other.

/// note

In the Editor, glyph in layer mode cannot be drawn on (e.g. with pen/line/rect).
To work around this, you can draw a custom named glyph and use it as a layer.

///

## Views

### Layers

![editor with layers U, combining ring, and overline](assets/layers.png){ loading=lazy }

/// caption

///

As the name suggests, the Layers view displays the glyph's layers as rows.

| Input                           | Action                  |
| ------------------------------- | ----------------------- |
| click, ++shift++/++ctrl++ click | modify layer selection  |
| drag                            | reorder selected layers |
| double-click                    | open layer for editing  |

### Parents

![editor with parents of combining circumflex](assets/parents.png){ loading=lazy }

/// caption

///

The Parents view displays rows of glyphs that contain the current glyph as a
layer. Double-clicking a row opens its glyph for editing.

### Presets

![editor with layer presets for I with circumflex](assets/presets.png){ loading=lazy }

/// caption

///

The Presets view displays some preset compositions for the current glyph.
Compositions may vary in applicability depending on your font's design.
Double-clicking a composition applies its layers to the current glyph.

## Tools

### Pick

Toggles pick mode, which lets you add layers by clicking glyphs on the Table.

### Delete

Deletes selected layers.

### Bake

Flattens all layers into a drawable glyph.

### Blend Modes

In layer mode, the color mode buttons become buttons that change selected
layers' blend modes.

| Blend Mode | Effect                                   |
| ---------- | ---------------------------------------- |
| add        | draw pixels                              |
| subtract   | erase pixels                             |
| exclude    | invert pixels                            |
| multiply   | keep only pixels that overlap this layer |

The grid highlights selected layers' drawn pixels in green and erased pixels in
faded red.

### Transforms

In layer mode, flip/rotate/translate (and the move tool) transform selected
layers. The clear button resets selected layers' transforms (instead of clearing
the grid itself).
