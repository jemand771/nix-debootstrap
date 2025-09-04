# this thing is unused and was just a first test. delete me at some point
{ pkgs ? import <nixpkgs> {} }:
let
deblist = pkgs.fetchurl {
  url = "https://snapshot.debian.org/archive/debian/20250817T082947Z/dists/trixie/main/binary-amd64/Packages.xz";
  hash = "sha256-15cDoCcTv3m5fiZqP1hqWWnSG1BVUZSrm5YszTSKQs4=";
};
locals = pkgs.runCommand "debootstrap-files" { src = ./debootstrap; } ''
  cp -r $src $out
'';
debpkgs = pkgs.runCommand "debpkgs.tar" { src = ./pkgs; } ''
  mkdir -p stuff/{debootstrap,var/lib/apt/lists}
  xz -d < ${deblist} > stuff/var/lib/apt/lists/deb.debian.org_debian_dists_trixie_main_binary-amd64_Packages
  cp -r $src/var/cache stuff/var/cache
  cp -t stuff/debootstrap/ ${locals}/{base,required,debpaths}
  tar cf $out -C stuff .
'';
in
pkgs.vmTools.runInLinuxVM (pkgs.stdenv.mkDerivation {

  name = "chroot";
  version = "0.1";

  memSize = 1024 * 8;

  dontUnpack = true;
  nativeBuildInputs = with pkgs; [
    (debootstrap.overrideAttrs {
      # postPatch = ''
      #   echo 'set -x' | cat - debootstrap > tmp
      #   mv tmp debootstrap
      #   chmod +x debootstrap
      #   sed -i 's/exec >>/# exec >>/' debootstrap
      # '';
    })
  ];
  buildPhase = ''
    debootstrap --unpack-tarball ${debpkgs} --no-check-sig trixie tmp
    rm tmp/dev/{null,zero,full,random,urandom,tty,console,ptmx}
    cp -r tmp $out
    cat <<EOF >> $out/root/.bashrc
    export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    EOF
  '';
  doCheck = true;
  checkPhase = ''
    chroot $out /bin/bash -c "exit 0"
    ! chroot $out /bin/bash -c "exit 1"
    # TODO check that PATH is set properly for interactive shells
  '';
  dontFixup = true;
})
