# nix-debootstrap

Maybe the worst crime I have committed so far.

Generate debian chroots using nix. Currently uses IFD for convenience reasons (Release -> Packages -> .deb file hashes) but should be doable without.
Abuses snapshot.debian.org to grab a stable release file, (allegedly) stable package lists and (allegedly) stable .deb archives. How nice of them to include hashes for each file.

~~Dependency resolution doesn't work~~, binary-amd64 is just straight up hardcoded, and the interface is questionable at best.
BUT you _can_ get a very basic trixie chroot out of this by running

```sh
nix-build test.nix
sudo chroot result /bin/bash
```

so that's something I guess.
(Good luck doing anything with a readonly chroot)

This is intended to be used with schroot's "readonly" mode where each session creates a copy/overlay of some golden image (which lives in the nix store in this case) some day.
If your chroot is too big and unpacking on each `schroot` invocation takes too long, you _can_ also just use this directly from the nix store, if you dare.
