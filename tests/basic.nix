{
  self,
  pkgs,
  system,
}:
let
  list = self.lib.${system}.debian.packageList "trixie" "main" "binary-amd64";
  packages = self.lib.${system}.lists.list2json list;
in
self.lib.${system}.buildChroot
  (builtins.map (name: pkgs.lib.findFirst (p: p.Package == name) null packages) (
    self.lib.${system}.deb.resolveDeps packages (
      builtins.map (p: p.Package) (self.lib.${system}.deb.priorityDebs "required" packages)
    )
  ))
  (
    builtins.map (name: pkgs.lib.findFirst (p: p.Package == name) null packages) (
      self.lib.${system}.deb.resolveDeps packages (
        builtins.map (p: p.Package) (self.lib.${system}.deb.priorityDebs "important" packages)
      )
    )
  )
