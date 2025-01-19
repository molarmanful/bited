{
  description = "A bitmap font editor.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      utils,
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        gdtk = pkgs.gdtoolkit_4.overrideAttrs (
          finalAttrs: prevAttrs: {
            version = "4.3.3";
            src = pkgs.fetchFromGitHub {
              owner = "Scony";
              repo = "godot-gdscript-toolkit";
              rev = finalAttrs.version;
              sha256 = "sha256-GS1bCDOKtdJkzgP3+CSWEUeHQ9lUcAHDT09QmPOOeVc=";
            };
          }
        );
      in
      {
        devShell = pkgs.mkShell {
          packages = with pkgs; [
            sqlite
            gdtk
            # godot_4
            scons
            marksman
            markdownlint-cli
          ];

          shellHook = ''
            export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib;
          '';
        };
      }
    );
}
