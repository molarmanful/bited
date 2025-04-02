{
  description = "A bitmap font editor.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devenv.url = "github:cachix/devenv";
    devenv-root = {
      url = "file+file:///dev/null";
      flake = false;
    };
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
          my_godot = pkgs.godot_4_4;
          my_godot-export-templates = pkgs.godot_4_4-export-templates;
          toolchain = inputs'.fenix.packages.minimal;
          craneLib = (inputs.crane.mkLib pkgs).overrideToolchain toolchain;
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
          } // release-pkgs;

          devenv.shells = {
            default = {
              devenv.root =
                let
                  path = builtins.readFile inputs.devenv-root.outPath;
                in
                pkgs.lib.mkIf (path != "") path;

              packages = with pkgs; [
                stdenv.cc.cc
                gdtoolkit_4
                my_godot
                marksman
                just
                yaml-language-server
                yamlfmt
                pixelorama
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
