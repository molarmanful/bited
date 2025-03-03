{
  description = "A bitmap font editor.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    systems.url = "systems";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devenv.url = "github:cachix/devenv";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane";
  };

  outputs =
    inputs@{ flake-parts, systems, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.devenv.flakeModule ];
      systems = import systems;
      perSystem =
        { inputs', pkgs, ... }:

        let
          godot_4_4 = pkgs.callPackage ./nix/godot_4.nix { };
          toolchain = inputs'.fenix.packages.minimal;
          craneLib = (inputs.crane.mkLib pkgs).overrideToolchain toolchain;
          rust = craneLib.buildPackage {
            src = ./rust;
            doCheck = false;
            depsBuildBuild = with pkgs; [ mold ];
            CARGO_BUILD_TARGET = "x86_64-unknown-linux-gnu";
            RUSTFLAGS = [ "-C link-arg=-fuse-ld=mold" ];
          };
          release-pkgs =
            builtins.mapAttrs
              (
                name: attrs:
                pkgs.callPackage ./release.nix (
                  {
                    inherit name;
                    godot_4 = godot_4_4;
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
        in
        {

          packages = {
            inherit rust;
          } // release-pkgs;

          devenv.shells = {
            default = {

              packages = with pkgs; [
                gdtoolkit_4
                godot_4_4
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
