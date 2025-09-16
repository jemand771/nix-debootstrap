{
  pkgs ? import <nixpkgs> { },
  chrootlib ? pkgs.callPackage ../lib { },
  ...
}:
let
  mkRepoPackages =
    {
      baseUrl,
      distReleaseHashes,
      cartesianMaps,
    }:
    pkgs.linkFarmFromDrvs "packages" (
      builtins.map (
        {
          dist,
          component,
          flavor,
        }:
        pkgs.runCommand "${dist}_${component}_${flavor}.json" {
          src = pkgs.writeText "${dist}_${component}_${flavor}_raw.json" (
            builtins.toJSON (
              chrootlib.lists.list2json (
                chrootlib.release.packageListXz baseUrl dist (builtins.getAttr dist distReleaseHashes) component
                  flavor
              )
            )
          );
          nativeBuildInputs = [ pkgs.jq ];
        } "jq < $src > $out"
      ) (builtins.concatMap pkgs.lib.cartesianProduct cartesianMaps)
    );
  repos = import ./repos.nix;
in
pkgs.linkFarm "repos" (builtins.mapAttrs (_: mkRepoPackages) repos)
