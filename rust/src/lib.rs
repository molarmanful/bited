#![feature(int_from_ascii)]

mod bdf;
mod util;
use godot::prelude::*;

struct MyExtension;

#[gdextension]
unsafe impl ExtensionLibrary for MyExtension {}
