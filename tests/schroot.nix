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
          file =
            let
              packages = self.repos.${system}.debian.packagesFor {
                dist = "trixie";
                component = "main";
                flavor = "binary-amd64";
              };
            in
            builtins.toString (
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
