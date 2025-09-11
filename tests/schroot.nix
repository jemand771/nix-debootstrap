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
          type = "directory";
          directory =
            let
              list = self.lib.${system}.debian.packageList "trixie" "main" "binary-amd64";
              packages = self.lib.${system}.lists.list2json list;
            in
            builtins.toString (
              self.lib.${system}.buildChroot
                (self.lib.${system}.deb.resolveDeps packages (
                  self.lib.${system}.deb.priorityDebs "required" packages
                ))
                (
                  self.lib.${system}.deb.resolveDeps packages (
                    self.lib.${system}.deb.priorityDebs "important" packages
                  )
                )
            );
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
