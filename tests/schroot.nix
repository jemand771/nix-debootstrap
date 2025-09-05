{
  self,
  pkgs,
  system,
}:

pkgs.nixosTest {
  name = "schroot";
  nodes.machine =
    { config, pkgs, ... }:
    {
      imports = [ ../lib/schroot-profile.nix ];
      programs.schroot = {
        enable = true;
        settings.mychroot = {
          type = "file";
          file = builtins.toString (
            self.lib.${system}.buildChroot (
              self.lib.${system}.debootstrapTar "trixie" "main" "binary-amd64" [ ]
            )
          );
          source-clone = false;
          aliases = "foo";
          users = "root";
        };
      };
    };

  testScript = ''
    machine.succeed("schroot -l")
    machine.succeed("schroot -c mychroot -- /bin/bash -c true")
    machine.fail("schroot -c mychroot -- /bin/bash -c false")
  '';
}
