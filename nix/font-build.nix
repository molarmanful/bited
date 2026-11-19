{ writeShellApplication, bited-build, ... }:

writeShellApplication {
  name = "font-build";
  text = ''
    cd "$(git rev-parse --show-toplevel)/godot/assets"
    ${bited-build}/bin/bited-build
    mv out/*.woff2 .
    rm -rf out
  '';
}
