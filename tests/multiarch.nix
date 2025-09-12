{
  self,
  pkgs,
  system,
}:
let
  packages =
    self.lib.${system}.lists.list2json (
      self.lib.${system}.debian.packageList "trixie" "main" "binary-amd64"
    )
    ++ self.lib.${system}.lists.list2json (
      self.lib.${system}.debian.packageList "trixie" "main" "binary-armhf"
    );
in
pkgs.runCommand "test-multiarch"
  {
    src =
      self.lib.${system}.buildChroot
        (self.lib.${system}.deb.resolveDeps packages (
          self.lib.${system}.deb.filter {
            Priority = "required";
            Architecture = "amd64";
          } packages
        ))
        (
          (self.lib.${system}.deb.resolveDeps packages (
            (self.lib.${system}.lists.findAll packages [
              "libgmock-dev:amd64"
              "libgmock-dev:armhf"
            ])
            ++ (self.lib.${system}.deb.filter {
              Priority = "important";
              Architecture = "amd64";
            } packages)
          ))
        );
  }
  ''
    tar tf $src | grep usr/lib/x86_64-linux-gnu/libgmock.a
    tar tf $src | grep usr/lib/arm-linux-gnueabihf/libgmock.a
    touch $out
  ''
