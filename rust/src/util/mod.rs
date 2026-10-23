use std::{
    fmt::Write,
    iter,
};

use godot::prelude::*;

#[derive(GodotClass)]
#[class(init, base=Node)]
pub struct UtilR {}

#[godot_api]
impl UtilR {
    #[func]
    fn bits_to_hexes(bytes: PackedByteArray, _w: u16, h: u16) -> PackedStringArray {
        bytes
            .as_slice()
            .chunks(bytes.len() / usize::from(h))
            .map(|row| {
                let mut s = String::with_capacity(row.len() * 2);
                for byte in row {
                    write!(s, "{byte:02X}").unwrap();
                }
                s.to_godot()
            })
            .collect()
    }

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
