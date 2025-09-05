{ pkgs ? import <nixpkgs> {} }:
let
chrootlib = pkgs.callPackage ./chrootlib {};
in
chrootlib.buildChroot (chrootlib.chrootTar "trixie" "main" "binary-amd64" [ ])
# chrootlib.buildChroot []
