#!/usr/bin/env bash

dir=$(dirname "$0")
out=$(nix-build --no-out-link "$dir/update.nix")
cp "$out/"*.json "$dir/"
