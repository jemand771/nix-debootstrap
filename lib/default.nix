{
  pkgs ? import <nixpkgs> { },
}:
rec {
  baseUrl = "https://snapshot.debian.org/archive/debian/20250817T082947Z/";
  releaseHashes = {
    trixie = "sha256-SPJcH1gsULfUPTdIHZmcLlM3WW2UifKuMxROFK/kodk=";
  };
  releaseFile =
    dist:
    pkgs.fetchurl {
      url = "${baseUrl}dists/${dist}/Release";
      hash = pkgs.lib.getAttr dist releaseHashes;
    };
  listHashesFromRelease =
    dist:
    pkgs.runCommand "list-hashes-${dist}" { src = releaseFile dist; } ''
      grep -A99999 -m1 'SHA256:' $src | tail -n+2 | while read line; do
        hash=$(echo $line | cut -d" " -f1)
        filename=$out/$(echo $line | cut -d" " -f3)
        mkdir -p $(dirname $filename)
        echo -n $hash > $filename
      done
    '';
  packageList =
    dist: component: flavor:
    let
      listPath = "${component}/${flavor}/Packages.xz";
    in
    builtins.readFile (
      builtins.toString (
        pkgs.runCommand "package-list-${dist}-${listPath}" {
          src = pkgs.fetchurl {
            url = "${baseUrl}dists/${dist}/${listPath}";
            sha256 = builtins.readFile "${listHashesFromRelease dist}/${listPath}";
          };
        } "xz -d < $src > $out"
      )
    );
  list2json =
    list:
    let
      unwrappedLines = builtins.map (
        line: if pkgs.lib.strings.hasPrefix " " line then line else "\n${line}"
      ) (pkgs.lib.splitString "\n" list);
      fullFile = pkgs.lib.removeSuffix "\n" (
        pkgs.lib.removePrefix "\n" (pkgs.lib.concatStringsSep "" unwrappedLines)
      );
    in
    builtins.map (
      block:
      builtins.listToAttrs (
        builtins.map (
          line:
          let
            split = pkgs.lib.splitString ": " line;
          in
          {
            name = builtins.elemAt split 0;
            value = pkgs.lib.concatStringsSep ": " (builtins.tail split);
          }
        ) (pkgs.lib.splitString "\n" block)
      )
    ) (pkgs.lib.splitString "\n\n" fullFile);
  json2list =
    json:
    pkgs.lib.concatStringsSep "\n\n" (
      builtins.map (
        package:
        pkgs.lib.concatStringsSep "\n" (
          # debootstrap assumes `Package:` is the first line (lol)
          # otherwise dependency resolution is off by one package entry with disasterous consequences
          pkgs.lib.sortOn (line: if pkgs.lib.hasPrefix "Package:" line then 0 else 1) (
            pkgs.lib.mapAttrsToList (name: value: "${name}: ${value}") package
          )
        )
      ) json
    );
  debFileName =
    package:
    "${package.Package}_${
      builtins.replaceStrings [ ":" ] [ "%3a" ] (package.Version)
    }_${package.Architecture}.deb";
  getDeb =
    package:
    pkgs.runCommand "${debFileName package}"
      {
        src = pkgs.fetchurl {
          url = "${baseUrl}${package.Filename}";
          sha256 = package.SHA256;
        };
      }
      ''
        mkdir $out
        cp $src $out/package.deb
        echo ${debFileName package} > $out/name.txt
      '';
  getDebs =
    packages:
    # pkgs.linkFarmFromDrvs "debs" (pkgs.lib.map (getDeb dist component flavor) debs);
    pkgs.runCommand "debs" { src = pkgs.linkFarmFromDrvs "debs" (pkgs.lib.map getDeb packages); } ''
      mkdir $out
      for dir in $src/*; do
        echo $dir
        cp -L $dir/package.deb $out/$(cat $dir/name.txt)
      done
    '';
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
  createChroot =
    debs:
    pkgs.vmTools.runInLinuxVM (
      pkgs.runCommand "chroot.tar"
        {
          nativeBuildInputs = [ pkgs.dpkg ];
        }
        ''
          export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          export DEBIAN_FRONTEND=noninteractive
          mkdir chroot

          for deb in ${debs}/*; do
            echo extracting $(basename $deb)
            dpkg-deb --extract $deb chroot
          done

          echo installing base system
          mkdir chroot/pkgs
          cp ${debs}/* chroot/pkgs/
          chroot chroot bash -c 'dpkg --install --force-depends /pkgs/*'
          # (pointlessly) run again without --force-depends to make sure everybody is happy
          chroot chroot bash -c 'dpkg --install /pkgs/*'
          rm -rf chroot/pkgs

          echo exporting chroot
          tar cf $out -C chroot .
        ''
    );
  installPackages =
    chroot: debs:
    pkgs.vmTools.runInLinuxVM (
      pkgs.runCommand "chroot.tar"
        {
          src = chroot;
          memSize = 1024 * 8;
        }
        ''
          export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          mkdir chroot
          tar xf $src -C chroot

          mkdir chroot/pkgs
          cp ${debs}/* chroot/pkgs/
          chroot chroot bash -c 'apt install -y /pkgs/*'
          rm -rf chroot/pkgs

          tar cf $out -C chroot .
        ''
    );
  buildChroot = required: base: installPackages (createChroot (getDebs required)) (getDebs base);
}
