use std::iter;

use bitvec::prelude::*;
use godot::{
    classes::{
        Image,
        image,
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
    fn bits_to_hexes(bytes: PackedByteArray, _w: u16, h: u16) -> PackedStringArray {
        bytes
            .as_slice()
            .chunks(bytes.len() / usize::from(h))
            .map(|row| {
                row.iter()
                    .map(|byte| format!("{byte:02X}"))
                    .collect::<Vec<_>>()
                    .concat()
                    .to_godot()
            })
            .collect()
    }

    #[func]
    fn alpha_to_bits(img: Gd<Image>) -> PackedByteArray {
        assert!(img.get_format() == image::Format::LA8);
        let w = img.get_width() as usize;
        let w8 = (w + 7) & !7;
        img.get_data()
            .as_slice()
            .chunks_exact(w * 2)
            .flat_map(|row| {
                row.iter()
                    .skip(1)
                    .step_by(2)
                    .map(|&byte| byte > 0)
                    .chain(iter::repeat(false))
                    .take(w8)
            })
            .collect::<BitVec<u8, Msb0>>()
            .into_vec()
            .into()
    }

    #[func]
    fn bits_to_alpha(bytes: PackedByteArray, w: u16, h: u16) -> Option<Gd<Image>> {
        let bits = BitSlice::<u8, Msb0>::from_slice(bytes.as_slice());
        Image::create_from_data(
            w.into(),
            h.into(),
            false,
            image::Format::LA8,
            &bits
                .chunks_exact(bits.len() / usize::from(h))
                .flat_map(|row| {
                    row.iter()
                        .by_refs()
                        .take(w.into())
                        .flat_map(|&bit| [255, if bit { 255 } else { 0 }])
                })
                .collect(),
        )
    }

    #[func]
    fn img_and(dst: Gd<Image>, src: Gd<Image>) {
        Self::bits_zip(dst, src, |a, b| a & b);
    }

    #[func]
    fn img_or(dst: Gd<Image>, src: Gd<Image>) {
        Self::bits_zip(dst, src, |a, b| a | b);
    }

    #[func]
    fn img_xor(dst: Gd<Image>, src: Gd<Image>) {
        Self::bits_zip(dst, src, |a, b| a ^ b);
    }

    #[func]
    fn img_andn(dst: Gd<Image>, src: Gd<Image>) {
        Self::bits_zip(dst, src, |a, b| a & !b);
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

    fn bits_zip(mut dst: Gd<Image>, src: Gd<Image>, f: fn(u8, u8) -> u8) {
        let w = dst.get_width();
        let h = dst.get_height();
        let format = dst.get_format();
        let new = &dst
            .get_data()
            .as_slice()
            .iter()
            .zip(src.get_data().as_slice())
            .skip(1)
            .step_by(2)
            .flat_map(|(&a, &b)| [255, f(a, b)])
            .collect();
        dst.set_data(w, h, false, format, new);
    }
}
