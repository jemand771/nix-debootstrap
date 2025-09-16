{
  pkgs ? import <nixpkgs> { },
  chrootlib ? pkgs.callPackage ../lib { },
  ...
}:
pkgs.linkFarmFromDrvs "packages" (
  builtins.map
    (
      {
        dist,
        component,
        flavor,
      }:
      pkgs.runCommand "${dist}_${component}_${flavor}.json" {
        src = pkgs.writeText "${dist}_${component}_${flavor}_raw.json" (
          builtins.toJSON (chrootlib.lists.list2json (chrootlib.debian.packageList dist component flavor))
        );
        nativeBuildInputs = [ pkgs.jq ];
      } "jq < $src > $out"
    )
    (
      (pkgs.lib.cartesianProduct {
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
      })
      ++ (pkgs.lib.cartesianProduct {
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
      })
    )
)
