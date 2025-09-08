{
  self,
  pkgs,
  system,
}:
let
  list = self.lib.${system}.packageList "trixie" "main" "binary-amd64";
  packages = self.lib.${system}.list2json list;
in
pkgs.runCommand "deps"
  {
    pass =
      self.lib.${system}.buildChroot
        (builtins.map (name: pkgs.lib.findFirst (p: p.Package == name) null packages) (
          self.lib.${system}.resolveDeps packages (
            builtins.map (p: p.Package) (self.lib.${system}.priorityDebs "required" packages)
          )
        ))
        (
          builtins.map (name: pkgs.lib.findFirst (p: p.Package == name) null packages) (
            self.lib.${system}.resolveDeps packages (
              builtins.map (p: p.Package) (
                [ (pkgs.lib.findFirst (p: p.Package == "cowsay") null packages) ]
                ++ (self.lib.${system}.priorityDebs "important" packages)
              )
            )
          )
        );
    # sanity check to make sure it doesn't magically get included in base one day (unlikely)
    fail =
      self.lib.${system}.buildChroot
        (builtins.map (name: pkgs.lib.findFirst (p: p.Package == name) null packages) (
          self.lib.${system}.resolveDeps packages (
            builtins.map (p: p.Package) (self.lib.${system}.priorityDebs "required" packages)
          )
        ))
        (
          builtins.map (name: pkgs.lib.findFirst (p: p.Package == name) null packages) (
            self.lib.${system}.resolveDeps packages (
              builtins.map (p: p.Package) (self.lib.${system}.priorityDebs "important" packages)
            )
          )
        );
  }
  ''
    echo "making sure the basic install doesn't contain cowsay"
    ! tar tf $fail | grep cowsay
    echo "making sure our custom install contains cowsay"
    tar tf $pass | grep cowsay > /dev/null
    touch $out
  ''
