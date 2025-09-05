{
  self,
  pkgs,
  system,
}:
self.lib.${system}.buildChroot (self.lib.${system}.debootstrapTar "trixie" "main" "binary-amd64" [ ])
