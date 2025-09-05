{
  self,
  pkgs,
  system,
}:
self.lib.${system}.buildChroot (self.lib.${system}.chrootTar "trixie" "main" "binary-amd64" [ ])
