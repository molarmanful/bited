{ fetchFromGitHub, gdtoolkit_4, ... }:

gdtoolkit_4.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "4.3.3";
    src = fetchFromGitHub {
      owner = "Scony";
      repo = "godot-gdscript-toolkit";
      rev = finalAttrs.version;
      sha256 = "sha256-GS1bCDOKtdJkzgP3+CSWEUeHQ9lUcAHDT09QmPOOeVc=";
    };
  }
)
