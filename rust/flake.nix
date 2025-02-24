{
  description = "Rust GDExtension for bited";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    systems.url = "systems";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devenv.url = "github:cachix/devenv";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.devenv.flakeModule ];
      systems = import inputs.systems;
      perSystem = _: {
        devenv.shells.default = {
          languages.rust.enable = true;
        };
      };
    };
}
