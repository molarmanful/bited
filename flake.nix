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
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [ inputs.treefmt-nix.flakeModule ];
      perSystem =
        {
          inputs',
          pkgs,
          ...
        }:

        let
          gdpkgs = pkgs.godotPackages_4_5;
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

          rust-pkg =
            o:
            craneLib.buildPackage (
              {
                src = ./rust;
                doCheck = false;
                depsBuildBuild = with pkgs; [ mold ];
                RUSTFLAGS = [ "-C link-arg=-fuse-ld=mold" ];
              }
              // o
            );

          rust = rust-pkg { };
          rust-dbg = rust-pkg { CARGO_PROFILE = ""; };

          version = builtins.readFile ./VERSION;
          release-pkgs =
            builtins.mapAttrs
              (
                name: attrs:
                pkgs.callPackage ./nix/release.nix (
                  {
                    inherit name version;
                    inherit (gdpkgs) godot export-templates-bin;
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

          bited = pkgs.callPackage ./nix {
            bited-release = release-pkgs.release-linux;
          };

          mdformat-plugins =
            ps: with ps; [ mdformat-mkdocs ] ++ mdformat-mkdocs.optional-dependencies.recommended;
        in
        {

          packages = {
            inherit bited rust rust-dbg;
            default = bited;

            build-check = pkgs.callPackage ./nix/build-check.nix {
              inherit version rust-dbg;
              inherit (gdpkgs) godot export-templates-bin;
            };
          }
          // release-pkgs;

          devShells = {
            default = pkgs.mkShell {
              packages = with pkgs; [
                gdtoolkit_4
                gdpkgs.godot
                marksman
                taplo
                just
                yamlfmt
                clang-tools
                actionlint
                pixelorama
                uv
                mdformat
                (python3.withPackages mdformat-plugins)
              ];
              inputsFrom = [ (craneLibDev.devShell { }) ];
            };

            ci-check = pkgs.mkShell {
              packages = with pkgs; [
                gdtoolkit_4
              ];
              inputsFrom = [ (craneLibDev.devShell { }) ];
            };
          };

          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              nixfmt.enable = true;
              statix.enable = true;
              deadnix.enable = true;
              gdformat = {
                enable = true;
                includes = [ "godot/components/**/*.gd" ];
              };
              rustfmt = {
                enable = true;
                package = craneLibDev.rustfmt;
              };
              yamlfmt.enable = true;
              actionlint.enable = true;
              mdformat = {
                enable = true;
                plugins = mdformat-plugins;
                includes = [ "docs/**/*.md" ];
              };
              clang-format = {
                enable = true;
                includes = [ "godot/components/**/*.gdshader" ];
              };
              taplo.enable = true;
            };
          };
        };
    };
}
