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
        { pkgs, system, ... }:

        let
          gdtk = pkgs.callPackage ./gdtoolkit.nix { };
          rust =
            let
              toolchain = inputs.fenix.packages.${system}.minimal;
              craneLib = (inputs.crane.mkLib pkgs).overrideToolchain toolchain;
            in
            craneLib.buildPackage {
              src = ./rust;
              doCheck = false;
              depsBuildBuild = with pkgs; [ mold ];
              CARGO_BUILD_TARGET = "x86_64-unknown-linux-gnu";
              RUSTFLAGS = [ "-C link-arg=-fuse-ld=mold" ];
            };
          release-pkgs =
            builtins.mapAttrs (name: attrs: pkgs.callPackage ./release.nix ({ inherit name; } // attrs))
              {
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
                gdtk
                godot_4
                marksman
                just
                yaml-language-server
                yamlfix
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
