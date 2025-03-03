{
  name,
  release,
  ext,

  lib,
  stdenv,
  godot_4,
  godot_4-export-templates,
  zip,
  ...
}:

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

    pushd godot
    mkdir -p bited
    godot4 --headless --verbose --export-release "${release}" bited/bited.${ext}
    ${lib.optionalString (ext != "zip") "zip -r bited.zip bited"}
    popd

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm 644 godot/bited.zip -t $out

    runHook postInstall
  '';
}
