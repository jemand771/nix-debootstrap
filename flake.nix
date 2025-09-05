{
  description = "Generate debian chroots using nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        formatter = pkgs.nixfmt-tree;
        checks = pkgs.lib.mapAttrs' (name: _: {
          name = pkgs.lib.removeSuffix ".nix" name;
          value = pkgs.callPackage "${self}/tests/${name}" { inherit self; };
        }) (builtins.readDir ./tests);
      }
    );
}
