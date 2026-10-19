#![feature(int_from_ascii)]

mod bdf;
mod bit_glyph;
mod util;
use godot::prelude::*;

struct MyExtension;

#[gdextension]
unsafe impl ExtensionLibrary for MyExtension {}
