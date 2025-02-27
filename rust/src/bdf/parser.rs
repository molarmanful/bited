use std::{
    collections::HashSet,
    io::Read,
    str::FromStr,
};

use base64::{
    engine::general_purpose::STANDARD,
    read::DecoderReader,
};
use bitvec::prelude::*;
use flate2::read::GzDecoder;
use godot::meta::ToGodot;

use super::{
    font::BFontR,
    p_gen::PGen,
    prop_val::PropVal,
};

pub struct Parser<'a> {
    pub n_line: usize,
    pub i_glyph: usize,
    font: &'a mut BFontR,
    mode: Mode,
    defs: HashSet<String>,
    dws: BitVec<u8, Msb0>,
    p_gen: PGen,
}

enum Mode {
    Pre,
    X,
    Props,
    Char,
    CharIgnore,
    BM,
    Post,
}

impl<'a> Parser<'a> {
    pub fn new(font: &'a mut BFontR) -> Self {
        Self {
            font,
            n_line: 0,
            mode: Mode::Pre,
            defs: HashSet::new(),
            dws: BitVec::new(),
            p_gen: PGen::new(),
            i_glyph: 0,
        }
    }

    pub fn is_done(&mut self) -> bool {
        matches!(self.mode, Mode::Post)
    }

    pub fn parse_line(&mut self, line: &str) -> Option<String> {
        self.n_line += 1;
        let (k, v) = kv(line);
        if k.is_empty() || k == "COMMENT" {
            return None;
        }

        match self.mode {
            Mode::Pre => self.parse_pre(&k),
            Mode::X => self.parse_x(&k, v),
            Mode::Props => self.parse_props(&k, v),
            Mode::Char => self.parse_char(&k, v),
            Mode::CharIgnore => self.parse_char_ignore(&k),
            Mode::BM => self.parse_bm(&k),
            Mode::Post => None,
        }
    }

    pub fn recover(&mut self) {
        match self.mode {
            Mode::Char | Mode::BM => {
                self.warn("reached file end while parsing glyph");
                self.endchar()
            }
            _ => {}
        }
        self.warn("reached file end without finding ENDFONT")
    }

    pub fn is_other_prop(k: &str) -> bool {
        !matches!(
            k,
            "FOUNDRY"
                | "FAMILY_NAME"
                | "WEIGHT_NAME"
                | "SLANT"
                | "SETWIDTH_NAME"
                | "ADD_STYLE_NAME"
                | "PIXEL_SIZE"
                | "POINT_SIZE"
                | "RESOLUTION_X"
                | "RESOLUTION_Y"
                | "SPACING"
                | "AVERAGE_WIDTH"
                | "CHARSET_REGISTRY"
                | "CHARSET_ENCODING"
                | "FONT_ASCENT"
                | "FONT_DESCENT"
                | "CAP_HEIGHT"
                | "X_HEIGHT"
                | "COPYRIGHT"
                | "BITED_DWIDTH"
                | "BITED_WIDTHS"
                | "BITED_TABLE_WIDTH"
                | "BITED_TABLE_CELL_SCALE"
                | "BITED_EDITOR_GRID_SIZE"
                | "BITED_EDITOR_CELL_SIZE"
        )
    }

    fn parse_pre(&mut self, k: &str) -> Option<String> {
        if k == "STARTFONT" && self.notdef(k) {
            self.mode = Mode::X;
        }
        None
    }

