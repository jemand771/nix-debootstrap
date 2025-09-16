{
  pkgs ? import <nixpkgs> { },
  chrootlib ? pkgs.callPackage ../lib { },
  repos ? import ./repos.nix,
  ...
}:
let
  mkRepoPackages =
    {
      baseUrl,
      distReleaseHashes,
      cartesianMaps,
      useGzip ? false,
    }:
    let
      packageList = if useGzip then chrootlib.release.packageListGz else chrootlib.release.packageListXz;
    in
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
                packageList baseUrl dist (builtins.getAttr dist distReleaseHashes) component flavor
              )
            )
          );
          nativeBuildInputs = [ pkgs.jq ];
        } "jq < $src > $out"
      ) (builtins.concatMap pkgs.lib.cartesianProduct cartesianMaps)
    );
in
pkgs.linkFarm "repos" (builtins.mapAttrs (_: mkRepoPackages) repos)
