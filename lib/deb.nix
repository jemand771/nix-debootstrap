{
  pkgs,
  baseUrl,
  json2list,
}:
rec {
  getDeb =
    package:
    pkgs.fetchurl {
      url = "${baseUrl}${package.Filename}";
      sha256 = package.SHA256;
    };
  getDebs = packages: pkgs.linkFarmFromDrvs "debs" (pkgs.lib.map getDeb packages);
  resolveDeps =
    packages: deps:
    pkgs.lib.splitString "\n" (
      pkgs.lib.trim (
        builtins.readFile "${pkgs.runCommand "deps"
          {
            ARCH_ALL_SUPPORTED = "0";
            MIRRORS = "deb.debian.org_debian";
            ARCH = "amd64";
            SUITE = "trixie";
            COMPONENTS = "main";
            DLDEST = "apt_dest";
            nativeBuildInputs = [ pkgs.perl ];
          }
          ''
            export TARGET=$(pwd)
            . ${pkgs.debootstrap}/share/debootstrap/functions
            mkdir lists
            cp ${pkgs.writeText "list" (json2list packages)} lists/deb.debian.org_debian_dists_trixie_main_binary-amd64_Packages
            resolve_deps ${pkgs.lib.concatStringsSep " " deps} > $out
          ''
        }"
      )
    );
  priorityDebs = priority: json: builtins.filter (pkg: pkg.Priority == priority) json;
}
