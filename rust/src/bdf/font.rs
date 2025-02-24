use godot::{
    classes::{
        IRefCounted,
        RefCounted,
    },
    prelude::*,
};

use super::parser::Parser;

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
            props: dict! {},
            glyphs: dict! {},
        }
    }
}

#[godot_api]
impl BFontR {
    #[func]
    pub fn parse(&mut self, next: Callable, end: Callable) -> GString {
        let mut parser = Parser::new(self);
        while !end.call(&[]).to::<bool>() {
            let e = parser.parse_line(&next.call(&[]).to_string());
            if let Some(msg) = e {
                let l = parser.n_line;
                return self.err(l, &msg).into();
            }
            if parser.is_done() {
                return "".into();
            }
        }
        parser.recover();
        "".into()
    }

    pub fn warn(&mut self, n_line: usize, msg: &str) {
        godot_print!("WARN @ line {}: {}", n_line, msg);
        self.warns.push(msg);
    }

    pub fn err(&self, n_line: usize, msg: &str) -> String {
        let e = format!("ERR @ line {}: {}", n_line, msg);
        godot_print!("{}", e);
        e
    }

    pub fn set_prop(&mut self, k: &str, v: Variant) {
        self.props.set(k, v)
    }

    pub fn set_glyph_pre(&mut self, k: &str, v: Dictionary) {
        self.glyphs.set(k, v)
    }
}
