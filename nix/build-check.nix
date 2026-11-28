{
  version,
  rust-dbg,

  stdenv,
  godot,
  export-templates-bin,
  xvfb-run,
  mesa,
  ...
}:

stdenv.mkDerivation {
  inherit version;
  pname = "bited-build-check";
  src = ./..;

  nativeCheckInputs = [ mesa.llvmpipeHook ];
  doCheck = true;

  buildPhase = ''
    runHook preBuild

    export HOME=$(mktemp -d)
    mkdir -p "$HOME"/.local/share/godot
    ln -s ${export-templates-bin}/share/godot/export_templates "$HOME"/.local/share/godot/export_templates

    mkdir -p rust/target/debug
    cp ${rust-dbg}/lib/libbited_rust.so rust/target/debug

    pushd godot
    ${godot}/bin/godot --headless --v --export-debug linux build-check.x86_64
    popd

    runHook postBuild
  '';

  checkPhase = ''
    runHook preCheck

    pushd godot
    patchShebangs addons/gdUnit4/runtest.sh
    GODOT_BIN="${godot}/bin/godot" \
      ${xvfb-run}/bin/xvfb-run -s "-screen 0 1920x1080x24" \
      addons/gdUnit4/runtest.sh -a test
    popd

    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out

    runHook postInstall
  '';
}
