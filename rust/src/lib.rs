#![feature(int_from_ascii)]
#![feature(string_into_chars)]

mod bdf;
mod util;
use godot::prelude::*;

struct MyExtension;

#[gdextension]
unsafe impl ExtensionLibrary for MyExtension {}
