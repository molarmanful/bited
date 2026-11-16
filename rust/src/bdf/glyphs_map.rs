use std::collections::{
    HashMap,
    HashSet,
};

use serde::{
    Deserialize,
    Serialize,
};

#[derive(Deserialize, Serialize, Default)]
pub struct GlyphsMap {
    #[serde(default)]
    pub default: Defaults,
    #[serde(default)]
    pub glyphs: HashMap<String, Glyph>,
}

#[derive(Deserialize, Serialize)]
pub struct Defaults {
    pub is_abs: bool,
}

#[derive(Deserialize, Serialize)]
pub struct Glyph {
    pub is_abs: Option<bool>,
    #[serde(default)]
    pub layers: Vec<Layer>,
}

#[derive(Deserialize, Serialize, Default)]
#[serde(default)]
pub struct Layer {
    pub child: String,
    pub off_x: i32,
    pub off_y: i32,
    pub blend: i32,
    pub xform: i32,
}

impl GlyphsMap {
    pub fn is_abs(&self, name: &str) -> bool {
        self.glyphs
            .get(name)
            .and_then(|glyph| glyph.is_abs)
            .unwrap_or(self.default.is_abs)
    }

    pub fn is_cycle(&self, parent: &str, child: &str) -> bool {
        let mut gs = vec![child];
        let mut seen = HashSet::new();
        while let Some(n) = gs.pop() {
            if n == parent {
                return true;
            }
            if seen.insert(n)
                && let Some(g) = self.glyphs.get(n)
            {
                gs.extend(g.layers.iter().map(|l| l.child.as_str()));
            }
        }
        false
    }
}

impl Default for Defaults {
    fn default() -> Self {
        Self { is_abs: true }
    }
}
