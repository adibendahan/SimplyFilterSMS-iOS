#!/bin/bash

set -eu

lambda="Report Message Lambda"

target="$lambda/.build/lambda/$lambda"
rm -rf "$target"
mkdir -p "$target"
cp "$lambda/.build/release/$lambda" "$target/"
cd "$target"
ln -s "$lambda" "bootstrap"
zip --symlinks lambda.zip *
