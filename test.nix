{
  pkgs ? import <nixpkgs> { },
  chrootlib ? pkgs.callPackage ./lib { },
}:
let
  list = chrootlib.release.packageList "trixie" "main" "binary-amd64";
  packages = chrootlib.lists.list2json list;
in
chrootlib.buildChroot
  (builtins.map (name: pkgs.lib.findFirst (p: p.Package == name) null packages) (
    chrootlib.deb.resolveDeps packages (
      builtins.map (p: p.Package) (chrootlib.deb.priorityDebs "required" packages)
    )
  ))
  (
    builtins.map (name: pkgs.lib.findFirst (p: p.Package == name) null packages) (
      chrootlib.deb.resolveDeps packages (
        builtins.map (p: p.Package) (chrootlib.deb.priorityDebs "important" packages)
      )
    )
  )
