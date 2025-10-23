use std::{
    error::Error,
    io::{
        BufRead,
        Read,
    },
    time::Instant,
};

use godot::{
    classes::{
        IRefCounted,
        RefCounted,
        file_access::ModeFlags,
    },
    prelude::*,
};

use super::{
    glyphs_map::GlyphsMap,
    parser::Parser,
};

#[derive(GodotClass)]
#[class(base=RefCounted)]
pub struct BFontR {
    base: Base<RefCounted>,
    #[var]
    pub foundry: GString,
    #[var]
    pub family: GString,
    #[var]
    pub weight: GString,
    #[var]
    pub slant: GString,
    #[var]
    pub setwidth: GString,
    #[var]
    pub add_style: GString,
    #[var]
    pub bb: Vector2i,
    #[var]
    pub resolution: Vector2i,
    #[var]
    pub spacing: GString,
    #[var]
    pub ch_reg: GString,
    #[var]
    pub ch_enc: GString,
    #[var]
    pub desc: i32,
    #[var]
    pub cap_h: i32,
    #[var]
    pub x_h: i32,
    #[var]
    pub copyright: GString,
    #[var]
    pub table_width: i32,
    #[var]
    pub thumb_px_size: i32,
    #[var]
    pub grid_size: i32,
    #[var]
    pub grid_px_size: i32,
    #[var]
    warns: PackedStringArray,
    #[var]
    props: Dictionary,
    #[var]
    glyphs: Dictionary,
}

#[godot_api]
impl IRefCounted for BFontR {
    fn init(base: Base<RefCounted>) -> Self {
        Self {
            base,
            warns: PackedStringArray::new(),
            foundry: "bited".into(),
            family: "new font".into(),
            weight: "Regular".into(),
            slant: "R".into(),
            setwidth: "Normal".into(),
            add_style: "".into(),
            bb: Vector2i::ZERO,
            resolution: Vector2i::new(75, 75),
            spacing: "P".into(),
            ch_reg: "ISO10646".into(),
            ch_enc: "1".into(),
            desc: 0,
            cap_h: 0,
            x_h: 0,
            copyright: "".into(),
            table_width: -16,
            thumb_px_size: 2,
            grid_size: 32,
            grid_px_size: 12,
            props: Dictionary::new(),
            glyphs: Dictionary::new(),
        }
    }
}

#[godot_api]
impl BFontR {
    #[func]
    pub fn read_file(&mut self, path: GString) -> GString {
        (&match GFile::open(&path, ModeFlags::READ) {
            Ok(file) => {
                let start = Instant::now();
                let path = path.to_string();
                let base = path.strip_suffix(".bdf").unwrap_or(&path);
                let gm = self.read_glyphs_map(&format!("{base}.glyphs.toml"));
                let e = self
                    .parse(file.lines().map(|l| l.unwrap_or("".to_string())), gm)
                    .err()
                    .unwrap_or("".to_string());
                godot_print!("parsed {:.2?}", start.elapsed());
                e
            }
            Err(e) => e.to_string(),
        })
            .into()
    }

    #[func]
    pub fn is_other_prop(k: GString) -> bool {
        Parser::is_other_prop(&k.to_string())
    }

    fn read_glyphs_map(&mut self, path: &str) -> GlyphsMap {
        GFile::open(path, ModeFlags::READ)
            .map_err(|e| e.into())
            .and_then(|mut file| {
                let mut s = String::new();
                file.read_to_string(&mut s)
                    .map_err(|e| e.into())
                    .and_then(|_| toml::from_str(&s).map_err(|e| e.into()))
            })
            .unwrap_or_else(|e: Box<dyn Error>| {
                self.warn(0, &format!("unable to read glyphs.toml [\n{e}\n]"));
                GlyphsMap::default()
            })
    }

    fn parse(
        &mut self,
        lines: impl IntoIterator<Item: AsRef<str>>,
        gm: GlyphsMap,
    ) -> Result<(), String> {
        let mut parser = Parser::new(self, gm);
        for line in lines {
            if let Err(msg) = parser.parse_line(line.as_ref()) {
                let l = parser.n_line;
                return Err(self.err(l, &msg));
            }
            if parser.is_done() {
                return Ok(());
            }
        }
        parser.recover();
        Ok(())
    }

    pub fn set_prop(&mut self, k: &str, v: Variant) {
        self.props.set(k, v)
    }

    pub fn set_glyph_pre(&mut self, k: &str, v: Dictionary) {
        self.glyphs.set(k, v)
    }

    pub fn warn(&mut self, n_line: usize, msg: &str) {
        self.warns
            .push(&Self::rs_print(format!("WARN @ line {n_line}: {msg}")));
    }

    fn err(&self, n_line: usize, msg: &str) -> String {
        Self::rs_print(format!("ERR @ line {n_line}: {msg}"))
    }

    #[func]
    fn rs_print(str: String) -> String {
        godot_print!("{str}");
        str
    }
}
