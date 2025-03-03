{ fetchFromGitHub, godot_4, ... }:

godot_4.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "4.4-stable";
    src = fetchFromGitHub {
      owner = "godotengine";
      repo = "godot";
      rev = "4c311cbee68c0b66ff8ebb8b0defdd9979dd2a41";
      hash = "sha256-net4F3qgxAP0TIEuecwuf/ltYF0d33f2fpfpsc3UQdE=";
    };
  }
)
