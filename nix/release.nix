{
  name,
  version,
  release,
  ext,

  lib,
  stdenv,
  fetchurl,
  godot,
  export-templates-bin,
  wineWowPackages,
  zip,
  ...
}:

let
  rcedit = fetchurl {
    url = "https://github.com/electron/rcedit/releases/download/v2.0.0/rcedit-x86.exe";
    hash = "sha256-OPtek118tY16mLTtj4dsg/XbAyvNAymwpN5OSh3odrY=";
  };
  gd_ver = lib.removeSuffix "-stable" godot.version;
in

stdenv.mkDerivation {
  inherit version;
  pname = "bited-${name}";
  src = ./..;

  nativeBuildInputs = [
    godot
    zip
  ];

  buildPhase = ''
    runHook preBuild

    export HOME=$(mktemp -d)
    mkdir -p "$HOME"/.local/share/godot
    ln -s ${export-templates-bin}/share/godot/export_templates "$HOME"/.local/share/godot/export_templates
    ${
      if release == "windows" && stdenv.hostPlatform.system == "x86_64-linux" then
        ''
          godot --headless -v -e --quit
          echo 'export/windows/rcedit = "${rcedit}"' >> "$HOME"/.config/godot/editor_settings-${gd_ver}.tres
          echo 'export/windows/wine = "${wineWowPackages.stable}/bin/wine64"' >> "$HOME"/.config/godot/editor_settings-${gd_ver}.tres
        ''
      else
        ""
    }

    pushd godot
    sed -i 's#^\s*config/version\s*=\s*".*"\s*$#config/version="v${version}"#' project.godot
    mkdir -p bited
    godot --headless --v --export-release "${release}" bited/bited.${ext}
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
