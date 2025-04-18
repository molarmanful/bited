use core::fmt;

use godot::prelude::*;

pub enum PropVal {
    Num(i32),
    Str(String),
}

impl fmt::Display for PropVal {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            PropVal::Num(n) => write!(f, "{n}"),
            PropVal::Str(s) => write!(f, "{s}"),
        }
    }
}

impl GodotConvert for PropVal {
    type Via = Variant;
}

impl ToGodot for PropVal {
    type ToVia<'v>
        = Variant
    where
        Self: 'v;

    fn to_godot(&self) -> Self::ToVia<'_> {
        match self {
            PropVal::Num(n) => n.to_variant(),
            PropVal::Str(s) => s.to_variant(),
        }
    }
}
