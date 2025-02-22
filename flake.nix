{
  description = "A bitmap font editor.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    systems.url = "systems";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devenv.url = "github:cachix/devenv";
  };

  outputs =
    inputs@{
      systems,
      flake-parts,
      ...
    }:

    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModule
      ];
      systems = import systems;
      perSystem =
        { pkgs, ... }:

        let
          gdtk = pkgs.callPackage ./gdtoolkit.nix { };
        in

        {
          devenv.shells.default = {
            packages = with pkgs; [
              sqlite
              gdtk
              godot_4
              scons
              marksman
            ];

            languages.python = {
              enable = true;
              venv.enable = true;
              uv = {
                enable = true;
                sync.enable = true;
              };
            };
          };
        };
    };
}
