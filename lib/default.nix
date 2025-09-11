{
  pkgs ? import <nixpkgs> { },
}:
rec {
  release = pkgs.callPackage ./release.nix { };
  debian = pkgs.callPackage ./debian.nix { inherit release; };
  lists = pkgs.callPackage ./lists.nix { };
  deb = pkgs.callPackage ./deb.nix {
    inherit lists;
  };

  createChroot =
    debs:
    pkgs.vmTools.runInLinuxVM (
      pkgs.runCommand "base-chroot"
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
          mkdir -p out/pkgs
          cp ${debs}/* out/pkgs/

          for deb in out/pkgs/*; do
            dpkg-deb --extract $deb out
          done
          cp $archfile out/var/lib/dpkg/arch

          chroot out bash -c 'dpkg --install --force-depends /pkgs/*'
          # (pointlessly) run again without --force-depends to make sure everybody is happy
          chroot out bash -c 'dpkg --install /pkgs/*'
          rm -rf out/pkgs
          cp -r --no-preserve=ownership out $out
        ''
    );
  installPackages =
    chroot: debs:
    pkgs.vmTools.runInLinuxVM (
      pkgs.runCommand "chroot"
        {
          src = chroot;
          # TODO make configurable/dynamic, somehow. don't build on a tempfs to begin with, maybe?
          memSize = 1024 * 16;
        }
        ''
          export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
          cp -r $src out

          mkdir out/pkgs
          cp ${debs}/* out/pkgs/
          chroot out bash -c 'apt install -y /pkgs/*'
          rm -rf out/pkgs
          cp -r --no-preserve=ownership out $out
        ''
    );
  buildChroot =
    required: base: installPackages (createChroot (deb.getDebs required)) (deb.getDebs base);
}
