# Tips & Tricks

Here is an assortment of design tips that I've learned and discovered over the
course of my bitmap font journey, which may help you on your own journey.

## Tradeoffs between different font characteristics

The decisions you make when beginning to design your font play a large part in
determining how your font eventually behaves, as well as the kinds of
compromises you'll eventually have to make as you continue designing that font.

### Proportional vs. Monospaced

![text sample in Times New Roman](assets/times-new-roman.webp)
/// caption
Source: [nypl.org](https://nypl.org)
///

Proportional fonts are suitable for a variety of text use cases. The immediate
benefit of making your font proportional is that you can fit the width to the
glyph, as opposed to the glyph to the width. For example, you can easily make
"m" wider than "x", and "x" wider than "i". This grants you more freedom in
design choices, and makes it far easier to expand your font's Unicode support
without having to compromise compactness.

![htop command in a terminal](assets/htop.png)
/// caption
Source: [htop.dev](https://htop.dev)
///

Monospaced fonts tend to be more niche than proportional fonts, and are
primarily used in data-heavy contexts where having a fixed glyph width is
important. Terminal emulators, for example, rely on the fixed width to properly
display tabular data and render more complex UI elements. The design choices
you can make with a monospaced font are inherently limited by its width
constraint; going back to the previous example, you'd have to make "m", "x",
and "i" the same width. A significant part of your design process will involve
balancing aesthetics and legibility through compromises in compactness and
spacing.

---

The choice between proportional and monospaced is not entirely black-and-white,
however. A proportional font may have monospaced digits for cleaner numerical
formatting. Conversely, a monospaced font may have proportional widths in its
less-used glyphs for the sake of legibility.
