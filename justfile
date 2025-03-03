[working-directory: 'godot']
run: build-rs
  godot4

[working-directory: 'rust']
build-rs *FLAGS:
  cargo build {{FLAGS}}

[working-directory: 'godot']
ed:
  godot4 -e

docs:
  mkdocs serve
