{
  pkgs ? import <nixpkgs> { },
}:
rec {
  baseUrl = "https://snapshot.debian.org/archive/debian/20250817T082947Z/";
  release = pkgs.callPackage ./release.nix { inherit baseUrl; };
  lists = pkgs.callPackage ./lists.nix { };
  deb = pkgs.callPackage ./deb.nix {
    inherit (lists) json2list;
    inherit baseUrl;
  };

  createChroot =
    debs:
    pkgs.vmTools.runInLinuxVM (
      pkgs.runCommand "base-chroot.tar"
        {
          nativeBuildInputs = [ pkgs.dpkg ];
        }
        ''
          export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          export DEBIAN_FRONTEND=noninteractive
          mkdir -p chroot/pkgs
          cp ${debs}/* chroot/pkgs/

          for deb in chroot/pkgs/*; do
            dpkg-deb --extract $deb chroot
          done

          chroot chroot bash -c 'dpkg --install --force-depends /pkgs/*'
          # (pointlessly) run again without --force-depends to make sure everybody is happy
          chroot chroot bash -c 'dpkg --install /pkgs/*'
          rm -rf chroot/pkgs

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
  buildChroot =
    required: base: installPackages (createChroot (deb.getDebs required)) (deb.getDebs base);
}
