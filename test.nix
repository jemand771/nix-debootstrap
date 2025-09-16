{
  pkgs ? import <nixpkgs> { },
  chrootlib ? pkgs.callPackage ./lib { },
  repos ? pkgs.callPackage ./repos { },
}:
let
  packages = repos.debian.packagesFor {
    dist = "trixie";
    component = "main";
    flavor = "binary-amd64";
  };
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
