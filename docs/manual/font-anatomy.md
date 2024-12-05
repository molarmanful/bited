# Anatomy of a Font

![bited font specimen](assets/font.png){ loading=lazy }
/// caption
///

In bited, a **font** is a collection of glyphs which generally share some sort
of style. Creating a font is essentially just creating a bunch of glyphs!

A **glyph** (sometimes used interchangeably with "character"/"char") is a
visual representation of a symbol -- e.g. letters, numbers, punctuation. In
bited, where we'll be working with Unicode bitmap fonts, glyphs represent
Unicode symbols and are constructed from pixels.

## Metrics

The glyph view inside the Editor exposes several metrics as colored grid lines:

![glyph annotated with metrics](assets/glyph.png){ loading=lazy }
/// caption
///

???+ info "Vertical Metrics (from top to bottom)"

    ???+ question "Ascent"

        The topmost edge of the font. Any pixels above the ascent will bleed
        upwards into the previous line.

    ???+ question "Cap Height"

        The height above the baseline of a typical uppercase letter in your
        font.

    ???+ question "X-Height"

        The height above the baseline of a lowercase "x" in your
        font.

    ???+ question "Baseline"

        The line upon which the other vertical metrics are measured.

    ???+ question "Descent"

        The bottommost edge of the font. Any pixels below the descent will
        bleed downwards into the next line.

???+ info "Horizontal Metrics (from left to right)"

    ???+ question "Baseline"

        The line upon which the other horizontal metrics are measured.

    ???+ question "DWidth"

        A glyph-specific metric for the amount of horizontal space this
        character occupies.
