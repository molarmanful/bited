{
  withWayland ? true,
  lib,
  stdenv,
  autoPatchelfHook,
  godot_4,
  godot_4-export-templates,
  zip,
  libGL,
  vulkan-loader,
  libX11,
  libXcursor,
  libXext,
  libXfixes,
  libXi,
  libXinerama,
  libxkbcommon,
  libXrandr,
  libXrender,
  wayland-scanner,
  libdecor,
  wayland,
  ...
}:

stdenv.mkDerivation {
  pname = "bited";
  version = "0.0.0-0";
  src = ./.;

  nativeBuildInputs = [
    autoPatchelfHook
    stdenv.cc.cc.lib
    godot_4
    zip
  ] ++ lib.optionals withWayland [ wayland-scanner ];

  runtimeDependencies =
    map lib.getLib [
      libGL
      vulkan-loader
      libX11
      libXcursor
      libXext
      libXfixes
      libXi
      libXinerama
      libxkbcommon
      libXrandr
      libXrender
    ]
    ++ lib.optionals withWayland [
      libdecor
      wayland
    ];

  buildPhase = ''
    runHook preBuild

    export HOME=$(mktemp -d)
    mkdir -p "$HOME"/.local/share/godot/export_templates
    ln -s ${godot_4-export-templates} "$HOME"/.local/share/godot/export_templates/${
      lib.replaceStrings [ "-" ] [ "." ] godot_4.version
    }

    pushd godot
    mkdir -p build
    godot4 --headless --v --export-release "linux" build/bited
    popd

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    pushd godot
    install -Dm 644 build/* -t $out/libexec
    chmod 755 $out/libexec/bited
    install -dm 755 $out/bin
    ln -s $out/libexec/bited $out/bin/bited
    popd

    runHook postInstall
  '';
}
