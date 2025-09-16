{
  self,
  pkgs,
  system,
}:
let
  packages = self.repos.${system}.debian.packagesFor {
    dist = "trixie";
    component = "main";
    flavor = "binary-amd64";
  };
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
