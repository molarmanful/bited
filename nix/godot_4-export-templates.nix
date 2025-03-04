{ fetchzip, godot_4, ... }:

fetchzip {
  pname = "export_templates";
  extension = "zip";
  url = "https://github.com/godotengine/godot/releases/download/${godot_4.version}/Godot_v${godot_4.version}_export_templates.tpz";
  hash = "sha256-ayY1euO7WJJhZcF0NfobuD1Pcr8LeV/3g/opaZ2wniQ=";
}
