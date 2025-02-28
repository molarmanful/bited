[working-directory: 'godot']
run: build-rs
  godot4

[working-directory: 'rust']
build-rs *FLAGS:
  cargo build {{FLAGS}}

release-pre:
  mkdir -p build
  mkdir -p ~/.local/share/godot/export_templates/4.3.stable
  rm -rf  ~/.local/share/godot/export_templates/4.3.stable/*
  cp "$GD_EXPORT_TEMPLATES_PATH"/* ~/.local/share/godot/export_templates/4.3.stable

[working-directory: 'godot']
release-windows: release-pre
  mkdir -p ../build/windows
  godot4 --headless --verbose --export-release "windows" ../build/windows/bited.exe
  cd ../build/windows
  zip bited.zip ./*
