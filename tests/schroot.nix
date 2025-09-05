{ self, pkgs }:

pkgs.nixosTest {
  name = "schroot";
  nodes.machine =
    { config, pkgs, ... }:
    {

    };

  testScript = ''
    machine.start()
  '';
}
