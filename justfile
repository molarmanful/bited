[working-directory: 'godot']
run:
  just build-rust
  godot4

[working-directory: 'rust']
build-rust:
  cargo build
