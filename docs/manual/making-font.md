# Making a Font

For this section, we'll be editing the `unicorn` font we created all the way
back in the "Start Menu" section.

## Settings

After opening up `unicorn` and getting to the Main Screen, the first thing
we'll do is open the Settings Menu (++ctrl+comma++). Verify that it's on the
FONTS tab.

![settings menu for unicorn](assets/make-settings.png)
/// caption
///

!!! tip

    Hover over each settings field's label to get more information about that
    field!

???+ question "foundry name"

    By default, this is `bited`. Feel free to change this to something more
    personalized if you wish.

???+ question "family name"

    By default, this is `new font`. Let's change this to `unicorn`.

!!! note

    If you didn't choose a preset when creating the font, the following metrics
    fields will be `0`.

???+ question "Metrics"

    Let's set:

    - Default dimensions to width `7` and height `17`.
    - Descent to `4` (ascent will automatically update accordingly).
    - Cap height to `9`.
    - X-height to `5`.

Once you've finished changing the settings, save & close (++ctrl+enter++) to go
back to the Main Screen.

## The First Glyph

Using the Tree, navigate to `Windows Glyph List 4` and double-click on the
first cell (should be the space character) in the Table.

![main editor at wgl4 with first cell selected](assets/make-glyph-first.png)
/// caption
///

Congratulations! Your font now has a glyph. We'll leave this one blank since it
represents spaces.

## ADHESION

When making fonts from scratch, it's pretty useful to have a starter word for
feeling out the letterforms and defining a style. We'll use "adhesion" as our
starter word.

### Pen Tool

Double-click the cell for "a" to define it. The tool should be set to pen with
default color mode (++b+q++). Draw the following glyph:

![unicorn glyph for "a"](assets/make-unicorn-a.png)
/// caption
///

!!! tip

    The pen tool's default color mode is the same as first-cell mode (++t++).
    In this mode, the first pixel's color is inverted; as long as the pen is
    held down, that color persists when dragged. This allows you to both draw
    and erase without having to switch modes.

    If you wish to *only* draw or erase, you can press ++w++ or ++e++
    respectively to change the mode.

### Copy/Paste

This "a" we've drawn could easily become a "d" with a bit of tweaking. With the
"a" cell still selected in the table, copy it (++ctrl+c++). Then single-click
the "d" cell and paste (++ctrl+v++).

![main screen result of copying "a" to "d"](assets/make-copy-paste.png)
/// caption
///

Clicking the "d" cell again will send it to the Editor. This will highlight the
"d" cell in purple to indicate it is being edited.

Here's the "d" glyph we'll draw:

![unicorn glyph for "d"](assets/make-unicorn-d.png)
/// caption
///

### Transforms

For "h", we can start by copying "d" and paste it into the "h" cell. We can
then flip horizontally (++shift+h++) and draw the following:

![unicorn glyph for "h"](assets/make-unicorn-h.png)
/// caption
///

!!! note

    The glyphs of our `unicorn` font so far have spacing on both sides, where
    flips are symmetrical. However, if you're working with glyphs with spacing
    on only one side, then you may need to translate the glyph left or right
    (++shift+left++ / ++shift+right++) after flipping.

---

The glyphs for "e" and "s" should be pretty straightforward to draw:

<div class='grid cards' markdown>

![unicorn glyph for "e"](assets/make-unicorn-e.png)
/// caption
///

![unicorn glyph for "s"](assets/make-unicorn-s.png)
/// caption
///

</div>

### DWidth

So far, all of our glyphs have had the same default dwidth, which means that --
up until now -- the font has been monospace. Monospace fonts are useful
primarily in data/programming contexts like terminals, which typically expect
consistent glyph widths. Most bitmap fonts tend to cater to these niches, and
are typically monospace as a result.

However, bited also supports proportional fonts with variable dwidths. These
can be more flexible design-wise than monospace fonts. Let's make `unicorn`
variable!

While editing, you may have noticed these controls above the grid:

