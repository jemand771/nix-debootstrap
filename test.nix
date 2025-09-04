{ pkgs ? import <nixpkgs> {} }:
let
chrootlib = pkgs.callPackage ./chrootlib.nix {};
in
chrootlib.buildChroot (chrootlib.chrootTar "trixie" "main" "binary-amd64" [ ])
# chrootlib.buildChroot []
