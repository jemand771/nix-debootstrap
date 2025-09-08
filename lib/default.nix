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
    pkgs.runCommand "package-list-${dist}-${listPath}" {
      src = pkgs.fetchurl {
        url = "${baseUrl}dists/${dist}/${listPath}";
        sha256 = builtins.readFile "${listHashesFromRelease dist}/${listPath}";
      };
    } "xz -d < $src > $out";

  debHashes =
    dist: component: flavor:
    pkgs.runCommand "deb-hashes-${dist}-${component}-${flavor}"
      {
        src = packageList dist component flavor;
        nativeBuildInputs = [ pkgs.python3 ];
      }
      ''
        python3 ${./debhashes.py} $src $out
      '';
  debFileName =
    dist: component: flavor: name:
    # pkgs.lib.last (
    #   pkgs.lib.splitString "/" (builtins.readFile "${debHashes dist component flavor}/${name}/Filename")
    # );
    "${name}_${
      builtins.replaceStrings [ ":" ] [ "%3a" ] (
        builtins.readFile "${debHashes dist component flavor}/${name}/Version"
      )
    }_${builtins.readFile "${debHashes dist component flavor}/${name}/Architecture"}.deb";
  getDeb =
    dist: component: flavor: name:
    let
      hashes = debHashes dist component flavor;
    in
    pkgs.runCommand "${dist}-${component}-${flavor}-${name}"
      {
        src = pkgs.fetchurl {
          url = "${baseUrl}${builtins.readFile "${hashes}/${name}/Filename"}";
          sha256 = builtins.readFile "${hashes}/${name}/SHA256";
        };
      }
      ''
        mkdir $out
        cp $src $out/package.deb
        echo ${debFileName dist component flavor name} > $out/name.txt
      '';
  getDebs =
    dist: component: flavor: debs:
    # pkgs.linkFarmFromDrvs "debs" (pkgs.lib.map (getDeb dist component flavor) debs);
    pkgs.runCommand "debs"
      { src = pkgs.linkFarmFromDrvs "debs" (pkgs.lib.map (getDeb dist component flavor) debs); }
      ''
        mkdir $out
        for dir in $src/*; do
          echo $dir
          cp -L $dir/package.deb $out/$(cat $dir/name.txt)
        done
      '';
  baseFile = debs: pkgs.writeText "base" (pkgs.lib.concatStringsSep " " debs);
  requiredFile = debs: pkgs.writeText "required" (pkgs.lib.concatStringsSep "\n" debs);
  debpathsFile =
    dist: component: flavor: debs:
    pkgs.writeText "debpaths" (
      pkgs.lib.concatStringsSep "\n" (
        (pkgs.lib.map (deb: "${deb} /var/cache/apt/archives/${debFileName dist component flavor deb}") debs)
        ++ [ "" ]
      )
    );
  resolveDeps =
    list: deps:
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
            cp ${list} lists/deb.debian.org_debian_dists_trixie_main_binary-amd64_Packages
            resolve_deps ${pkgs.lib.concatStringsSep " " deps} > $out
          ''
        }"
      )
    );
  priorityDebs =
    priority: info:
    pkgs.lib.splitString "\n" (
      pkgs.lib.trim (
        builtins.readFile "${pkgs.runCommand "${priority}-packages"
          {
            src = info;
            nativeBuildInputs = [ pkgs.python3 ];
          }
          ''
            python3 ${./priority-filter.py} ${priority} $src $out
          ''
        }"
      )
    );
  debootstrapTar =
    dist: component: flavor: debs:
    let
      hashes = debHashes dist component flavor;
      list = packageList dist component flavor;
      requiredDebs = resolveDeps list (debs ++ priorityDebs "required" hashes);
      baseDebs = pkgs.lib.subtractLists requiredDebs (
        resolveDeps list (debs ++ priorityDebs "important" hashes)
      );
      allDebs = baseDebs ++ requiredDebs;
    in
    pkgs.runCommand "debootstrap.tar" { src = getDebs dist component flavor allDebs; } ''
      mkdir -p out/{debootstrap,var/{lib/apt/lists,cache/apt}}
      cp -r $src out/var/cache/apt/archives
      cp ${
        packageList dist component flavor
      } out/var/lib/apt/lists/deb.debian.org_debian_dists_${dist}_${component}_${flavor}_Packages
      cp ${baseFile baseDebs} out/debootstrap/base
      cp ${requiredFile requiredDebs} out/debootstrap/required
      cp ${debpathsFile dist component flavor allDebs} out/debootstrap/debpaths
      tar cf $out -C out var debootstrap
    '';
  debootstrap = pkgs.debootstrap;
  debootstrapVerbose = debootstrap.overrideAttrs {
    postPatch = ''
      echo 'set -x' | cat - debootstrap > tmp
      mv tmp debootstrap
      chmod +x debootstrap
      sed -i 's/exec >>/# exec >>/' debootstrap
    '';
  };
  buildChroot =
    debpkgs:
    pkgs.vmTools.runInLinuxVM (
      pkgs.runCommand "chroot.tar"
        {
          # nativeBuildInputs = [ debootstrapVerbose ];
          nativeBuildInputs = [ debootstrap ];
          memSize = 1024 * 8;
        }
        ''
          debootstrap --unpack-tarball ${debpkgs} --no-check-sig trixie tmp
          rm tmp/dev/{null,zero,full,random,urandom,tty,console,ptmx}
          cat <<EOF >> tmp/root/.bashrc
          export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
          EOF
          tar cf $out -C tmp .
        ''
    );
}
