{
  self,
  pkgs,
  system,
}:
let
  list = self.lib.${system}.packageList "trixie" "main" "binary-amd64";
  packages = self.lib.${system}.packageJSON list;
in
self.lib.${system}.buildChroot list
  (builtins.map (name: pkgs.lib.findFirst (p: p.Package == name) null packages) (
    self.lib.${system}.resolveDeps list (
      builtins.map (p: p.Package) (self.lib.${system}.priorityDebs "required" packages)
    )
  ))
  (
    builtins.map (name: pkgs.lib.findFirst (p: p.Package == name) null packages) (
      self.lib.${system}.resolveDeps list (
        builtins.map (p: p.Package) (self.lib.${system}.priorityDebs "important" packages)
      )
    )
  )
