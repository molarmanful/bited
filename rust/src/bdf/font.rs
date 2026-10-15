use std::{
    error::Error,
    io::{
        BufRead,
        Read,
    },
    time::Instant,
};

use godot::{
    classes::file_access::ModeFlags,
    prelude::*,
};

use crate::bdf::{
    glyphs_map::GlyphsMap,
    parser::Parser,
    prop_val::PropVal,
};

#[derive(GodotClass)]
#[class(init, base=RefCounted)]
pub struct BFontR {
    #[var]
    #[init(val = "bited".into())]
    pub foundry: GString,
    #[var]
    #[init(val = "new font".into())]
    pub family: GString,
    #[var]
    #[init(val = "Regular".into())]
    pub weight: GString,
    #[var]
    #[init(val = "R".into())]
    pub slant: GString,
    #[var]
    #[init(val = "Normal".into())]
    pub setwidth: GString,
    #[var]
    pub add_style: GString,
    #[var]
    pub bb: Vector2i,
    #[var]
    #[init(val = Vector2i::new(75, 75))]
    pub resolution: Vector2i,
    #[var]
    #[init(val = "P".into())]
    pub spacing: GString,
    #[var]
    #[init(val = "ISO10646".into())]
    pub ch_reg: GString,
    #[var]
    #[init(val = "1".into())]
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
    #[init(val = -16)]
    pub table_width: i32,
    #[var]
    #[init(val = 2)]
    pub thumb_px_size: i32,
    #[var]
    #[init(val = 32)]
    pub grid_size: i32,
    #[var]
    #[init(val = 12)]
    pub grid_px_size: i32,
    #[var]
    warns: PackedStringArray,
    #[var]
    props: Dictionary<GString, Variant>,
    #[var]
    glyphs: Dictionary<GString, VarDictionary>,
}

#[godot_api]
impl BFontR {
    #[func]
    pub fn read_file(&mut self, path: String) -> String {
        match GFile::open(&path, ModeFlags::READ) {
            Ok(file) => {
                let start = Instant::now();
                let base = path.strip_suffix(".bdf").unwrap_or(&path);
                let gm = self.read_glyphs_map(&format!("{base}.glyphs.toml"));
                let e = self
                    .parse(file.lines().map(|l| l.unwrap_or_default()), gm)
                    .err()
                    .unwrap_or_default();
                godot_print!("parsed {:.2?}", start.elapsed());
                e
            }
            Err(e) => e.to_string(),
        }
    }

    #[func]
    pub fn is_other_prop(k: String) -> bool {
        Parser::is_other_prop(&k)
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

    pub fn set_prop(&mut self, k: &str, v: PropVal) {
        self.props.set(k, v)
    }

    pub fn set_glyph_pre(&mut self, k: &str, v: VarDictionary) {
        self.glyphs.set(k, &v)
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
