# Why bited?

![pokemon emerald](assets/pokemon-emerald.png)
/// caption
///

**I love bitmap fonts**. Whether it's programming in my terminal of choice or
playing games with pixel art styles, I derive an odd enjoyment from seeing
perfectly crisp pixels on my screen. Bitmap fonts are visually sharp with a
tinge of retro; they're astonishingly readable at small sizes and are great for
fitting more text into small screens.

![my terminal](assets/term.png)
/// caption
///

When I first began using bitmap fonts for programming, I periodically switched
between fonts made by others. But as someone who is obsessed with
customization, I found myself yearning for a font that was more... bespoke.
With my bitmap font editor of choice --
[Bits'n'Picas](https://github.com/kreativekorp/bitsnpicas) -- I set to work
creating fonts tailored specifically to my personal taste.

![eldur font](assets/eldur.png)
/// caption
[eldur](https://github.com/molarmanful/eldur), a stylistically unique font that
is perhaps too tiny for practical use.
///

![kirsch font](assets/kirsch.png)
/// caption
[kirsch](https://github.com/molarmanful/kirsch), another stylistically unique
font I now use as my programming font of choice.
///

As I became more familiar with designing bitmap fonts, I began wishing for
features that weren't present in Bits'n'Picas. I tried
[FontForge](https://fontforge.org), but its unintuitive and clunky UI/UX made
for an uncomfortable time. Other editors, for one reason or another, didn't fit
my desired workflow.

And so I decided to build my own.

![thanos meme](assets/thanos.gif)
/// caption
///

## Why BDF?

Reading the [Wikipedia entry for
BDF](https://en.wikipedia.org/wiki/Glyph_Bitmap_Distribution_Format), you might
get the impression that BDF is an obsolete font format. And while BDF is pretty
old -- after all, it was released in 1987 -- it's still perfectly usable! Sure,
it may not have the fancy Opentype features of more modern formats, but BDF has
plenty going for it.

- **Human-readable**: You can open up a BDF in your text editor of choice and
    directly edit it.
- **Computer-readable**: The BDF structure is very simple and diff-friendly,
    which is great when you want to build tools that can read or edit BDFs.
- **Compatibility**: BDFs are plug-and-play on systems that support them (e.g.
    Linux).
