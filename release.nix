{
  name,
  release,
  ext,

  stdenv,
  fetchurl,
  godot_4,
  godot_4-export-templates,
  wineWowPackages,
  zip,
  ...
}:

let
  rcedit = fetchurl {
    url = "https://github.com/electron/rcedit/releases/download/v2.0.0/rcedit-x86.exe";
    hash = "sha256-OPtek118tY16mLTtj4dsg/XbAyvNAymwpN5OSh3odrY=";
  };
in

stdenv.mkDerivation {
  pname = "bited-${name}";
  version = "0.0.0-0";
  src = ./.;

  nativeBuildInputs = [
    godot_4
    zip
  ];

  buildPhase = ''
    runHook preBuild

    export HOME=$(mktemp -d)
    mkdir -p "$HOME"/.local/share/godot/export_templates
    ln -s ${godot_4-export-templates} "$HOME"/.local/share/godot/export_templates/4.3.stable
    ${
      if release == "windows" then
        ''
          godot4 --headless -v -e --quit
          echo 'export/windows/rcedit = "${rcedit}"' >> "$HOME"/.config/godot/editor_settings-4.3.tres
          echo 'export/windows/wine = "${wineWowPackages.stable}/bin/wine64"' >> "$HOME"/.config/godot/editor_settings-4.3.tres
        ''
      else
        ""
    }

    pushd godot
    mkdir -p bited
    godot4 --headless --v --export-release "${release}" bited/bited.${ext}
    ${if ext == "zip" then "cp bited/bited.zip ." else "zip -r bited.zip bited"}
    popd

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm 644 godot/bited.zip -t $out

    runHook postInstall
  '';
}