    fn parse_x(&mut self, k: &str, v: &str) -> Option<String> {
        match k {
            "FONT" => {
                if self.notdef(k) {
                    return self.parse_xlfd(v);
                }
            }

            "DWIDTH" => {
                if self.notdef(k) {
                    match one_int(v) {
                        Some(n) => self.font.bb.x = n,
                        None => self.warn("DWIDTH x is not a valid int >=0, defaulting to 0"),
                    }
                }
            }

            "STARTPROPERTIES" => {
                self.notdef(k);
                self.mode = Mode::Props;
            }

            "STARTCHAR" => {
                if self.notdef(&format!("char {}", v)) {
                    self.mode = Mode::Char;
                    self.p_gen = PGen::new();
                    self.p_gen.name = v.to_string();
                } else {
                    self.mode = Mode::CharIgnore;
                }
            }

            "ENDFONT" => self.mode = Mode::Post,

            "SIZE" | "FONTBOUNDINGBOX" | "CONTENTVERSION" | "METRICSSET" | "SWIDTH" | "SWIDTH1"
            | "DWIDTH1" | "VVECTOR" | "CHARS" => {
                self.notdef(k);
            }

            _ => self.warn(&format!("unknown keyword {}, skipping", k)),
        }
        None
    }

    fn parse_props(&mut self, k: &str, v: &str) -> Option<String> {
        if k == "ENDPROPERTIES" {
            self.mode = Mode::X;
        } else if self.notdef(&format!("prop {}", k)) {
            match self.parse_propval(v) {
                Some(pv) => match k {
                    "FONT_DESCENT" => match pv {
                        PropVal::Num(n) if n >= 0 => self.font.desc = n,
                        _ => self.warn("FONT_DESCENT is not a valid int >= 0, ignoring"),
                    },

                    "CAP_HEIGHT" => match pv {
                        PropVal::Num(n) if n >= 0 => self.font.cap_h = n,
                        _ => self.warn("CAP_HEIGHT is not a valid int >= 0, ignoring"),
                    },

                    "X_HEIGHT" => match pv {
                        PropVal::Num(n) if n >= 0 => self.font.x_h = n,
                        _ => self.warn("X_HEIGHT is not a valid int >= 0, ignoring"),
                    },

                    "COPYRIGHT" => self.font.copyright = pv.to_string().into(),

                    "BITED_DWIDTH" => match pv {
                        PropVal::Num(n) if n >= 0 => self.font.bb.x = n,
                        _ => self.warn("BITED_DWIDTH is not a valid int >= 0, ignoring"),
                    },

                    "BITED_WIDTHS" => match pv {
                        PropVal::Str(s) => self.parse_widths(s),
                        _ => self.warn("BITED_WIDTHS is not a string, ignoring"),
                    },

                    "BITED_TABLE_WIDTH" => match pv {
                        PropVal::Num(n) => self.font.table_width = n,
                        _ => self.warn("BITED_TABLE_WIDTH is not a valid int, ignoring"),
                    },

                    "BITED_TABLE_CELL_SCALE" => match pv {
                        PropVal::Num(n) if n >= 0 => self.font.thumb_px_size = n,
                        _ => self.warn("BITED_TABLE_WIDTH is not a valid int >= 0, ignoring"),
                    },

                    "BITED_EDITOR_GRID_SIZE" => match pv {
                        PropVal::Num(n) if n >= 0 => self.font.grid_size = n,
                        _ => self.warn("BITED_TABLE_WIDTH is not a valid int >= 0, ignoring"),
                    },

                    _ => {
                        if Self::is_other_prop(k) {
                            self.font.set_prop(k, pv.to_variant())
                        }
                    }
                },

                _ => self.warn(&format!("unable to parse property {}, skipping", k)),
            }
        }
        None
    }

