{
  self,
  pkgs,
  system,
}:
pkgs.callPackage ./../test.nix {
  chrootlib = self.lib.${system};
  repos = self.repos.${system};
}
