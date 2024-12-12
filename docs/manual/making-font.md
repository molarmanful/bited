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

Once you've finished changing the settings, press "save & close"
(++ctrl+enter++) to go back to the Main Screen.

## The First Glyphs

Using the Tree, navigate to `Windows Glyph List 4` and double-click on the
first cell (should be the space character) in the Table.

![main editor at wgl4 with first cell selected](assets/make-glyph-first.png)
/// caption
///

Congratulations! Your font now has a glyph. We'll leave this one blank since it
represents spaces.

### ADHESION

When making fonts from scratch, it's pretty useful to have a starter word for
feeling out the letterforms and defining a style. We'll use "adhesion" as our
starter word.

Double-click the cell for "a". The tool should be set to pen with default color
mode (++b+q++). Draw the following glyph:

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
