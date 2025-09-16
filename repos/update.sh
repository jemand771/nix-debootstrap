#!/usr/bin/env bash

dir=$(dirname "$0")
out=$(nix-build --no-out-link "$dir/update.nix")
for repodir in "$out/"*; do
  repo=$(basename "$repodir")
  rm -rf "$dir/$repo"
  mkdir "$dir/$repo"
  cp "$repodir/"*.json "$dir/$repo/"
done
