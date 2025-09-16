{
  pkgs ? import <nixpkgs> { },
  chrootlib ? pkgs.callPackage ../lib { },
  ...
}:
let
  mkRepoPackages =
    packageListFun: cartesianMaps:
    pkgs.linkFarmFromDrvs "packages" (
      builtins.map (
        {
          dist,
          component,
          flavor,
        }:
        pkgs.runCommand "${dist}_${component}_${flavor}.json" {
          src = pkgs.writeText "${dist}_${component}_${flavor}_raw.json" (
            builtins.toJSON (chrootlib.lists.list2json (packageListFun dist component flavor))
          );
          nativeBuildInputs = [ pkgs.jq ];
        } "jq < $src > $out"
      ) (builtins.concatMap pkgs.lib.cartesianProduct cartesianMaps)
    );
in
pkgs.linkFarm "repos" {
  debian = mkRepoPackages chrootlib.debian.packageList [
    {
      dist = [
        "bookworm"
        "trixie"
      ];
      component = [
        "main"
        "contrib"
        "non-free"
        "non-free-firmware"
      ];
      flavor = [
        "binary-amd64"
      ];
    }
    {
      dist = [
        "bullseye"
      ];
      component = [
        "main"
        "contrib"
        "non-free"
      ];
      flavor = [
        "binary-amd64"
      ];
    }
  ];
}
