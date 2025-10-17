{
  description = "A bitmap font editor.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      perSystem =
        {
          inputs',
          pkgs,
          ...
        }:

        let
          my_godot = pkgs.godot_4_4;
          my_godot-export-templates = pkgs.godot_4_4-export-templates;

          baseCraneLib = inputs.crane.mkLib pkgs;
          craneLib = baseCraneLib.overrideToolchain inputs'.fenix.packages.minimal.toolchain;
          craneLibDev = baseCraneLib.overrideToolchain (
            inputs'.fenix.packages.complete.withComponents [
              "rustc"
              "cargo"
              "clippy"
              "rustfmt"
              "rust-analyzer"
              "rust-src"
            ]
          );

          rust = craneLib.buildPackage {
            src = ./rust;
            doCheck = false;
            depsBuildBuild = with pkgs; [ mold ];
            RUSTFLAGS = [ "-C link-arg=-fuse-ld=mold" ];
          };

          version = builtins.readFile ./VERSION;
          release-pkgs =
            builtins.mapAttrs
              (
                name: attrs:
                pkgs.callPackage ./release.nix (
                  {
                    inherit name version;
                    godot = my_godot;
                    godot-export-templates = my_godot-export-templates;
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
          }
          // release-pkgs;

          devShells = {
            default = pkgs.mkShell {
              packages = with pkgs; [
                gdtoolkit_4
                my_godot
                marksman
                just
                yaml-language-server
                yamlfmt
                pixelorama
                uv
                python314
              ];

              inputsFrom = [ (craneLibDev.devShell { }) ];
            };
          };
        };
    };
}
