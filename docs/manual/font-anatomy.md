# Anatomy of a Font

In bited, a **font** is a collection of glyphs which generally share some sort
of style. Creating a font is essentially just creating a bunch of glyphs!

![bited font specimen](assets/font.png){ loading=lazy }
/// caption
///

A **glyph** (sometimes used interchangeably with "character"/"char") is a
visual representation of a symbol -- e.g. letters, numbers, punctuation. In
bited, where we'll be working with Unicode bitmap fonts, glyphs represent
Unicode symbols and are constructed from pixels.

## Metrics

The glyph view inside the Editor exposes several metrics as colored grid lines:

![glyph annotated with metrics](assets/glyph.png){ loading=lazy }
/// caption
///

???+ info "Horizontal Metrics (from left to right)"

    ???+ question "Baseline"

        The line upon which the other horizontal metrics are measured.

    ???+ question "DWidth"

        A glyph-specific metric for the amount of horizontal space this
        character occupies.

???+ info "Vertical Metrics (from top to bottom)"

    ???+ question "Ascent"

        The topmost edge of the font. Any pixels above the ascent will bleed
        upwards into the previous line.

    ???+ question "Cap Height"

        The height above the baseline of a typical uppercase letter in your
        font.

        This metric is purely for designer use; it isn't used in any
        font-related calculations.

    ???+ question "X-Height"

        The height above the baseline of a lowercase "x" in your font.

        This metric is purely for designer use; it isn't used in any
        font-related calculations.

    ???+ question "Baseline"

        The line upon which the other vertical metrics are measured.

    ???+ question "Descent"

        The bottommost edge of the font. Any pixels below the descent will
        bleed downwards into the next line.

Typesetting glyphs relies on boxes formed from each glyph's ascent, descent,
horizontal baseline, and dwidth. In other words:

- Given two consecutive glyphs, the next glyph's horizontal baseline and the
  previous glyph's dwidth will be touching.
- Given two consecutive lines of glyphs, the next line's ascent and the
  previous line's descent will be touching.

When choosing your bitmap font's metrics, you should make sure to reserve
enough space so that glyphs don't crowd each other out.

!!! tip

    Here are some other useful things to know about these metrics:

    - Font size can be determined by adding the ascent and descent.
    - Diacritics will typically go between the ascent and cap height or between
      the descent and vertical baseline. If you're planning on adding glyphs
      with diacritics, make sure to also reserve space for these.
