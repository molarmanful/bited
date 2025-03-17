use std::collections::HashMap;

use serde::{
    Deserialize,
    Serialize,
};

#[derive(Deserialize, Serialize)]
pub struct GlyphsMap(pub HashMap<String, Glyph>);

#[derive(Deserialize, Serialize)]
pub struct Glyph {
    pub is_abs: bool,
}

impl GlyphsMap {
    pub fn new() -> Self {
        Self(HashMap::new())
    }

    pub fn from_toml(toml: &str) -> Result<Self, toml::de::Error> {
        toml::from_str(toml)
    }
}
