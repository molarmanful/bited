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

## The First Glyphs

Using the Tree, navigate to `Windows Glyph List 4` and double-click on the
first cell (should be the space character) in the Table.

![main editor at wgl4 with first cell selected](assets/make-glyph-first.png)
/// caption
///

Congratulations! Your font now has a glyph. We'll leave this one blank since it
represents spaces.

When making fonts from scratch, it's pretty useful to have a starter word for
feeling out the letterforms and defining a style. We'll use "adhesion" as our
starter word.

### Tools

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
