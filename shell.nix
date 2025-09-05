{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShellNoCC {

  packages = with pkgs; [
    debootstrap
    dpkg
  ];
}
