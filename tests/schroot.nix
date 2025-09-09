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
              list = self.lib.${system}.release.packageList "trixie" "main" "binary-amd64";
              packages = self.lib.${system}.lists.list2json list;
            in
            builtins.toString (
              self.lib.${system}.buildChroot
                (builtins.map (name: pkgs.lib.findFirst (p: p.Package == name) null packages) (
                  self.lib.${system}.deb.resolveDeps packages (
                    builtins.map (p: p.Package) (self.lib.${system}.deb.priorityDebs "required" packages)
                  )
                ))
                (
                  builtins.map (name: pkgs.lib.findFirst (p: p.Package == name) null packages) (
                    self.lib.${system}.deb.resolveDeps packages (
                      builtins.map (p: p.Package) (self.lib.${system}.deb.priorityDebs "important" packages)
                    )
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
