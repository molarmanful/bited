use core::fmt;

use godot::prelude::*;

pub enum PropVal<'a> {
    Num(i32),
    Str(&'a str),
}

impl fmt::Display for PropVal<'_> {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            PropVal::Num(n) => write!(f, "{}", n),
            PropVal::Str(s) => write!(f, "{}", s),
        }
    }
}

impl GodotConvert for PropVal<'_> {
    type Via = Variant;
}

impl ToGodot for PropVal<'_> {
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
