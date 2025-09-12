{
  pkgs ? import <nixpkgs> { },
  chrootlib ? pkgs.callPackage ./lib { },
}:
let
  list = chrootlib.debian.packageList "trixie" "main" "binary-amd64";
  packages = chrootlib.lists.list2json list;
in
chrootlib.buildChroot
  (chrootlib.deb.resolveDeps packages (
    chrootlib.deb.filter {
      Priority = "required";
      Architecture = "amd64";
    } packages
  ))
  (
    chrootlib.deb.resolveDeps packages (
      (chrootlib.deb.filter {
        Priority = "important";
        Architecture = "amd64";
      } packages)
    )
  )
