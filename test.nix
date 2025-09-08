{
  pkgs ? import <nixpkgs> { },
  chrootlib ? pkgs.callPackage ./lib { },
}:
let
  list = chrootlib.packageList "trixie" "main" "binary-amd64";
  packages = chrootlib.packageJSON list;
in
chrootlib.buildChroot list
  (builtins.map (name: pkgs.lib.findFirst (p: p.Package == name) null packages) (
    chrootlib.resolveDeps list (
      builtins.map (p: p.Package) (chrootlib.priorityDebs "required" packages)
    )
  ))
  (
    builtins.map (name: pkgs.lib.findFirst (p: p.Package == name) null packages) (
      chrootlib.resolveDeps list (
        builtins.map (p: p.Package) (chrootlib.priorityDebs "important" packages)
      )
    )
  )
