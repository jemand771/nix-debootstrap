{
  self,
  pkgs,
  system,
}:
pkgs.runCommand "deps"
  {
    pass = self.lib.${system}.buildChroot (
      self.lib.${system}.debootstrapTar "trixie" "main" "binary-amd64" [ "cowsay" ]
    );
    # sanity check to make sure it doesn't magically get included in base one day (unlikely)
    fail = self.lib.${system}.buildChroot (
      self.lib.${system}.debootstrapTar "trixie" "main" "binary-amd64" [ ]
    );
  }
  ''
    ! tar tf $fail | grep cowsay
    tar tf $pass | grep cowsay
    touch $out
  ''
