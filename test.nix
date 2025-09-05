{
  pkgs ? import <nixpkgs> { },
}:
let
  chrootlib = pkgs.callPackage ./lib { };
in
chrootlib.buildChroot (chrootlib.debootstrapTar "trixie" "main" "binary-amd64" [ ])
# chrootlib.buildChroot []
