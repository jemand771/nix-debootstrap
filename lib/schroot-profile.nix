{ pkgs, ... }:
{
  programs.schroot = {
    enable = true;
    profiles.default = {
      nssdatabases = [
        "passwd"
        "shadow"
        "group"
        "services"
        "protocols"
        "hosts"
      ];
      fstab = pkgs.writeText "fstab" ''
        /nix            /nix            none    ro,bind         0       0
        /proc           /proc           none    rw,bind         0       0
        /sys            /sys            none    rw,bind         0       0
        /dev            /dev            none    rw,bind         0       0
        /dev/pts        /dev/pts        none    rw,bind         0       0
        /home           /home           none    rw,bind         0       0
        /tmp            /tmp            none    rw,bind         0       0
      '';
      copyfiles = [
        "/etc/resolv.conf"
      ];
    };
  };
}
