use std::iter;

use bitvec::prelude::*;
use godot::{
    classes::{
        Image,
        image::Format,
    },
    prelude::*,
};

#[derive(GodotClass)]
#[class(base=Node)]
pub struct UtilR {
    base: Base<Node>,
}

#[godot_api]
impl INode for UtilR {
    fn init(base: Base<Node>) -> Self {
        Self { base }
    }
}

#[godot_api]
impl UtilR {
    #[func]
    fn hexes_to_bits(hexes: PackedStringArray, w: u16, h: u16) -> PackedByteArray {
        Self::hexes_to_bits_r(
            hexes.as_slice().iter().map(GString::to_string),
            w.into(),
            h.into(),
        )
        .collect()
    }

    #[func]
    fn alpha_to_bits(img: Gd<Image>) -> PackedByteArray {
        assert!(img.get_format() == Format::LA8);
        let w = img.get_width() as usize;
        let w8 = (w + 7) & !7;
        img.get_data()
            .as_slice()
            .chunks_exact(w * 2)
            .flat_map(|row| {
                row.iter()
                    .skip(1)
                    .step_by(2)
                    .map(|&x| x > 0)
                    .chain(iter::repeat(false))
                    .take(w8)
            })
            .collect::<BitVec<u8, Msb0>>()
            .into_vec()
            .into()
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
                    .map(|cs| u8::from_ascii_radix(cs, 16).unwrap_or(0))
                    .chain(iter::repeat(0))
                    .take(chunk)
                    .collect::<Vec<_>>()
            })
            .chain(iter::repeat(0))
            .take(chunk * h)
    }
}
