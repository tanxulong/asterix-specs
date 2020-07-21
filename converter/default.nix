{ packages ? null
, inShell ? null
}:

let
  nixpkgs = builtins.fromJSON (builtins.readFile ../nixpkgs.json);
  pkgs = if packages == null
    then import (builtins.fetchGit nixpkgs) { }
    else packages;

  haskellPackages = pkgs.haskellPackages;
  drv1 = haskellPackages.callPackage ./generated.nix { };

  envVars = ''
    export SW_VERSION=$(cat *.cabal | grep "^version:" | awk '{print $2}')
  '';

  drv = drv1.overrideDerivation (oldAttrs: {
      preBuild = envVars;
      src = builtins.filterSource
        (path: type: type != "symlink" || baseNameOf path != "result")
        ./.;
    }) // { inherit env; };

  env = pkgs.stdenv.mkDerivation rec {
    name = "converter-devel-environment";
    buildInputs = drv1.env.nativeBuildInputs ++ [
      pkgs.cabal2nix
      pkgs.ghcid
    ];
    shellHook = envVars;
  };

in
  if inShell == false
    then drv
    else if pkgs.lib.inNixShell then env else drv

