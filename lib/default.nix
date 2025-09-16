{
  pkgs ? import <nixpkgs> { },
}:
rec {
  release = pkgs.callPackage ./release.nix { };
  lists = pkgs.callPackage ./lists.nix { };
  deb = pkgs.callPackage ./deb.nix {
    inherit lists;
  };

  createChroot =
    debs:
    pkgs.vmTools.runInLinuxVM (
      pkgs.runCommand "base-chroot.tar"
        {
          nativeBuildInputs = [ pkgs.dpkg ];
          # TODO that aint right skull emoji
          archfile = pkgs.writeText "arch" ''
            amd64
            aarch64
            armhf
          '';
        }
        ''
          export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          export DEBIAN_FRONTEND=noninteractive
          mkdir -p chroot/pkgs
          cp ${debs}/* chroot/pkgs/

          for deb in chroot/pkgs/*; do
            dpkg-deb --extract $deb chroot
          done
          cp $archfile chroot/var/lib/dpkg/arch

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
          # TODO make configurable/dynamic, somehow. don't build on a tempfs to begin with, maybe?
          # TODO should be apt install -y, not dpkg -i
          memSize = 1024 * 16;
        }
        ''
          export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          mkdir chroot
          tar xf $src -C chroot

          mkdir chroot/pkgs
          cp ${debs}/* chroot/pkgs/
          chroot chroot bash -c 'dpkg --install --force-depends /pkgs/*'
          rm -rf chroot/pkgs

          tar cf $out -C chroot .
        ''
    );
  buildChroot =
    required: base: installPackages (createChroot (deb.getDebs required)) (deb.getDebs base);
}
