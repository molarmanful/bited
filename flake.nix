{
  description = "A bitmap font editor.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devenv.url = "github:cachix/devenv";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.devenv.flakeModule ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      perSystem =
        { inputs', pkgs, ... }:

        let
          my_godot = pkgs.callPackage ./nix/godot_4.nix { };
          my_godot-export-templates = pkgs.callPackage ./nix/godot_4-export-templates.nix {
            godot_4 = my_godot;
          };
          toolchain = inputs'.fenix.packages.minimal;
          craneLib = (inputs.crane.mkLib pkgs).overrideToolchain toolchain;
          rust = craneLib.buildPackage {
            src = ./rust;
            doCheck = false;
            depsBuildBuild = with pkgs; [ mold ];
            RUSTFLAGS = [ "-C link-arg=-fuse-ld=mold" ];
          };
          release-pkgs =
            builtins.mapAttrs
              (
                name: attrs:
                pkgs.callPackage ./release.nix (
                  {
                    inherit name;
                    godot_4 = my_godot;
                    godot_4-export-templates = my_godot-export-templates;
                  }
                  // attrs
                )
              )
              {
                release-macos = {
                  release = "macos";
                  ext = "zip";
                };
                release-windows = {
                  release = "windows";
                  ext = "exe";
                };
                release-linux = {
                  release = "linux";
                  ext = "x86_64";
                };
              };
          bited = pkgs.callPackage ./. {
            bited-release = release-pkgs.release-linux;
          };
        in
        {

          packages = {
            inherit rust bited;
            default = bited;
          } // release-pkgs;

          devenv.shells = {
            default = {

              packages = with pkgs; [
                gdtoolkit_4
                my_godot
                marksman
                just
                yaml-language-server
                yamlfmt
              ];

              languages = {
                rust = {
                  enable = true;
                  channel = "nightly";
                  components = [
                    "rustc"
                    "cargo"
                    "clippy"
                    "rustfmt"
                    "rust-analyzer"
                    "rust-src"
                  ];
                };
                python = {
                  enable = true;
                  venv.enable = true;
                  uv = {
                    enable = true;
                    sync.enable = true;
                  };
                };
              };

              enterShell = ''
                export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc ]}:$LD_LIBRARY_PATH"
              '';
            };
          };
        };
    };
}
