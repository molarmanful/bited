{
  version,
  rust-dbg,

  stdenv,
  godot,
  export-templates-bin,
  ...
}:

stdenv.mkDerivation {
  inherit version;
  pname = "bited-build-check";
  src = ./..;

  nativeBuildInputs = [ godot ];

  buildPhase = ''
    runHook preBuild

    export HOME=$(mktemp -d)
    mkdir -p "$HOME"/.local/share/godot
    ln -s ${export-templates-bin}/share/godot/export_templates "$HOME"/.local/share/godot/export_templates

    mkdir -p rust/target/debug
    cp ${rust-dbg}/lib/libbited_rust.so rust/target/debug

    pushd godot
    godot --headless --v --export-debug linux build-check.x86_64
    popd

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out

    runHook postInstall
  '';
}
