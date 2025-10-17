use std::collections::HashSet;

use godot::prelude::*;

use crate::util::UtilR;

pub struct PGen {
    pub name: String,
    pub code: i32,
    pub dwidth: i32,
    pub is_abs: bool,
    pub bb_x: usize,
    pub bb_y: usize,
    pub off_x: i32,
    pub off_y: i32,
    pub bm: Vec<String>,
    defs: HashSet<String>,
}

impl PGen {
    pub fn new() -> Self {
        Self {
            name: "".to_string(),
            code: -1,
            dwidth: 0,
            is_abs: false,
            bb_x: 0,
            bb_y: 0,
            off_x: 0,
            off_y: 0,
            defs: HashSet::new(),
            bm: vec![],
        }
    }

    pub fn notdef(&mut self, k: &str) -> (Option<String>, bool) {
        let def = self.defs.contains(k);
        let mut warn = None;
        if def {
            warn = Some(format!("{k} already defined, skipping"));
        } else {
            self.defs.insert(k.to_string());
        }
        (warn, !def)
    }

    pub fn check_missing(&mut self) -> Vec<&str> {
        ["BBX", "DWIDTH", "BITMAP"]
            .into_iter()
            .filter(|&k| !self.defs.contains(k))
            .collect()
    }

    pub fn to_glyph(&self) -> Dictionary {
        vdict! {
            "name": self.name.clone(),
            "code": self.code,
            "dwidth": self.dwidth,
            "is_abs": self.is_abs,
            "bb_x": self.bb_x as u32,
            "bb_y": self.bb_y as u32,
            "off_x": self.off_x,
            "off_y": self.off_y,
            "img": self.img(),
        }
    }

    fn img(&self) -> PackedByteArray {
        UtilR::hexes_to_bits_r(self.bm.iter(), self.bb_x, self.bb_y).collect()
    }
}
