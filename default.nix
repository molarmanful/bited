{
  bited-release,
  withX11 ? true,
  withWayland ? true,

  lib,
  stdenv,
  autoPatchelfHook,
  unzip,
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
  dbus,
  udev,
  wayland-scanner,
  libdecor,
  wayland,
  fontconfig,
  ...
}:

stdenv.mkDerivation {
  inherit (bited-release) version;
  pname = "bited";
  src = ./.;

  nativeBuildInputs = [
    autoPatchelfHook
    stdenv.cc.cc.lib
    unzip
  ] ++ lib.optionals withWayland [ wayland-scanner ];

  runtimeDependencies =
    map lib.getLib [
      libGL
      vulkan-loader
      dbus
      dbus.lib
      udev
      fontconfig
      fontconfig.lib
    ]
    ++ lib.optionals withX11 [
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

  installPhase = ''
    runHook preInstall

    unzip ${bited-release}/bited.zip
    install -Dm 644 bited/* -t $out/libexec
    chmod 755 $out/libexec/bited.x86_64
    install -dm 755 $out/bin
    ln -s $out/libexec/bited.x86_64 $out/bin/bited

    runHook postInstall
  '';
}
