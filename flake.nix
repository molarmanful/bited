{
  description = "A bitmap font editor.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      pyproject-nix,
      uv2nix,
      pyproject-build-systems,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let

        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib;
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

        python = pkgs.python313;
        workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };
        overlay = workspace.mkPyprojectOverlay {
          sourcePreference = "wheel";
        };
        pythonSet =
          (pkgs.callPackage pyproject-nix.build.packages {
            inherit python;
          }).overrideScope
            (
              lib.composeManyExtensions [
                pyproject-build-systems.overlays.default
                overlay
              ]
            );

      in
      {
        devShell =
          let
            editableOverlay = workspace.mkEditablePyprojectOverlay {
              root = "$REPO_ROOT";
            };
            editablePythonSet = pythonSet.overrideScope (
              lib.composeManyExtensions [
                editableOverlay
                (final: prev: {
                  bited-docs = prev.bited-docs.overrideAttrs (old: {
                    src = lib.fileset.toSource {
                      root = old.src;
                      fileset = lib.fileset.unions [
                        (old.src + "/pyproject.toml")
                        (old.src + "/README.md")
                      ];
                    };
                    nativeBuildInputs =
                      old.nativeBuildInputs
                      ++ final.resolveBuildSystem {
                        editables = [ ];
                      };
                  });
                })
              ]
            );
            virtualenv = editablePythonSet.mkVirtualEnv "bited-docs-dev-env" workspace.deps.all;
          in

          pkgs.mkShell {
            packages = with pkgs; [
              sqlite
              gdtk
              godot_4
              scons
              marksman
              virtualenv
              pkgs.uv
            ];

            env = {
              UV_NO_SYNC = "1";
              UV_PYTHON = "${virtualenv}/bin/python";
              UV_PYTHON_DOWNLOADS = "never";
            };

            shellHook = ''
              unset PYTHONPATH
              export REPO_ROOT=$(git rev-parse --show-toplevel)
            '';
          };
      }
    );
}
