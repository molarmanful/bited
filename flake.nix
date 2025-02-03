{
  description = "A bitmap font editor.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
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
            godot_4
            scons
            marksman
            mkdocs
            python313Packages.pip
          ];

          shellHook = ''
            export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib;
            python -m venv venv
            source venv/bin/activate
            pip install -r requirements.txt
          '';
        };
      }
    );
}
