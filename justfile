[working-directory: 'godot']
run: build-rs
  godot4

[working-directory: 'rust']
build-rs *FLAGS:
  cargo build {{FLAGS}}

docs:
  mkdocs serve
