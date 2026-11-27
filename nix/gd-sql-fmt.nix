{
  writers,
  python3Packages,
  gdtoolkit_4,
  syntaqlite,
  lld,
}:

let
  libsyntaqlite = syntaqlite.overrideAttrs (old: {
    buildAndTestSubdir = "syntaqlite-capi";
    nativeBuildInputs = old.nativeBuildInputs ++ [ lld ];
    doCheck = false;
    doInstallCheck = false;
  });

  syntaqlite-py = python3Packages.buildPythonPackage {
    pname = "syntaqlite";
    inherit (syntaqlite) version src;
    sourceRoot = "${syntaqlite.src.name}/python";
    pyproject = true;
    build-system = [ python3Packages.setuptools ];
    postPatch = "install -D ${libsyntaqlite}/lib/libsyntaqlite.so syntaqlite/lib/libsyntaqlite.so";
  };
in

writers.writePython3Bin "gd-sql-fmt" {
  libraries = [
    syntaqlite-py
    (python3Packages.toPythonModule gdtoolkit_4)
  ];
} ./gd_sql_fmt.py
