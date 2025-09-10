{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShellNoCC {

  packages = with pkgs; [
    apt
    dpkg
  ];
}
