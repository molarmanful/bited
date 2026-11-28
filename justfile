[working-directory: 'godot']
run *ARGS: build-rs
  godot {{ARGS}}

[working-directory: 'rust']
build-rs *ARGS:
  cargo build {{ARGS}}

[working-directory: 'godot']
ed *ARGS: build-rs
  godot -e {{ARGS}}

[working-directory: 'godot']
test *ARGS="-a test": build-rs
  GODOT_BIN="$(command -v godot)" addons/gdUnit4/runtest.sh {{ARGS}}

docs:
  uv run zensical serve