    fn parse_char(&mut self, k: &str, v: &str) -> Option<String> {
        match k {
            "ENCODING" => {
                if self.p_gen_notdef(k) {
                    match one_int(v) {
                        Some(n) => {
                            self.p_gen.code = n;
                            if n >= 0 {
                                self.p_gen.name = format!("{:04X}", n)
                            }
                        }
                        None => self.warn("ENCODING is not a valid int, defaulting to -1"),
                    }
                }
            }

            "BBX" => {
                let mut bb = arr_int::<i64>(v, 4);
                let bb_x = bb.next()?.map(|n| {
                    n.try_into().unwrap_or_else(|_| {
                        self.warn("bounding box x < 0, defaulting to 0");
                        0
                    })
                });
                let bb_y = bb.next()?.map(|n| {
                    n.try_into().unwrap_or_else(|_| {
                        self.warn("bounding box x < 0, defaulting to 0");
                        0
                    })
                });
                let off_x = bb.next()?;
                let off_y = bb.next()?;
                if bb_x.and(bb_y).and(off_x).and(off_y).is_none() {
                    self.warn("BBX has invalid entries, filling with 0");
                }
                self.p_gen.bb_x = bb_x.unwrap_or(0);
                self.p_gen.bb_y = bb_y.unwrap_or(0);
                self.p_gen.off_x = off_x.unwrap_or(0);
                self.p_gen.off_y = off_y.unwrap_or(0);
            }

            "DWIDTH" => {
                if self.p_gen_notdef(k) {
                    self.p_gen.is_abs = *self.dws.get(self.i_glyph).as_deref().unwrap_or(&true);
                    match one_int::<i32>(v) {
                        Some(n) => {
                            self.p_gen.dwidth = n - self.font.bb.x * (!self.p_gen.is_abs as i32);
                        }
                        None => self.warn(
                            "DWIDTH x is not a valid int >=0, defaulting to font-wide DWIDTH",
                        ),
                    }
                }
            }

            "BITMAP" => self.mode = Mode::BM,

            "ENDCHAR" => {
                self.warn(&format!(
                    "glyph {} is missing a BITMAP entry",
                    self.p_gen.name,
                ));
                self.endchar();
            }

            "SWIDTH" | "SWIDTH1" | "DWIDTH1" | "VVECTOR" => {}

            _ => self.warn(&format!(
                "unknown keyword {} in glyph '{}', skipping",
                k, self.p_gen.name
            )),
        }

        None
    }

    fn parse_char_ignore(&mut self, k: &str) -> Option<String> {
        match k {
            "ENDCHAR" => self.mode = Mode::X,
            _ => {}
        }
        None
    }

    fn parse_bm(&mut self, k: &str) -> Option<String> {
        match k {
            "ENDCHAR" => self.endchar(),
            _ => match usize::from_str_radix(k, 16) {
                Ok(_) => self.p_gen.bm.push(k.to_string()),
                Err(_) => {
                    self.warn(&format!(
                        "'{}' is not valid hex, replacing with empty line",
                        k
                    ));
                    self.p_gen.bm.push("".to_string());
                }
            },
        }
        None
    }

    fn endchar(&mut self) {
        self.mode = Mode::X;
        self.i_glyph += 1;
        self.font
            .set_glyph_pre(&self.p_gen.name, self.p_gen.to_glyph())
    }

    fn parse_xlfd(&mut self, v: &str) -> Option<String> {
        let [
            blank,
            foundry,
            family,
            weight,
            slant,
            setwidth,
            add_style,
            px_size,
            _,
            res_x,
            res_y,
            spacing,
            _,
            _,
            _,
        ] = &v.split('-').map(str::trim).take(15).collect::<Vec<_>>()[..]
        else {
            return Some("XLFD must have 14 entries".to_string());
        };
        if !blank.is_empty() {
            return Some("XLFD must start with '-'".to_string());
        }

        if foundry.is_empty() {
            self.warn(&format!(
                "XLFD foundry name is empty, defaulting to '{}'",
                self.font.foundry,
            ));
        } else {
            self.font.foundry = (*foundry).into();
        }

        if family.is_empty() {
            self.warn(&format!(
                "XLFD family name is empty, defaulting to '{}'",
                self.font.family,
            ));
        } else {
            self.font.family = (*family).into();
        }

        if weight.is_empty() {
            self.warn(&format!(
                "XLFD weight name is empty, defaulting to '{}'",
                self.font.weight,
            ));
        } else {
            self.font.weight = (*weight).into();
        }

        let slant_up = slant.to_uppercase();
        match slant_up.as_str() {
            "R" | "I" | "O" | "RI" | "RO" => self.font.slant = slant_up.into(),
            _ => self.warn(&format!(
                "XLFD slant is not one of (R, I, O, RI, RO), defaulting to '{}'",
                self.font.slant,
            )),
        }

        if setwidth.is_empty() {
            self.warn(&format!(
                "XLFD setwidth name is empty, defaulting to '{}'",
                self.font.setwidth,
            ));
        } else {
            self.font.weight = (*weight).into();
        }

        self.font.add_style = (*add_style).into();

        if let Ok(n) = px_size.parse() {
            self.font.bb.y = n
        } else {
            self.warn(&format!(
                "XLFD pixel size is not a valid int, defaulting to '{}'",
                self.font.bb.y,
            ));
        }

        if let Ok(n) = res_x.parse() {
            self.font.resolution.x = n
        } else {
            self.warn(&format!(
                "XLFD resolution x is not a valid int, defaulting to '{}'",
                self.font.resolution.x,
            ));
        }

        if let Ok(n) = res_y.parse() {
            self.font.resolution.y = n
        } else {
            self.warn(&format!(
                "XLFD resolution y is not a valid int, defaulting to '{}'",
                self.font.resolution.y,
            ));
        }

        let spacing_up = spacing.to_uppercase();
        match spacing_up.as_str() {
            "P" | "M" | "C" => self.font.spacing = spacing_up.into(),
            _ => self.warn(&format!(
                "XLFD slant is not one of (R, I, O, RI, RO), defaulting to '{}'",
                self.font.spacing,
            )),
        }

        None
    }

