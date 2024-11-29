# Start Menu

When you first open bited, you'll see this screen:

![bited start menu](assets/start.png){ loading=lazy }

Let's see what each of these buttons do.

## New

This is what you press when you want to create a new font from scratch.
Pressing "new" (or its keybind ++1++) will bring up the following dialog:

![bited dialog for creating a new font](assets/new.png){ loading=lazy }

`font id`

: A unique "file name" for your font. May only contain `a-z`, `0-9`, and `_`.
In the simplest cases, this may just be the name of your font. If you're making
multiple variations on one font, the ID may also contain other pieces of info
to distinguish it (e.g. `helvetica_bold` vs. `helvetica_regular`).

    For now, let's set this to `unicorn`. If you don't like this name
    (highly unlikely), you can always change it later.

`preset`

: Some optional starting templates for your font's metrics: height/width,
ascender/descender, cap-height, x-height.

    Feel free to pick one or leave blank.

Once you've entered in a `font id`, a "start" button should appear. Let's press
it and see what happens.

!!! tip

    For all dialogs, you can trigger "OK"-type buttons with ++ctrl+enter++, and
    "cancel"-type buttons with ++esc++.

## Load

![bited dialog for loading fonts](assets/load.png){ loading=lazy }

## Import

![bited dialog for importing a font from BDF](assets/import.png){ loading=lazy }
