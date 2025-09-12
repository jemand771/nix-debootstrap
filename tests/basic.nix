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
  (self.lib.${system}.deb.resolveDeps packages (
    self.lib.${system}.deb.filter {
      Priority = "required";
      Architecture = "amd64";
    } packages
  ))
  (
    self.lib.${system}.deb.resolveDeps packages (
      self.lib.${system}.deb.filter {
        Priority = "important";
        Architecture = "amd64";
      } packages
    )
  )