    fn parse_propval<'c>(&mut self, v: &'c str) -> Option<PropVal<'c>> {
        if v.starts_with('"') {
            let mut cs = v.chars();
            cs.next();
            if !v.ends_with('"') {
                self.warn("string not properly closed");
            } else {
                cs.next_back();
            }
            Some(PropVal::Str(cs.as_str()))
        } else {
            one_int(v).map(PropVal::Num)
        }
    }

    fn parse_widths(&mut self, s: &str) {
        match if let [a, b] = &s.split_whitespace().take(2).collect::<Vec<_>>()[..] {
            a.parse().ok().and_then(|n| {
                let mut buf: Vec<u8> = Vec::with_capacity(n);
                GzDecoder::new(DecoderReader::new(b.as_bytes(), &STANDARD))
                    .read_to_end(&mut buf)
                    .ok()
                    .map(|_| {
                        let mut bits = BitVec::from_vec(buf);
                        bits.truncate(n);
                        bits
                    })
                    .inspect(|bits| {
                        if bits.len() < n {
                            self.warn(&format!(
                                concat!(
                                    "BITED_WIDTHS bit len ({}) < n ({}), ",
                                    "please manually verify BDF integrity"
                                ),
                                bits.len(),
                                n
                            ));
                        }
                    })
            })
        } else {
            None
        } {
            Some(bits) => {
                self.dws = bits;
            }
            None => self.warn("BITED_WIDTHS does not follow a valid format, ignoring"),
        }
    }

    fn notdef(&mut self, k: &str) -> bool {
        let def = self.defs.contains(k);
        if def {
            self.warn(&format!("{} already defined, skipping", k));
        } else {
            self.defs.insert(k.to_string());
        }
        !def
    }

    fn p_gen_notdef(&mut self, k: &str) -> bool {
        let (ok, res) = self.p_gen.notdef(k);
        if let Some(warn) = ok {
            self.warn(&warn);
        }
        res
    }

    fn warn(&mut self, msg: &str) {
        self.font.warn(self.n_line, msg);
    }
}

fn kv(line: &str) -> (String, &str) {
    let l = line.trim();
    let (k, v) = line.split_once(char::is_whitespace).unwrap_or((l, ""));
    (k.to_uppercase(), v.trim_start())
}

fn arr_int<F>(v: &str, n: usize) -> impl Iterator<Item = Option<F>>
where
    F: FromStr,
{
    v.split_whitespace().map(|s| s.parse().ok()).take(n)
}

fn one_int<F>(v: &str) -> Option<F>
where
    F: FromStr,
{
    arr_int(v, 1).next()?
}
