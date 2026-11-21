# `glyphs.toml`

One limitation of the BDF format is that there is no spec-compliant way to store
custom per-glyph data. To work around this, bited interfaces with a TOML file
colocated with the BDF that follows the pattern `{bdf_basename}.glyphs.toml`.
Like BDF, this file is intended for both human and computer consumption.

!!! warning

    Whenever you rename your BDF, you must also rename the corresponding
    `glyphs.toml` to ensure bited can find it.

## `glyphs.<name>`

This table contains glyph-specific values. Glyphs not specified here will derive
values from the `default` table.

### `is_abs?: bool`

Optional. Whether the glyph is in offset mode (`false`) or dwidth mode (`true`).

### `layers?.[]`

Optional. Layers that compose into the parent glyph.

#### `child: str`

The layer's glyph name.

#### `off_x?: i32`, `off_y?: i32`

The layer's translation offsets. Both default to `0`.

#### `blend?: i32`

The layer's blend mode. Defaults to `0`.

| Index | Blend Mode |
| ----- | ---------- |
| 0     | add        |
| 1     | subtract   |
| 2     | exclude    |
| 3     | multiply   |

#### `xform: i32`

The layer's flips (x/y) and transposition encoded as bits of an int. Defaults to
`0`.

| Bit (LSB) | Value | Transform |
| --------- | ----- | --------- |
| 0         | 1     | flip x    |
| 1         | 2     | flip y    |
| 2         | 4     | transpose |

Transposition is applied before flips.

| Value | Bits  | Steps                     | Result         |
| ----- | ----- | ------------------------- | -------------- |
| 0     | `000` | none                      | identity       |
| 1     | `001` | flip x                    | flip x         |
| 2     | `010` | flip y                    | flip y         |
| 3     | `011` | flip x, flip y            | rotate 180°    |
| 4     | `100` | transpose                 | transpose      |
| 5     | `101` | transpose, flip x         | rotate cw      |
| 6     | `110` | transpose, flip y         | rotate ccw     |
| 7     | `111` | transpose, flip x, flip y | anti-transpose |

## `default`

This table contains fallback values for glyphs not specified in the `glyphs`
table.

| Key      | Default Value |
| -------- | ------------- |
| `is_abs` | `true`        |
