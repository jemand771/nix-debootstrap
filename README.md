# nix-debootstrap

Maybe the worst crime I have committed so far.

Generate debian chroots using nix. Currently uses IFD for dependency resolution (handed off to apt) but dependencies _can_ be vendored (by consumers).

This repo provides:

* Builder functions to create a base chroot and install packages in an existing chroot
* Extendable tooling for fetching `Release` and `Packages` files from debian repositories (contains IFD)
* Vendored package lists for select suites and architectures from deb.debian.org and archive.debian.org

Try it:

```sh
nix-build test.nix
mkdir out
tar xf result -C out
sudo chroot result /bin/bash
```

This can be used with schroot's `file` mode where each session creates a copy/overlay of some golden image (which lives in the nix store in this case).

Known issues:

* currently uses `--force-depends` when it doesn't need to (although that may be due to debian crimes in the setup I'm using this for)
* pretty much hardcoded for amd64 (you _could_ also build foreign arch chroots with this, but not right now)
* doesn't auto-update
* GitHub might explode some day if I keep pushing 60MB json files
* Some questionable hardcoded values here and there (e.g. maximum size)
