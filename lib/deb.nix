{
  pkgs,
  json2list,
}:
rec {
  getDeb =
    package:
    pkgs.fetchurl {
      url = "${package._baseUrl}${package.Filename}";
      sha256 = package.SHA256;
    };
  getDebs = packages: pkgs.linkFarmFromDrvs "debs" (pkgs.lib.map getDeb packages);
  resolveDeps =
    packages: deps:
    let
      sources = pkgs.writeText "fake.sources" ''
        Types: deb
        URIs: http://a.b/c
        Suites: d
        Components: e
      '';
      list = pkgs.writeText "list" (json2list packages);
      resolved =
        pkgs.runCommand "deps-resolved"
          {
            nativeBuildInputs = with pkgs; [
              apt
              dpkg
            ];
          }
          ''
            mkdir -p var/lib/apt/lists var/cache/apt etc/apt/{sources.list,preferences}.d/
            cp ${sources} etc/apt/sources.list.d/fake.sources
            cp ${list} var/lib/apt/lists/a.b_c_dists_d_e_binary-amd64_Packages
            apt-get install -s --no-install-recommends \
              -o Apt::System="Debian dpkg interface" \
              -o Dir::Cache="$PWD/var/cache/apt" \
              -o Dir::State="$PWD/var/lib/apt" \
              -o Dir::Etc="$PWD/etc/apt" \
              ${pkgs.lib.concatStringsSep " " deps} \
            | grep '^Inst' | cut -d" " -f2 > $out
          '';
    in
    pkgs.lib.splitString "\n" (pkgs.lib.trim (builtins.readFile resolved));
  priorityDebs = priority: json: builtins.filter (pkg: pkg.Priority == priority) json;
}