![dwidth mode controls](assets/make-dwidth-mode.png)
/// caption
///

bited features two dwidth modes that can be toggled by pressing the `W?`
button:

???+ question "offset (indicated by `o:`)"

    The given input is treated as an offset of the default (font-wide) dwidth.
    Glyphs in offset mode will recalculate their dwidths when the default
    dwidth changes.

    ```
    glyph_dwidth = font_dwidth + offset
    ```

    By default, new glyphs are set to offset by 0.

???+ question "dwidth (indicated by `w:`)"

    The given input is treated as the glyph's dwidth. Unlike in offset mode,
    glyphs in dwidth mode will **not** change their dwidths when the default
    dwidth changes.

Since "i" is a thinner letterform, we'll use an offset of -2:

![unicorn glyph for "i"](assets/make-unicorn-i.png)
/// caption
///

---

The glyphs for "o" and "n" will also be pretty straightforward:

<div class='grid cards' markdown>

![unicorn glyph for "o"](assets/make-unicorn-o.png)
/// caption
///

![unicorn glyph for "n"](assets/make-unicorn-n.png)
/// caption
///

</div>

## Preview

We now have a whole word's worth of glyphs drawn out, but how do we see these
glyphs in action?

In the Navbar, press the "preview font" button (++ctrl+p++).

![preview window](assets/make-preview.png)
/// caption
///

Type "adhesion" into the input, and you should see the fruits of your labor
thus far!

!["adhesion" in unicorn font](assets/make-unicorn-adhesion.png)
/// caption
///

!!! tip

    Preview comes with several text presets that may come in handy as you
    continue designing your font and adding more glyphs.

## HAMBURGEFONTSIV

At this point, you have all the tools you need to finish the rest of the
letterforms. The next word we'll target is "hamburgefontsiv" (weird, I know).
We'll take cues from our existing glyphs to make sure the styles stay
consistent.

<div class='grid cards' markdown>

![unicorn glyph for "m"](assets/make-unicorn-m.png)
/// caption
///

![unicorn glyph for "b"](assets/make-unicorn-b.png)
/// caption
///

![unicorn glyph for "u"](assets/make-unicorn-u.png)
/// caption
///

![unicorn glyph for "r"](assets/make-unicorn-r.png)
/// caption
///

![unicorn glyph for "g"](assets/make-unicorn-g.png)
/// caption
///

![unicorn glyph for "f"](assets/make-unicorn-f.png)
/// caption
///

![unicorn glyph for "t"](assets/make-unicorn-t.png)
/// caption
///

![unicorn glyph for "v"](assets/make-unicorn-v.png)
/// caption
///

</div>

You can preview the letters you've drawn so far using the "hamburgefontsiv"
preset.

![unicorn hamburgefontsiv preview](assets/make-unicorn-hamburgefontsiv.png)
/// caption
///

## Finishing Lowercase

Here's the rest of the lowercase letters:

<div class='grid cards' markdown>

![unicorn glyph for "c"](assets/make-unicorn-c.png)
/// caption
///

![unicorn glyph for "j"](assets/make-unicorn-j.png)
/// caption
///

![unicorn glyph for "k"](assets/make-unicorn-k.png)
/// caption
///

![unicorn glyph for "l"](assets/make-unicorn-l.png)
/// caption
///

![unicorn glyph for "p"](assets/make-unicorn-p.png)
/// caption
///

![unicorn glyph for "q"](assets/make-unicorn-q.png)
/// caption
///

![unicorn glyph for "r"](assets/make-unicorn-r.png)
/// caption
///

![unicorn glyph for "v"](assets/make-unicorn-v.png)
/// caption
///

![unicorn glyph for "w"](assets/make-unicorn-w.png)
/// caption
///

![unicorn glyph for "x"](assets/make-unicorn-x.png)
/// caption
///

![unicorn glyph for "y"](assets/make-unicorn-y.png)
/// caption
///

![unicorn glyph for "z"](assets/make-unicorn-z.png)
/// caption
///

</div>
