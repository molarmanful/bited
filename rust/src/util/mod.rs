use std::iter;

use godot::prelude::*;

#[derive(GodotClass)]
#[class(init, base=Node)]
pub struct UtilR {}

#[godot_api]
impl UtilR {
    pub fn hexes_to_bits_r(
        hexes: impl IntoIterator<Item: AsRef<str>>,
        w: usize,
        h: usize,
    ) -> impl Iterator<Item = u8> {
        let chunk = (w + 7) >> 3;
        hexes
            .into_iter()
            .flat_map(move |row| {
                row.as_ref()
                    .as_bytes()
                    .chunks(2)
                    .map(|cs| u8::from_ascii_bytes_radix(cs, 16).unwrap_or(0))
                    .chain(iter::repeat(0))
                    .take(chunk)
                    .collect::<Vec<_>>()
            })
            .chain(iter::repeat(0))
            .take(chunk * h)
    }
}
