use std::collections::HashMap;

use serde::{
    Deserialize,
    Serialize,
};

#[derive(Deserialize, Serialize, Default)]
pub struct GlyphsMap {
    #[serde(default)]
    pub default: Glyph,
    #[serde(default)]
    pub glyphs: HashMap<String, Glyph>,
}

#[derive(Deserialize, Serialize)]
pub struct Glyph {
    pub is_abs: bool,
}

impl GlyphsMap {
    pub fn is_abs(&self, name: &str) -> bool {
        self.glyphs
            .get(name)
            .map(|glyph| glyph.is_abs)
            .unwrap_or(self.default.is_abs)
    }
}

impl Default for Glyph {
    fn default() -> Self {
        Self { is_abs: true }
    }
}
